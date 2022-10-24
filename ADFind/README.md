Summary

    Command line Active Directory query tool. Mixture of ldapsearch, search.vbs, ldp, dsquery, and dsget tools with a ton of other cool features thrown in for good measure. This tool proceeded dsquery/dsget/etc by years though I did adopt some of the useful stuff from those tools.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Warranty

    http://www.joeware.net/freetools/warranty.htm
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Platforms

    Windows 7 / 2008 R2 or newer against any version of Active Directory, ADAM/ADLDS, and other LDAP directories
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Current Version

    Version 1.57.00 - November 19, 2021
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Modification(s) from previous version

    BUGFIXES:
        Fixed issue with RegEx !m
         Fixed issue with RegEx for SID/GUID attributes
        Fixed Crash Bug with Security Descriptors
        Fixed DN breakout for Extended Names output
        Fixed ranging issue with Extended Names output
        Fixed issue with non-paged searches
        Fixed some error outputs
    Switches:
        Added -csvsh (CSV Smart Header for piping)
        Added ! as alias for !m
        Added -gplinkmulti
        Added -ntlm
        Added -starttls
        Added -dncharvalidation
        Added -dirsync
        Added -dirsyncro
        Added -dirsync_opts
        Added -dirsync_cont
        Added -showcookie
    Shortcuts:
        Added nothing new
    Misc
        Convert to Visual Studio 2022
        Added addtional decodes for 389DS LDAP Directory
        Updated dSHeuristics decodes
        Allow -csvnoheader to work with -sdcsvsingle
        Updated some systemFlag decodes
        Allow SID/GUIDs for DN pipe input
        Added regex functionality for -excldn / -incldn
        Added -sdbinout alias for -sdblob
        Remove [BLOB] from CSV output for -sdblob
        Detect Windows Server 2022

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Security Requirements

    There are no local security requirements for running AdFind other than the ability to launch executables. Information returned from Active Directory and ADAM/ADLDS will be dependent on the security configured for the directory. Generally a normal Active Directory user can return a considerable amount of information from Active Directory while ADAM/ADLDS tends to be more locked down.

    The -showdel option will require permissions to see into the cn=Deleted Objects container. By default, this requires administrator permissions. It can be modified but it is non-trivial for most admins.

    The STATS control options (stats, stats+, statsonly, stats+only, etc.) require the user to have DEBUG_PRIVILEGE on the server being queried. This generally means admin access is required to use that functionality.

    The -sdna (Security Descriptor Non-Admin) or -nosacl options can be used to tell LDAP to not return the SACL portion of the ACL. This will allow users without auditing rights to retrieve most of the Security Descriptor of an object. Specifically, the Owner, Group Owner, and DACL information will be returned. If you attempt to use -sddl,-sddc,-owner* options and you don't get the information returned, add the -sdna option to see if that helps.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Language

    C++. Compiled with Visual Studio 2022

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Source Code Availability

    None
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Story

    AdFind was put together when I finally got sick of the limitations in ldapsearch and search.vbs and didn't want to continue writing quick vbscript solutions every time I needed some generic info. Plus, anyone will tell you vbscript doesn't handle several of the attributes in Active Directory very well. Eventually after I had this tool out there for some time, Microsoft introduced dsquery and dsget. While they are nice tools, AdFind continues to be more flexible and I rarely, if ever, use the ds* tools. I did, however, like the ability to pipe the quoted DN results from the query into other command line tools so I emulated that functionality from the ds* series with AdFind with the -dsq option. One day I realized that I could take the piping one step further and worked out the -adcsv option which when combined with AdMod is extremely powerful for performing updates on AD. 

    V01.31.00 added a bunch of new changes, some of these changes include shortcut options. You can view information on the shortcut options with the new help screen available through /sc?. The story behind these shortcut options is that there were queries I was doing on a regular basis that I hated typing up the whole command for, for example, one of my most common queries is to check a schema object for its definitions which would normally take the command adfind -schema -f "|(name=objectname)(ldapdisplayname=objectname)" and now it is as simple as adfind -sc s:objectname. Another common one for me is listing all of the schema objects with a specific prefix which normally would look like adfind -schema -f "|(name=prefix*)(ldapdisplayname=prefix*)" -sort -list ldapdisplayname and now it is adfind -sc sl:prefix*. Anyway there are a ton of shortcuts, have fun.

    V01.40.00 finally added an often requested feature - the ability to pipe the output from one AdFind command as the input for the BASE DN for another AdFind command, this allows things like requesting constructed attributes that require a base scope query for all users in an OU or the entire directory with a single command line or counting the number of users in every OU in the directory.

    V01.47.00 added a beta switch -nopaging which turns off the default LDAP Paging option. This should make it so AdFind can be used against LDAP directories that do not support the paging control. In V01.48.00 this switch auto-enables itself when it detects a directory that doesn't indicate paging is a supported capability in the RootDSE.

    V01.52.00 added some beta Regular Expression (regex) functionality. See -regex? usage for more information.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Add-Ons

    ADCSV.PL - Perl script to convert a full ADFIND output dump to CSV style format. Included in ZIP file for AdFind. No I will not rewrite this in vbscript. I dislike vbscript. I have received a couple of vbscript scripts to do this, I will not include them as I will only include stuff that I have written so I am only answering questions on stuff I wrote. If you only need to export specific attributes, specify those attributes and use the -csv option to get CSV output natively.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Download
	http://www.joeware.net/freetools/tools/adfind/index.htm
  	
Sponsored Link: 	
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Version History

    Update: Version 1.02.00 - Decode more GUID attributes, maintains attribute name case versus converting to lowercase, convert non-print chars to ?.
    Update: Version 1.03.00 - Changed how I identified what was a single value SID or GUID field for decoding. Seems MS decided to make a couple of GUID fields that were actually UNICODE strings octet strings. I got bit by it when working on a little project to do programmatic AD ACL enumerations from a perl script.
    Update: Version 1.04.00 - Added option to allow changing timeout value, also increased page timeout default to 120 seconds from 60 seconds. Added bitwise filter conversion option which will convert simple strings to bitwise OID values. Changes some of the error handling because some error messages weren't seeing the light of day such as bad filter or timeout errors.
    Update: Version 1.05.00 - Added anonymous connection capability. Also added Simple authentication capability
    Update: Version 1.06.00 - Changed -dn and -c options to not return values unless specifically asked for.
    Update: Version 1.07.00 - Added more SID/GUID attributes for decoding. Most specifically for Exchange 2000.
    Update: Version 1.08.00 - Added more SID/GUID attributes for decoding. Most specifically for Dot NET Domains.
    Update: Version 1.09.00 - Attempting to read schema to determine binary/GUID/SID attributes. Display Binary Info as HEX. Also fixed some bad memory management I was doing during count and DN only operations. You should notice that less memory being used for these operations.
    Update: Version 1.10.00 - Added No referrals option (-nr). Added Page size option (-ps)
    Update: Version 1.11.00 - 02/23/2003 - Added port option (-p)
    Update: Version 1.12.00 - 05/24/2003 - Fixed a bug in the -BIT option with OR. Also added -default, -root, -schema, -config that can be used instead of having to specify the full DN for those partitions with -b.
    Update: Version 1.13.00 - 12/01/2003 - Never publicly released, fixed a small bug.
    Update: Version 1.14.00 - 04/10/2004 - Added decode sid option (-sddc), added dsquery style output for Deano (-dsq), added elapsed time counter (-elapsed), added sort (-sort) and reverse sort (-rsort), added show deleted objects (-showdel) which inserts the deleted objects display OID into the server control, added new parameter validation system I worked up for oldcmp.
    Update: Version 1.14.01 - 04/11/2004 - Added a line outputting the full SDDL string for security descriptors because ~Eric asked for it. :o)
    Update: Version 1.15.00 - 04/24/2004 - Fixed an issue with the elapsed time option, it was really screwed up. ;o)
    Update: Version 1.16.00 - 05/20/2004 - Change for internal attrib identification for display. Took into account defunct attribs.
    Update: Version 1.17.00 - 05/29/2004 - Added several new options: /stats, /stats+, /statsonly, /stats+only - all of these are for displaying LDAP STATS info on Windows 2003 AD. They will help you determine how efficient a given query is. Some additional options: /extname which will give you the GUID and SID bind DNs as well as the regular DN, /exterr which will display some additional error info - specifically dsid codes which PSS likes to see. I also added some additional functionality that works all the time and that is closest match display if you specify a bad base DN and also it will display any referrals generated.
    Update: Version 1.18.00 - 07/05/2004 - Fixed a leak in the ldap result section added last version. Fixed a bug in the Stats section on how it displayed the bitewise AND|OR. Fixed the display of deleted objects. You will note that you usually have a new line in the middle of the name and cn fields with K3 and also the DN and distinguishedName fields in 2K. MS fixed the DN for K3 but missed the others, I catch them all.
    Update: Version 1.19.00 - 08/09/2004 - Fixed a bug with decoding of lastLogonTimestamp. Fixed a bug where you couldn't use -root. Added relative base option (-rb). Added -binenc option, this allows you to specify guids and sids in nice human format in a query and it will convert it (ex: objectsid={{sid:S-1-5-21-3593593216-2729731540-1825052264-1105}}). Add excl option to exclude display of certain attribs. I also added some code to catch what appears to be a bug in AD. Occasionally STATS control will return a DWORD value where it should return an OctetString. This was throwing exceptions in AdFind. Now it will capture it and set the bad values to be "".
    Update: Version 1.20.00 - 08/10/2004 - Found out more about STATS bug, added additional usage info and throw up a message when it occurs. MS requires DEBUG_PRIVILEGE on the DC in order to returns STATS info.
    Update: Version 1.21.00 - 09/05/2004 - Fixed division by zero error, fixed some usage text.
    Update: Version 1.22.00 - 09/18/2004 - Added -selapsed, fixed bug in -sddl, added ldap directory determination capability
    Update: Version 1.23.00 - 09/22/2004 - Added lockoutTime to list of time values to be decoded
    Update: Version 1.24.00 - 09/30/2004 - Recompiled to remove Debug info
    Update: Version 1.25.00 - 12/10/2004 - Added several options - maxe,sddl,kerbenc,ff,samdc,excldn,excldndelim. Port can be specified in -h option. -sddc functionality changed to not append nTSecurityDescriptor attribute if attribs are specified. Dot (.) specified for -h gets translated to localhost.
    Update: Version 1.25.01 - 12/10/2004 - Missed cleaning up some debug statements from 1.25.00.
    Update: Version 1.26.00 - 02/12/2005 - Fixed stats bug. Fix stats base search message bug. Fixed bug in "-h .". Fix bug in ranging for K3. Added -nodn,-nolabel,-noctl,-owner,-owneronly,-ownercsv,-sdna.
    Update: Version 1.27.00 - 11/05/2005 - Fixed bug in stats filter expansion. Decode msDS-User-Account-Control-Computed with -samdc. Add TZ string for -tdc(s). Added port info on host connection output info. Broke help up. Added -pr, -list, -soao, -oao,-csv, -csvdelim, -csvmvdelim, -csvq, -nocsvheader, -incldn, -incldndelim, -e, -ef, -tdcs, -utc, -po.
    Update: Version 1.28.00 - 12/21/2005 - Fixed bug in stats, fixed bug in usage display, fixed bug in counting for -incldn.
    Update: Version 1.29.00 - 12/22/2005 - -up * will now query user for password so you don't have to specify on command line
    Update: Version 1.30.00 - 01/29/2006 - Bug fix for multivalue sid/guid attribs. Fixed /??? usage bug. Added -ssl, -null, -flagdc, -sl, -adcsv. Added logic to prevent logonWorkstations from being displayed in HEX.
    Update: Version 1.30.01 - 01/31/2006 - Fixed small bug with usage.
    Update: Version 1.31.00 - 03/22/2006 - Added /???? shortcut help menu describing a ton of shortcuts which will not be listed here. Fixed Decode issue with msDS-User-Account-Control-Computed. Decode some more flags/values. Decode more attributes - msDS-Behavior-Version, msDS-Cached-Membership, msDS-Cached-Membership-Time-Stamp, msDS-Site-Affinity, retiredReplDSASignatures, msDS-RetiredReplNCSignatures. Properly handle requested binary format ;binary. Added support for \t for delimiter switches so you can specify tab delimited. Added options for -binenc to encode int8 time format using {{utc:}} and {{local:}}. Officially added (unhid) shortcut options (-sc xxx:yyy), see /????. Added -schdc, -rootdse, -rootdsefull, -alldc (all decode), -replacedn, -replacedndelim, -sitenamedc, -resolvesids, -sddc+/-sddl+, -rawsddl, -mvfilterdelim, -mvfilter, -mvnotfilter, -sidbinout, -guidbinout, -asq, -decutc, -declocal, -encutc, -enclocal
    Update: Version 1.32.00 - 10/01/2006 - Fixed several bugs, added subnets and exch to DN Replace option, Added support to decode longhorn mode values, Expanded partitions msDS-Behavior-Version decoded on, Decode defaultSecurityDescriptor, Changed usage switches around - see adfind /?, Added switches -sddl++, -sddlfilter, -sddlnotfilter, -recmute, -noowner, -nogroup, -nodacl, -nosacl, -decsddlacl, -tdca, -tdcas, -tdcgt, -tdcgts, Allow ACEs in SDDL+/SDDL++ output to be filtered with -mvfilter, Fixed -maxe so it works for values >1000, Increased buffer size of -ef and -ff options to 10MB, Special Exchange specific decode of msExchMailboxSecurityDescriptor with sddl+, Added shortcuts listpropsets, listpropsetsl, listpropsetscsv, listvwrites, listvwritesl, listvwritescsv, listxrights,listxrightsl,listxrightscsv,exchmbxs, exchme, sdfilter, sdfilterns, explaces
    Update: Version 1.33.00 - 10/30/2006 - Updates usage, fixed -sc u bug, mod to -decsddlacl, more timers for -selapsed, Added INCHAIN/NEST for -bit, added -exterr option for more error points.
    Update: Version 1.34.00 - 11/13/2006 - Fixed bug in filtered SDDL output, added -qlist, -onlysacl, -onlydacl
    Update: Version 1.35.00 - 01/06/2007 - Fixed bug in -onlydacl, added shortcut DomainNCs, fixed bug in -sddl flag output, changed decode output for ACL Flag for -sddl+, added -onlydaclflag -onlysaclflag -onlyaclflags
    Update: Version 1.36.00 - 02/24/2007 - Added switches: -nrss, -resolvesidsldap, -csvnoq, -gcb, -mvfiltercs, -scexchnosys, -sdsize, -sdsizenl, -metasort. Added the following shortcuts: exchsmtpaddr, exchprimarysmtp, objmeta, objsmeta, legacylvr, legacylvrs, legacygroupmembers, replqueue, ncrepl. Updated switches:-rootdse, -fullrootdse. Updated shortcut: exchme. Decode attributes: supportedExtension, pwdProperties. Decode ;binary form of attributes: msDS-ReplAttributeMetaData, msDS-ReplValueMetaData, msDS-NCReplCursors, msDS-ReplConnectionFailures, msDS-ReplLinkFailures, msDS-NCReplInboundNeighbors, msDS-NCReplOutboundNeighbors, msDS-ReplAllInboundNeighbors, msDS-ReplAllOutboundNeighbors, msDS-ReplPendingOps, msDS-TopQuotaUsage
    Update: Version 1.37.00 - 06/24/2007 - Added new special base switches: forestdns, domaindns, gpo, psocontainer, ldappolicy, xrights, partitions, sites, subnets, exch, dcs, fsps. Added new switches: noautoranging, onlyaclprot, onlyaclunprot Added the following shortcuts: rodcpas, rodcpasl, !rodcpas, !rodcpasl, export, sddldmp, sddlmap, sitedmp, subnetdmp, gpodmp, fspdmp, oudmp, showmeta, showmetas. Updated switches:-replacedn. Decode more time/interval valuesDecode attributes: options, mS-DS-ReplicatesNCReasonUpdated some of the decode functions for Longhorn (aka Windows Server 2008) values Updates STATS to work properly with Longhorn Fixed multiple usage typosFixed bug with -mvfilterStreamlined some of the shortcutsSped up SID resolution (especially in cases where LDAP connection but no RPC connection)Changed "Coordinated Universal Time" in time decode to UTC.
    Update:Version 1.38.00 - Never publicly released
    Update: Version 1.39.00 - 01/10/2009 - Now compiled with Code Gear C++ Builder 2009, smaller and faster executable. Changed Windows Longhorn references to Windows Server 2008. Updated decoded attributes to account for Windows Server 2008 values. Added additional decoded attributes. Multiple bug fixes. Multiple shortcut fixes. Multiple usage screen typo fixes. -csv now also sets -noctl automatically. -sc sdump sorts multivalue attributes included in return set. Arbitrary text column mode for -csv (see -csv?). -rawsddl no longer requires -sddl. Auto-Ranging disabled for any attributes where the range modifier was specified. Assume -default if no base specified. -mvfilter string matching is made without any modifiers in the returned attribute. I.E. Match on someattrib not someattrib;binary. Added more attributes to be returned for -fullrootdseAdded. New switches: rootdseanon, nirs, nirsx, writeable, sslignorecert, mvsort, mvrsort, filterbreakdown, enccurrent, tdcd, inputdn. New shortcuts: admincountdmp, xrdump, dcdmp, adobjcnt, alldc+, users_disabled, users_nonexpiring, users_pwdnotreqd, users_accexpired, computers_disabled, computers_pwdnotreqd, computers_active, computers_inactive, schver, spn, email, site, subnet, syscrit, rodc_cachable, policies
    Update: Version 1.40.00 - 02/13/2009 - AdFind now accepts multiple DNs for BASE paramter through STDIN piping.Enable -alldc+ switch that was added in V01.39.00Fixed Misc usage typosAdded Windows Server 2008 R2 decode constantsAdded "default" -e and -ef type functionality (i.e. default environment variables or default config file that are always processed)Added new switches: -csvqesq, -extsrvinfo, -srvctls, -showdelobjlinks, -showrecycled, -showdel+, -tdcdshort, -ic, -db, -ictsv, -stdinsort, -subsetAdded new shortcuts: -sc trustdmp, -sc ou:xx
    Update: Version 1.41.00 - 02/13/2010 - Multiple bug fixes, switches, logic, shortcuts, and docs. Added decodes for linkID, msDS-OptionalFeatureFlags, msDS-RequiredForestBehaviorVersion, msDS-RequiredDomainBehaviorVersion, and some K8R2 Decodes for existing decoded attributes. Additional work on the Environment (-e and -ef) functionality. Added new switches: -arecex, -digest, -this, -jtsv, -users, -displayspecifiers, -nocsvq, -csvnoheader, -hh, -hd, -tdcfmt, -tdcsfmt. Added new shortcuts: -sc replstat, -sc getacl, -sc getacls Added ;class and ;attr modifiers to shortcuts -sc s and -sc sl.
    Update: Version 1.42.00 - 04/24/2010 - Fixed port bug in -rootdseanon, Fixed -adcsv header bug, Fixed bug in schema OID retrieval, Added -decint, -metafilter,-metafilterattr,-metafilterval, -statsonlynodata,-stats+onlynodata,-ameta,-vmeta switches, Added more fields for stats output for 2008+, Changed the decode of -9223372036854775808,Added -sc dompol shortcut
    Update: Version 1.43.00 - 02/13/2011 - Decode more attributes. Fixed multiple usage typos. Modified how several shortcuts functioned to allow CSV, also fixed a few bugs, probably added a few more. ;) Fixed several bugs around handling improperly formatted input. Attempted to fix cut/paste bug from Outlook/Word for doublequote and dash. Enabled -stats with -c. Fixed bug in time output for 00/00/00. Fixed hang bug with processing VERY LARGE groups for CSV. Fixed UTC error in -declocal. Added %int8% for -tdc(s)fmt. Added ENCPWD: format for -up switch. Added -objfilefolder, -encpwd switches. Added shortcuts adam_info, adam_fo, adam_u, adam_g, adam_ou, adam_email, adam_spn, dclist, export_*. Added _attr and attr- functionality for most shortcuts
    Update: Version 1.44.00 - 03/03/2011 - Fixed paging bug for non-MSFT LDAP directories. Decode some OpenLDAP RootDSE OIDs.Add -nopagingcheck switch. Fixed output bug in value metadata. Removed nTSecurityDescriptor from -sc export_* shortcuts. Added shortcut -sc domainlist. Disallow combination of special base and -b switch. Changed switches behind shortcut -sc dclist to be more flexible. Added ability to -sc gclist, -sc !gclist.
    Update: Version 1.45.00 - 03/15/2011 - Fixed bug in -tdcdshort
    Update: Version 1.46.00 - 02/xx/2012 - Fixed bug in decoding binary attributes. Fixed bug in -tdcsfmt. Fixed base bug in -sc objsmeta. Fixed multiple bugs around CSV quoting. Fixed typoes in usage. Fixed bugs in dsheuristics decode, Added dynamic determination of int8 time and interval attributes. Better error message when folder doesn't exist for -objfilefolder. Error out if multiple special based used. Fixed -sc dcdmp:csv, added objectsid as well. Changed -sc adobjcnt such that -gc is no longer specified. Modified -sc policies. Added decodes for Win8. Decode msDFSR-Flags. Allow you to specify filter for -ameta and -vmta. Added following switches -int8time, -int8time-, -dpdn, -pdn, -pdnu, -pdnq, -pdnuq, -statsnofilter, -csvxl, -exportfile,-cv. Added shortcut -sc adinfo.
    Update: Version 1.47.00 - 10/31/2012 - Fixed bugs with -this,-ameta,-vmeta. Changed Win8 decodes strings to Windows 2012. Added switch -nopaging. Added shortcut -sc ridpool.
    Update: Version 1.48.00 - 1/17/2015 - Fixed a bunch of bugs. Added a bunch of decodes.Tweaked various shortcuts to increase speed, etc. Allow duplicate attributes to be specified for CSV output (broken a few versions back). Added IPv6 addressing format support for -h/-hh switches. Auto-enable -nopaging when necessary. Added ability to use SID/GUID/IID for BaseDN. Added additional constants for -replacedn. Added :dnwdata:= matching rule. Added BASE64 for -binenc. Added Hex/Base64 modifiers for -sidbinout and -guidbinout. New special bases: -sitelinks, -legacydns, -quotas. Added shortcuts -sc sitelinkdmp, -sc sitelinkdmpl. Added switches -exclrepl, -ametal, -vmetal, -fdnx, -encguidtoiid, -deciidtoguid, -objcnterrlevel, -stripdn
    Update: Version 1.49.00 - 02/28/2015 - Fixed bug in -dloid
    Update: Version 1.50.00 - 05/04/2017 - Ported to Visual Studio 2017. Change CHAR based functions to safeR (_s) versions. SID Resolution speed greatly increased Security Descriptors. Schema OID query increased to 1K page size (faster startup). BUGFIXES: Fixed auto-nopaging, -sddl+ fixed ***INVALID*** incorrectly displayed in decoded ACL, dsHeuristics decode bug, Fixed CanonicalName containing \0A causing newline, Removed -sc gclist (didn't work). Threshold Decodes changed to Windows Server 2016. Additional dsHeuristics decodes. Decode msDS-ReplAuthenticationModeDecode msds-revealedusers. Changed ADAM to ADLDS. Added switches -appver, -dplsids, sslinfo, -tdcda, -tdctzstr, -csvconnerr. Added aliases for -sc schemadmp=sdump, -sc xrdmp=xrdump. Added "short" option to -sc dclist.Added utcgt/localgt for -binenc.Added special bases -prb, -ds, -svcs, -delobjs, -delobjs+, -roles. The -rb switch works with piped in dns now.
    Update: Version 1.51.00 - 10/31/2017 - Fixed number of small bug fixes / memory leak fixes related to Borland Builder C++ to VS 2017 conversion, Preloaded Security Descriptor OIDs, For PSISE if stderr redirect send header to stdin, Added Bulk SID resolution to SID atts, Added garbageCollPeriod to policies, Decode msDS-TrustForestTrustInfo (-samdc), Added more attributes to -fullrootdse, Updated time/sid attributes hardcode, Brought back the mainicon, Added fgppcontainer alias for psocontainer, Decode wellknownobjects/otherwko, Decoded dSASignature, msExchRemoteRecipientType, msExchRecipientDisplayType, msExchRecipientTypeDetails, Fixed jtsv/2 to use -csv xx value, Added -ametanl, -vmetanlAdded -jsd, -jsdnl, -jsde, -jsdenl, -url, -sddl+++/-sddc+++,-sddl3 alias for sddl+++, -metamvcsv, -metamvcsva, -metamvcsvv, -binsize xx, -binsizenl xx, -adminrootdse, Changed dcdmp filter to dclist filter, Added dn to -sc dclist:xx, Added shortcuts cexplaces,caclnoinherit, structdmp/dump, fgpps/psos
    Update: Version 1.52.00 - 01/11/2020 - Ported to Visual Studio 2019 and a whole lot more.
    Update: Version 1.53.00 - 01/01/2021 - Lots of fixes, no longer listing details here. :)
    Update: Version 1.54.00 - 01/19/2021 - Bug fixes
    Update: Version 1.55.00 - 03/14/2021 - More bug fixes and some performance increases
    Update: Version 1.56.00 - 04/23/2021 - More bug fixes and additions
    Update: Version 1.57.00 - 11/12/2021 - Ported to Visual Studio 2022, more bug fixes and additions

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
As seen in

    Active Directory Third/Fourth Edition/Fifth Edition - O'Reilly Publishing
    Active Directory Cookbook Second/Third Edition/Fourth Edition - O'Reilly Publishing
    http://www.jsiinc.com in tips and tricks
    Windows IT Pro Magazine
    Thousands of blog posts.
    Thousands of newsgroup and web forum postings.
    Thousands of ActiveDir Org postings.
    Many articles and presentations about Hackers performing AD Recon and IR Teams working to catch them ;)

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Usage

    Download and type adfind /? for basic usage
    
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
See current usage screens
http://www.joeware.net/freetools/tools/adfind/usage.htm

 

 
