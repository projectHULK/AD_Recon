<#----------------------------------------------------------------------------------------------------

##########################################################################################
#                                                                                        #  
#    Discovering Privileged Accounts and Shadow Admins - using Advanced ACLs Analysis    #
#                                                                                        #
##########################################################################################


Release Notes:

The ACLight is a tool for discovering Privileged Accounts through advanced ACLs analysis.
It will discover the Shadow Admins in the network.
It queries the Active Directory for its objects' ACLs and then filters the sensitive permissions from each one of them.
The results are the domain privileged accounts in the network (from the advanced ACLs perspective of the AD).
It automatically scans all the domains of the forest.
You can run the scan with just any regular user in the domain (could be non-privleged user) and it needs PowerShell version 3+.
 
Version 1.0: 28.8.16
Version 1.1: 15.9.16
version 2.0: 17.5.17
version 2.1: 4.6.17

Authors: Asaf Hecht (@hechtov) - Cyberark's research team.
         Using functions from the great PowerView project created by: Will Schroeder (@harmj0y).
         The original PowerView have more functionalities:
         Powerview: https://github.com/PowerShellEmpire/PowerTools/tree/master/PowerView

------------------------------------------------------------------------------------------------------

HOW TO RUN:

option 1 - Just double click on "Execute-ACLight.bat".

- OR -

option 2 - Open cmd:
    Go to "ACLight" main folder -> 1) Type: cd "<ACLight folder path>"
    Run the "ACLight" script    -> 2) Type: powershell -noprofile -ExecutionPolicy Bypass Import-Module '.\ACLight.psm1' -force ; Start-ACLsAnalysis

- OR -

Option 3 - Open PowerShell (with -ExecutionPolicy Bypass):
    1) cd "<ACLight folder path>"
    2) Import-Module '.\ACLight.psm1' -force
    3) Start-ACLsAnalysis

Execute it and check the result!
You should take care of all the privileged accounts that the tool discovered for you.
Especially - take care of the Shadow Admins!
Those are accounts with direct sensitive ACLs assignments (not through the known privileged groups).

------------------------------------------------------------------------------------------------------

THE RESULTS FILES:

1) First check the - "Accounts with extra permissions.txt" file - It's straight-forward & powerful list of the privileged accounts that were discovered in the network.
2) "All entities with extra permissions.txt" - Will give you more sensitive entities in the network (also the "empty" entities like empty groups).
3) "Privileged Accounts Permissions - Final Report.csv" - This is the final summary report - in this file you can see what is the exact sensitive permission each account has.
4) "Privileged Accounts Permissions - Irregular Accounts.csv" - Similar to the final report just with only the privileged accounts that have direct permissions (not through their group membership).
5) "research.com - Full Output.csv" - Every domain that was scanned will have a csv with more raw results of the ACLs.


----------------------------------------------------------------------------------------------------#>

##Requires -Version 3.0 or above

######################################################################
#                                                                    #  
#    Section 1 - main functions for advanced analysis of the ACLs    #
#                                                                    #
######################################################################

# Create the results folder
$resultsPath = $PSScriptRoot + "\Results"
if (Test-Path $resultsPath)
{
    write-verbose "The results folder was already exists"
}
else
{
    New-Item -ItemType directory -Path $resultsPath
}

# Function for advanced ACLs analysis in a specified domain
function Start-domainACLsAnalysis {

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Full = $False,
        
        [String]
        $SamAccountName,

        [String]
        $Name = "*",

        [Alias('DN')]
        [String]
        $DistinguishedName = "*",

        [String]
        $Filter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        $Domain,

        [String]
        $DomainController,
                
        [String]
        $exportCsvFile = "C:\scanACLsResults.csv",

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    #clean the csv output file
    if (Test-Path $exportCsvFile) {
        Remove-Item $exportCsvFile
    }
    
    $Domaintime = New-Object system.Diagnostics.Stopwatch  
    $DomainTotaltime = New-Object system.Diagnostics.Stopwatch  
    $Domaintime.Start()
    $DomainTotaltime.Start()

    $DomainList = @()
    $PrivilegedOwners = @()
    $PrivilegedEntities = @()
    $PrivilegedGroups = @()
    $PrivilegedAccounts = @()
    $GroupMembersDB = @{}
    $domainPrivilegedOwners = @()
    $domainPrivilegedEntities = @()
    $count++
    $DomainDN = "DC=$($Domain.Replace('.', ',DC='))"
    Write-Output "Starting the scan for Domain: $domain"

    ###############################################################################################################################################
    #  Important - here you can choose each sensitive Active Directory objects you want to scan.
    #  You can add or remove scan filters and check the new results.
    #  It will affect the scanning time duration and the results might include less privileged accounts (if you choose less sensitive AD objects).
    #  It's also recommended to add here the privilged accounts that were discovered in previous scans - to discover who has control over them
    ###############################################################################################################################################
    
    # the root of the domain
    Invoke-ACLScanner -Full $Full -exportCsvFile $exportCsvFile -Domain $Domain -DistinguishedName $DomainDN
    # wild char on "admin" - it will be very interesting but also might includes less sensitive objects
    Invoke-ACLScanner @PSBoundParameters -Name '*admin*'
    # more built-in sensitive groups, every organization can add here more of his unique sensitive groups
    Invoke-ACLScanner @PSBoundParameters -Name 'Server Operators'
    Invoke-ACLScanner @PSBoundParameters -Name 'Account Operators'
    Invoke-ACLScanner @PSBoundParameters -Name 'Backup Operators'
    Invoke-ACLScanner @PSBoundParameters -Name 'Group Policy Creator Owners'
    # the krbtgt account
    Invoke-ACLScanner @PSBoundParameters -Name 'Krbtgt'
    # the main containers
    $ObjectName = "CN=Users,$DomainDN"
    Invoke-ACLScanner @PSBoundParameters -DistinguishedName $ObjectName
    $ObjectName = "CN=Computers,$DomainDN"
    Invoke-ACLScanner @PSBoundParameters -DistinguishedName $ObjectName
    $ObjectName = "CN=System,$DomainDN"
    Invoke-ACLScanner @PSBoundParameters -DistinguishedName $ObjectName
    $ObjectName = "CN=Policies,CN=System,$DomainDN"
    Invoke-ACLScanner @PSBoundParameters -DistinguishedName $ObjectName
    $ObjectName = "CN=Managed Service Accounts,$DomainDN"
    Invoke-ACLScanner @PSBoundParameters -DistinguishedName $ObjectName
    # the AdminSDHolder object
    $ObjectName = "CN=AdminSDHolder,CN=System,$DomainDN"
    Invoke-ACLScanner @PSBoundParameters -DistinguishedName $ObjectName
    
    #Analyze every OUs, if it's not Full scan it analyzes only the Domain Controller OU
    $domainOU = Get-NetOU -Domain $Domain
    $counter = 0
    $numberOU = $domainOU.count
    foreach ($OU in $domainOU){
        $counter++
        $OUdn = 'None'  
        $NameArray = $OU -split("/")
        [int]$NameCount = 0
        ForEach ($NameCell in $NameArray)
        { 
            $NameCount++
            if ($NameCount -eq 4){
                $OUdn = $NameCell
                }
        }
        if ($OUdn -match "Domain Controller"){
            if ($Full -eq $True){
                if ($counter -eq 1) {
                    Write-Output "Finished 13 analysis queries, there are still $numberOU more" 
                }
            }
            Invoke-ACLScanner @PSBoundParameters -DistinguishedName $OUdn
        }
        else {
            if ($Full -eq $True){
                if ($counter -eq 1) {
                    Write-Output "Finished 13 analysis queries, there are still $numberOU more" 
                }
                Invoke-ACLScanner @PSBoundParameters -DistinguishedName $OUdn
            }
        }
    }
    
    Write-Output "Finish first analysis on Domain: $Domain"
    $Domaintime.Stop()
    $runtime = $Domaintime.Elapsed.TotalMilliseconds
    $runtime = ($runtime/1000)
    $runtimeMin = ($runtime/60)
    $runtimeHours = ($runtime/3600)
    $runtime = [math]::round($runtime , 2)
    $runtimeMin = [math]::round($runtimeMin , 2)
    $runtimeHours = [math]::round($runtimeHours , 3)
    Write-Host "Time elapsed for this stage: $runtime Second, $runtimeMin Minutes, $runtimeHours Hours"
    $Domaintime.reset()                    
    $Domaintime.start()

    $NewListACLs = @()
    $ListObjectDNs = @()
    $domainGroups = Get-NetGroup -Domain $Domain
    if ($domainGroups.count -eq 0){
        write-warning "There was a critical problem of getting the domain groups"
    }

    $ObjectMembersList = @{}
    $counterLines = 0 
    $NameCount = 0  
    
    Import-Csv $exportCsvFile | Where-Object {$_} | ForEach-Object {
        If ($ListObjectDNs -notcontains $_.ObjectDN)
        {
            $ListObjectDNs += $_.ObjectDN
        }
        #adding group members
        $GroupMembers = $Null
        $EntityType = "Other"

        $domainGroupName = "None"            
        $NameArray = $_.UpdatedIdentityReference -Split("\\")
        $NameCount = 0
        ForEach ($NameCell in $NameArray)
        { 
            $NameCount++
            if ($NameCount -eq 1)
                {continue}
            else 
                {$domainGroupName = $NameCell}
        }
        if ($domainGroups -contains $domainGroupName) {
            $EntityType = "Group"
            if ($GroupMembersDB.ContainsKey($domainGroupName)){
                $GroupMembers = $GroupMembersDB.$domainGroupName
            }
            else {
                try {
                    $GroupMembersRecursive = Get-NetGroupMember -Domain $Domain -Recurse -UseMatchingRule -GroupName $domainGroupName
                }
                catch {
                    $GroupMembersRecursive = Get-NetGroupMember -Domain $Domain -GroupName $domainGroupName
                    #Write-Warning $_
                }
                $GroupMembers = @()
                foreach ($Entity in $GroupMembersRecursive){   
                    if (!($GroupMembers -match $Entity.MemberName)){
                        $GroupMembers += $Entity.MemberName
                    }
                }
                $GroupMembersDB.add($domainGroupName, $GroupMembers)
                $GroupMembersRecursive = $Null
            }
        }
        $GroupMembersCount = $GroupMembers.count
        
        #create the $ObjectMembersList
        $isMemberOfOtherGroups = $Null
        if ($domainGroups -contains $domainGroupName) {
            if ($ObjectMembersList.ContainsKey($_.ObjectDN)){
                $ObjectDN = $_.ObjectDN
                foreach ($user in $GroupMembers){
                    if ($ObjectMembersList.$ObjectDN -notcontains $domainGroupName){
                        $ObjectMembersList.$ObjectDN += $domainGroupName
                        if ($ObjectMembersList.$ObjectDN -notcontains $user){
                            $ObjectMembersList.$ObjectDN += $user                 
                        }
                    }
                }
            }
            else {
                $ObjectMembersList.add($_.ObjectDN, $GroupMembers)
            }
        }

        #in the future step it checks the class of the object
        $ObjectClassCategory = $Null

        #creates the structure to output the csv
        $ObjectACE = [PSCustomObject][ordered] @{
        #$ObjectACE = [PSCustomObject] @{
                        ObjectDN                = [string]$_.ObjectDN
                        ObjectOwner             = [string]$_.ObjectOwner
                        EntityName              = [string]$_.UpdatedIdentityReference
                        ActiveDirectoryRights   = [string]$_.ActiveDirectoryRights
                        ObjectRights            = [string]$_.ObjectType
                        ObjectClass             = [string]$_.ObjectClass
                        ObjectClassCategory     = [string]$ObjectClassCategory
                        EntityType              = [string]$EntityType                      
                        EntityGroupMembers      = [string]$GroupMembers
                        EntityGroupMembersCount = [string]$GroupMembersCount
                        isMemberOfOtherGroups   = [string]$isMemberOfOtherGroups                 
                        IsInherited             = [string]$_.IsInherited
                        PropagationFlags        = [string]$_.PropagationFlags
                        InheritanceFlags        = [string]$_.InheritanceFlags
                        InheritedObjectType     = [string]$_.InheritedObjectType
                        InheritanceType         = [string]$_.InheritanceType
                        ObjectFlags             = [string]$_.ObjectFlags
                        AccessControlType       = [string]$_.AccessControlType
                        ObjectSID               = [string]$_.ObjectSID
                        IdentitySID             = [string]$_.IdentitySID

        }
        $NewListACLs += $ObjectACE
        #counter
        $counterLines++
        $counter = $counterLines
        if (($counter %= 50000) -eq 0){
            write-host "$counterLines Permission lines were finished"
        }
        $_ = $Null
    }

    Write-Output "`nGood, the second stage was over"
    $Domaintime.Stop()
    $runtime = $Domaintime.Elapsed.TotalMilliseconds
    $runtime = ($runtime/1000)
    $runtimeMin = ($runtime/60)
    $runtimeHours = ($runtime/3600)
    $runtime = [math]::round($runtime , 2)
    $runtimeMin = [math]::round($runtimeMin , 2)
    $runtimeHours = [math]::round($runtimeHours , 3)
    Write-Host "Time of the second stage: $runtime Second, $runtimeMin Minutes, $runtimeHours Hours"
    $Domaintime.reset()                    
    $Domaintime.start() 

    foreach ($ACE in $NewListACLs){
        #check object class
        $ObjectClassCategory = $ACE.ObjectClass
        if ($ACE.ObjectClass -match "domain") {$ObjectClassCategory = "Domain"}
        elseif ($ACE.ObjectClass -match "container") {$ObjectClassCategory = "Container"}
        elseif ($ACE.ObjectClass -match "group") {$ObjectClassCategory = "Group"}
        elseif ($ACE.ObjectClass -match "computer") {$ObjectClassCategory = "Computer"}
        elseif ($ACE.ObjectClass -match "user") {$ObjectClassCategory = "User"}
        elseif ($ACE.ObjectClass -match "dns") {$ObjectClassCategory = "DNS"}
        elseif ($ACE.ObjectClass -match "organizationalUnit") {$ObjectClassCategory = "OU"}
        $ACE.ObjectClassCategory = $ObjectClassCategory

        try { 
            $isMemberOfOtherGroups = 'False'           
            $NameArray = $ACE.EntityName -split("\\")
            [int]$NameCount = 0
            ForEach ($NameCell in $NameArray)
            { 
                $NameCount++
                if ($NameCount -eq 1)
                    {continue}
                else 
                    {$userName = $NameCell}
            }
            $ObjectDN = $ACE.ObjectDN
            if ($userName.count -gt 0) {
                if ($ObjectMembersList.$ObjectDN -contains $userName) {
                    $isMemberOfOtherGroups = 'True'
                }
            }
            $ACE.isMemberOfOtherGroups = $isMemberOfOtherGroups
        }
        catch{}
    }

    $numObjectAnalyzed = $ListObjectDNs.Count
    $NewListACLs | Export-Csv -NoTypeInformation $exportCsvFile

    Write-Output "`nExcellent, The scan for $Domain was finished - check the results file:"
    Write-Output $exportCsvFile
    Write-Output "`nNumber of Objects that were Analyzed: $numObjectAnalyzed"
    $DomainTotaltime.Stop()
    $runtime = $DomainTotaltime.Elapsed.TotalMilliseconds
    $runtime = ($runtime/1000)
    $runtimeMin = ($runtime/60)
    $runtimeHours = ($runtime/3600)
    $runtime = [math]::round($runtime , 2)
    $runtimeMin = [math]::round($runtimeMin , 2)
    $runtimeHours = [math]::round($runtimeHours , 3)
    Write-Host "The scan for this Domain took: $runtime Second, $runtimeMin Minutes, $runtimeHours Hours"
}

# Function to reorder the results for more straight-forward output
function OrderPermissionsByAccounts {

    [CmdletBinding()]
    Param (
        [String]
        $inputCSV,
        
        [String]
        $Domain,

        [array]
        $privilegedAccountList,
        
        [hashtable]
        $domainsPrivilegedAccountDB,

        [String]
        $exportCsvFolder
    )

    $newAccountPermissionList = @()
    $owner = "ObjectOwner"
    $privDomainAcc = $domainsPrivilegedAccountDB.$Domain       
    Import-Csv $inputCSV | Where-Object {$_} | ForEach-Object {
        foreach($account in $privilegedAccountList){
            if (($_.EntityName -eq $account) -or ($_.EntityGroupMembers -eq $account)){
            $accountPermissionLine = [PSCustomObject][ordered] @{
                Domain                  = [string]$Domain
                AccountName             = [string]$account
                AccountGroup            = [string]$_.EntityName
                ActiveDirectoryRights   = [string]$_.ActiveDirectoryRights
                ObjectRights            = [string]$_.ObjectRights
                ObjectDN                = [string]$_.ObjectDN
                ObjectOwner             = [string]$_.ObjectOwner
                ObjectClassCategory     = [string]$_.ObjectClassCategory
            }   
            $newAccountPermissionList += $accountPermissionLine
            }
            else{
                if ($_.ObjectOwner -eq $account){
                    $accountPermissionLine = [PSCustomObject][ordered] @{
                        Domain                  = [string]$Domain
                        AccountName             = [string]$account
                        AccountGroup            = [string]$_.ObjectOwner
                        ActiveDirectoryRights   = [string]$owner
                        ObjectRights            = [string]$owner
                        ObjectDN                = [string]$_.ObjectDN
                        ObjectOwner             = [string]$_.ObjectOwner
                        ObjectClassCategory     = [string]$_.ObjectClassCategory
                    }   
                    $newAccountPermissionList += $accountPermissionLine
                }
            }
        } 
        foreach($account in $privDomainAcc){
            if ($_.EntityGroupMembers -match $account){
                $accountPermissionLine = [PSCustomObject][ordered] @{
                    Domain                  = [string]$Domain
                    AccountName             = [string]$account
                    AccountGroup            = [string]$_.EntityName
                    ActiveDirectoryRights   = [string]$_.ActiveDirectoryRights
                    ObjectRights            = [string]$_.ObjectRights
                    ObjectDN                = [string]$_.ObjectDN
                    ObjectOwner             = [string]$_.ObjectOwner
                    ObjectClassCategory     = [string]$_.ObjectClassCategory
                }   
            $newAccountPermissionList += $accountPermissionLine
            }
        }
    }
    $exportCsvFolder += $Domain
    $exportCsvFolder += " - Sensitive Accounts.csv"
    $exportAccCsvFile = $exportCsvFolder
    $newAccountPermissionList | sort AccountName, AccountGroup, Domain, ObjectDN | Export-Csv -NoTypeInformation $exportAccCsvFile
}

# The main function - here it's the starting point of the Privileged ACLs scan
function Start-ACLsAnalysis {
<#
    .SYNOPSIS
        Thi is the function to start the ACLs advanced scan.
        It will do analysis of the Permissions and ACLs on all the domains in the forest - automatically.
        In the end of the scanning - there will be good reports in the output folder.
        The scan will discover who are the privileged accounts in the forest and what permissions exactly they have.

    .EXAMPLE
        1. Open PowerShell
        2. Import-Module '.\ACLight.psm1' -force
        3. Start-ACLsAnalysis

#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Full = $False,
        
        [String]
        $SamAccountName,

        [String]
        $Name = "*",

        [Alias('DN')]
        [String]
        $DistinguishedName = "*",

        [String]
        $Filter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ScriptRoot = $PSScriptRoot,
                
        [String]
        $exportCsvFolder = "$resultsPath",

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    ) 
    
    if ($PSVersionTable.PSVersion.Major -ge 3){
        $time = New-Object system.Diagnostics.Stopwatch  
        $stagetime = New-Object system.Diagnostics.Stopwatch  
        $time.Start()

        Write-Output "`nGreat, the scan was started.`nIt could take a while (5-60+ mins) depends on the size of the network`n"

        $PathFolder = $exportCsvFolder
        $PathFolder = $PathFolder.substring($PathFolder.length - 1, 1)
        if ($PathFolder -ne "\"){
            $exportCsvFolder += "\"
        }

        $DomainList = Get-NetForestDomain
        $count = 0
        $privilegedAccountList = @()
        $privilegedAllList = @()
        $processPointersList = @()
        $domainsPrivilegedAccountDB = @{}
        $domainNumber = $DomainList.count
        Write-Output "Discovered $domainNumber Domain"

        # run ACLs analysis on every domain
        foreach ($Domain in $DomainList){
            Write-Output "`n******************************`nOpened process for analyzing Domain: $Domain`n"
            $exportCsvFile = $exportCsvFolder
            $exportCsvFile += $Domain
            $exportCsvFile += " - Full Output.csv"
            $exportCsvFile = '\"' + $exportCsvFile + '\"'

            # The scan will automatically scan all the domain in a parallel time - it's much more time efficient
            $processPointer = start-process powershell.exe -PassThru -WorkingDirectory $ScriptRoot -argument "-noprofile -ExecutionPolicy Bypass Import-Module '.\ACLight.psm1' -force ; Start-domainACLsAnalysis -Full $Full -exportCsvFile $exportCsvFile -Domain $Domain"
            $processPointersList += $processPointer

            # if you don't won't to scan all the domains in parallel (but one after the other):
            #$processPointer | Wait-Process
        }

        Write-Output "Waiting for all the scans to be completed.."
        foreach ($processPt in $processPointersList){
            try{
                $processPt | Wait-Process
            }
            catch{
            }
        }
        
        Write-Output "All the processes completed. Now, starting Accounts analysis.."

        foreach ($Domain in $DomainList){
            $exportCsvFile = $exportCsvFolder
            $exportCsvFile += $Domain
            $exportCsvFile += " - Full Output.csv"
            #create the final list of privileged accounts
            $privilegedDomainAccountList = @()
            $domainGroups = Get-NetGroup -Domain $Domain
            $domainUsers = Get-NetUser -Domain $Domain
            $domainUserList = @()
            $privDomain = @()
            $domainUserList = $domainUsers.name
            
            Import-Csv $exportCsvFile | Where-Object {$_} | ForEach-Object {
                If ($privilegedDomainAccountList -notcontains $_.ObjectOwner){
                    $privilegedDomainAccountList += $_.ObjectOwner
                }
                If ($privilegedDomainAccountList -notcontains $_.EntityName){
                    $privilegedDomainAccountList += $_.EntityName
                }
            }

            $EntityStartName = ""
            foreach ($fullNameEntity in $privilegedDomainAccountList){  
                $domainEntityName = $fullNameEntity  
                if ($fullNameEntity -match "\\"){         
                    $NameArray = $fullNameEntity -split("\\")
                    $NameCount = 0
                    ForEach ($NameCell in $NameArray)
                    { 
                        $NameCount++
                        if ($NameCount -eq 1){
                            $EntityStartName = $NameCell
                            }
                        else 
                            {$domainEntityName = $NameCell}
                    }
                }

                if ($privilegedAllList -notcontains $fullNameEntity){
                    $privilegedAllList += $fullNameEntity
                }
                if ($EntityStartName -notmatch "BUILTIN"){
                    if ($domainGroups -contains $domainEntityName){
                        try {
                            $GroupMembersRecursive = Get-NetGroupMember -domain $Domain -Recurse -UseMatchingRule -GroupName $domainEntityName
                        }
                        catch {
                            $GroupMembersRecursive = Get-NetGroupMember -domain $Domain -GroupName $domainEntityName
                            #Write-Warning $_
                        }
                        foreach ($accountName in $GroupMembersRecursive){
                            $accountDomainName = $EntityStartName + "\" + $accountName.MemberName
                            if ($privilegedAccountList -notcontains $accountDomainName){
                                $privilegedAccountList += $accountDomainName
                                #create hash table for accounts by their domain values
                                if ($privilegedAllList -notcontains $accountDomainName){
                                    $privilegedAllList += $accountDomainName
                                }
                            }
                            $accountN = $accountName.MemberName
                            if ($privDomain -notcontains $accountN){
                                $privDomain += $accountN
                            }
                        }
                    }
                    else {
                        if ($domainUserList -contains $domainEntityName){
                            if ($privilegedAccountList -notcontains $fullNameEntity ){
                                $privilegedAccountList += $fullNameEntity 
                            }
                            if ($privDomain -notcontains $domainEntityName){
                                $privDomain += $domainEntityName
                            }
                        }
                    }
                }
                # adding a special test for the dangerous case of "Authenticated Users"
                if ($fullNameEntity -like "NT AUTHORITY\Authenticated Users"){
                    if ($privilegedAccountList -notcontains $fullNameEntity ){
                        $privilegedAccountList += $fullNameEntity 
                    }
                }
            }

            $domainsPrivilegedAccountDB.add($Domain, $privDomain)

            $exportCsvFile = $exportCsvFolder
            $exportCsvFile += $Domain
            $exportCsvFile += " - Full Output.csv"
            OrderPermissionsByAccounts -inputCSV $exportCsvFile -Domain $Domain -domainsPrivilegedAccountDB $domainsPrivilegedAccountDB -privilegedAccountList $privilegedAccountList -exportCsvFolder $exportCsvFolder
        }
        $exportAllAccCsvFile = $exportCsvFolder
        $exportAllAccCsvFile += "Privileged Accounts Permissions - Final Report.csv" 
        $exportAllIrregularAccCsvFile = $exportCsvFolder + "Privileged Accounts Permissions - Irregular Accounts.csv"              

        if (Test-Path $exportAllAccCsvFile) {
            Remove-Item $exportAllAccCsvFile
        }
        if (Test-Path $exportAllIrregularAccCsvFile) {
            Remove-Item $exportAllIrregularAccCsvFile
        }
        foreach ($Domain in $DomainList){
            $exportAccCsvFile = $exportCsvFolder
            $exportAccCsvFile += $Domain
            $exportAccCsvFile += " - Sensitive Accounts.csv"
            $importedCsvData = Import-Csv $exportAccCsvFile 
            $importedCsvData | sort Domain,AccountName,AccountGroup,ActiveDirectoryRights,ObjectRights,ObjectDN,ObjectOwner,ObjectClassCategory -Unique | Export-Csv -NoTypeInformation -append $exportAllAccCsvFile             
            $importedCsvData | Where { ($_.AccountGroup -eq $_.AccountName)}  | sort Domain,AccountName,AccountGroup,ActiveDirectoryRights,ObjectRights,ObjectDN,ObjectOwner,ObjectClassCategory -Unique | Export-Csv -NoTypeInformation -append $exportAllIrregularAccCsvFile 
            if (Test-Path $exportAccCsvFile) {
                Remove-Item $exportAccCsvFile
            }
        }

        Write-Host "Finished Account analysis" 
        #create the final list of the privileged Accounts
        $exportListFile = $exportCsvFolder + "Accounts with extra permissions.txt"
        $privilegedAccountList | sort | Out-File $exportListFile 
        $numberAccounts = $privilegedAccountList.count
        
        Write-host "`nDiscovered $numberAccounts privileged accounts" -ForegroundColor Yellow
        Write-host "Check the list of the accounts with extra permissions:`n$exportListFile"
        write-host "`nPrivileged ACLs scan completed - the results are in  the folder:`n$exportCsvFolder`nCheck the `"Final Report`""-ForegroundColor Yellow

        $exportListFile = $exportCsvFolder + "All entities with extra permissions.txt"
        $privilegedAllList |  sort | Out-File $exportListFile 

        $time.Stop()
        $runtime = $time.Elapsed.TotalMilliseconds
        $runtime = ($runtime/1000)
        $runtimeMin = ($runtime/60)
        $runtimeHours = ($runtime/3600)
        $runtime = [math]::round($runtime , 2)
        $runtimeMin = [math]::round($runtimeMin , 2)
        $runtimeHours = [math]::round($runtimeHours , 3)
        #Write-Output "`n----------FINISHED----------`n`nTotal time of the scaning: $runtime Second, $runtimeMin Minutes, $runtimeHours Hours"
        #Write-Output "Check the results files in the folder: `n$exportCsvFolder `n"
    }
    else {
        Write-Output "`nSorry,`nThe tool need powershell version 3 or higher to perform the efficient Permissions scan`nYou can upgrade the PowerShell version from Microsoft official website:`nhttps://www.microsoft.com/en-us/download/details.aspx?id=34595`n`nFinished without running.`n"
    }
}


###############################################################
#                                                             #  
#    Section 2 - functions from PowerView                     #
#    The filter in Invoke-ACLScanner function was modified    #
#                                                             #
###############################################################

function Get-NetUser {
<#
    .SYNOPSIS

        Query information for a given user or users in the domain
        using ADSI and LDAP. Another -Domain can be specified to
        query for users across a trust.
        Replacement for "net users /domain"

    .PARAMETER UserName

        Username filter string, wildcards accepted.

    .PARAMETER Domain

        The domain to query for users, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER Filter

        A customized ldap filter string to use, e.g. "(description=*admin*)"

    .PARAMETER AdminCount

        Switch. Return users with adminCount=1.

    .PARAMETER SPN

        Switch. Only return user objects with non-null service principal names.

    .PARAMETER Unconstrained

        Switch. Return users that have unconstrained delegation.

    .PARAMETER AllowDelegation

        Switch. Return user accounts that are not marked as 'sensitive and not allowed for delegation'

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-NetUser -Domain testing

    .EXAMPLE

        PS C:\> Get-NetUser -ADSpath "LDAP://OU=secret,DC=testlab,DC=local"
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $UserName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $Filter,

        [Switch]
        $SPN,

        [Switch]
        $AdminCount,

        [Switch]
        $Unconstrained,

        [Switch]
        $AllowDelegation,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        # so this isn't repeated if users are passed on the pipeline
        $UserSearcher = Get-DomainSearcher -Domain $Domain -ADSpath $ADSpath -DomainController $DomainController -PageSize $PageSize
    }

    process {
        if($UserSearcher) {

            # if we're checking for unconstrained delegation
            if($Unconstrained) {
                Write-Verbose "Checking for unconstrained delegation"
                $Filter += "(userAccountControl:1.2.840.113556.1.4.803:=524288)"
            }
            if($AllowDelegation) {
                Write-Verbose "Checking for users who can be delegated"
                # negation of "Accounts that are sensitive and not trusted for delegation"
                $Filter += "(!(userAccountControl:1.2.840.113556.1.4.803:=1048574))"
            }
            if($AdminCount) {
                Write-Verbose "Checking for adminCount=1"
                $Filter += "(admincount=1)"
            }

            # check if we're using a username filter or not
            if($UserName) {
                # samAccountType=805306368 indicates user objects
                $UserSearcher.filter="(&(samAccountType=805306368)(samAccountName=$UserName)$Filter)"
            }
            elseif($SPN) {
                $UserSearcher.filter="(&(samAccountType=805306368)(servicePrincipalName=*)$Filter)"
            }
            else {
                # filter is something like "(samAccountName=*blah*)" if specified
                $UserSearcher.filter="(&(samAccountType=805306368)$Filter)"
            }

            $UserSearcher.FindAll() | Where-Object {$_} | ForEach-Object {
                # convert/process the LDAP fields for each result
                Convert-LDAPProperty -Properties $_.Properties
            }
        }
    }
}



function Get-NetForest {
<#
    .SYNOPSIS

        Returns a given forest object.

    .PARAMETER Forest

        The forest name to query for, defaults to the current domain.

    .EXAMPLE
    
        PS C:\> Get-NetForest -Forest external.domain
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Forest
    )

    process {
        if($Forest) {
            $ForestContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Forest', $Forest)
            try {
                $ForestObject = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ForestContext)
            }
            catch {
                Write-Debug "The specified forest $Forest does not exist, could not be contacted, or there isn't an existing trust."
                $Null
            }
        }
        else {
            # otherwise use the current forest
            $ForestObject = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        }

        if($ForestObject) {
            # get the SID of the forest root
            $ForestSid = (New-Object System.Security.Principal.NTAccount($ForestObject.RootDomain,"krbtgt")).Translate([System.Security.Principal.SecurityIdentifier]).Value
            $Parts = $ForestSid -Split "-"
            $ForestSid = $Parts[0..$($Parts.length-2)] -join "-"
            $ForestObject | Add-Member NoteProperty 'RootDomainSid' $ForestSid
            $ForestObject
        }
    }
}


function Get-NetForestDomain {
<#
    .SYNOPSIS

        Return all domains for a given forest.

    .PARAMETER Forest

        The forest name to query domain for.

    .PARAMETER Domain

        Return domains that match this term/wildcard.

    .EXAMPLE

        PS C:\> Get-NetForestDomain

    .EXAMPLE

        PS C:\> Get-NetForestDomain -Forest external.local
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Forest,

        [String]
        $Domain
    )

    process {
        if($Domain) {
            # try to detect a wild card so we use -like
            if($Domain.Contains('*')) {
                (Get-NetForest -Forest $Forest).Domains | Where-Object {$_.Name -like $Domain}
            }
            else {
                # match the exact domain name if there's not a wildcard
                (Get-NetForest -Forest $Forest).Domains | Where-Object {$_.Name.ToLower() -eq $Domain.ToLower()}
            }
        }
        else {
            # return all domains
            $ForestObject = Get-NetForest -Forest $Forest
            if($ForestObject) {
                $ForestObject.Domains
            }
        }
    }
}


function Get-NetDomain {
<#
    .SYNOPSIS

        Returns a given domain object.

    .PARAMETER Domain

        The domain name to query for, defaults to the current domain.

    .EXAMPLE

        PS C:\> Get-NetDomain -Domain testlab.local

    .LINK

        http://social.technet.microsoft.com/Forums/scriptcenter/en-US/0c5b3f83-e528-4d49-92a4-dee31f4b481c/finding-the-dn-of-the-the-domain-without-admodule-in-powershell?forum=ITCG
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Domain
    )

    process {
        if($Domain) {
            $DomainContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Domain', $Domain)
            try {
                [System.DirectoryServices.ActiveDirectory.Domain]::GetDomain($DomainContext)
            }
            catch {
                Write-Warning "The specified domain $Domain does not exist, could not be contacted, or there isn't an existing trust."
                $Null
            }
        }
        else {
            [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain()
        }
    }
}


function Get-NetGroup {
<#
    .SYNOPSIS

        Gets a list of all current groups in a domain, or all
        the groups a given user/group object belongs to.

    .PARAMETER GroupName

        The group name to query for, wildcards accepted.

    .PARAMETER SID

        The group SID to query for.

    .PARAMETER UserName

        The user name (or group name) to query for all effective
        groups of.

    .PARAMETER Filter

        A customized ldap filter string to use, e.g. "(description=*admin*)"

    .PARAMETER Domain

        The domain to query for groups, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER AdminCount

        Switch. Return group with adminCount=1.

    .PARAMETER FullData

        Switch. Return full group objects instead of just object names (the default).

    .PARAMETER RawSids

        Switch. Return raw SIDs when using "Get-NetGroup -UserName X"

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-NetGroup
        
        Returns the current groups in the domain.

    .EXAMPLE

        PS C:\> Get-NetGroup -GroupName *admin*
        
        Returns all groups with "admin" in their group name.

    .EXAMPLE

        PS C:\> Get-NetGroup -Domain testing -FullData
        
        Returns full group data objects in the 'testing' domain
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $GroupName = '*',

        [String]
        $SID,

        [String]
        $UserName,

        [String]
        $Filter,

        [String]
        $Domain,
        
        [String]
        $DomainController,
        
        [String]
        $ADSpath,

        [Switch]
        $AdminCount,

        [Switch]
        $FullData,

        [Switch]
        $RawSids,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        $GroupSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -PageSize $PageSize
    }

    process {
        if($GroupSearcher) {

            if($AdminCount) {
                Write-Verbose "Checking for adminCount=1"
                $Filter += "(admincount=1)"
            }

            if ($UserName) {
                # get the raw user object
                $User = Get-ADObject -SamAccountName $UserName -Domain $Domain -DomainController $DomainController -ReturnRaw -PageSize $PageSize

                # convert the user to a directory entry
                $UserDirectoryEntry = $User.GetDirectoryEntry()

                # cause the cache to calculate the token groups for the user
                $UserDirectoryEntry.RefreshCache("tokenGroups")

                $UserDirectoryEntry.TokenGroups | Foreach-Object {
                    # convert the token group sid
                    $GroupSid = (New-Object System.Security.Principal.SecurityIdentifier($_,0)).Value
                    
                    # ignore the built in users and default domain user group
                    if(!($GroupSid -match '^S-1-5-32-545|-513$')) {
                        if($FullData) {
                            Get-ADObject -SID $GroupSid -PageSize $PageSize
                        }
                        else {
                            if($RawSids) {
                                $GroupSid
                            }
                            else {
                                Convert-SidToName $GroupSid
                            }
                        }
                    }
                }
            }
            else {
                if ($SID) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }
                else {
                    $GroupSearcher.filter = "(&(objectCategory=group)(name=$GroupName)$Filter)"
                }
            
                $GroupSearcher.FindAll() | Where-Object {$_} | ForEach-Object {
                    # if we're returning full data objects
                    if ($FullData) {
                        # convert/process the LDAP fields for each result
                        Convert-LDAPProperty -Properties $_.Properties
                    }
                    else {
                        # otherwise we're just returning the group name
                        $_.properties.samaccountname
                    }
                }
            }
        }
    }
}


function Get-NetComputer {
<#
    .SYNOPSIS

        This function utilizes adsisearcher to query the current AD context
        for current computer objects. Based off of Carlos Perez's Audit.psm1
        script in Posh-SecMod (link below).

    .PARAMETER ComputerName

        Return computers with a specific name, wildcards accepted.

    .PARAMETER SPN

        Return computers with a specific service principal name, wildcards accepted.

    .PARAMETER OperatingSystem

        Return computers with a specific operating system, wildcards accepted.

    .PARAMETER ServicePack

        Return computers with a specific service pack, wildcards accepted.

    .PARAMETER Filter

        A customized ldap filter string to use, e.g. "(description=*admin*)"

    .PARAMETER Printers

        Switch. Return only printers.

    .PARAMETER Ping

        Switch. Ping each host to ensure it's up before enumerating.

    .PARAMETER FullData

        Switch. Return full computer objects instead of just system names (the default).

    .PARAMETER Domain

        The domain to query for computers, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER Unconstrained

        Switch. Return computer objects that have unconstrained delegation.

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-NetComputer
        
        Returns the current computers in current domain.

    .EXAMPLE

        PS C:\> Get-NetComputer -SPN mssql*
        
        Returns all MS SQL servers on the domain.

    .EXAMPLE

        PS C:\> Get-NetComputer -Domain testing
        
        Returns the current computers in 'testing' domain.

    .EXAMPLE

        PS C:\> Get-NetComputer -Domain testing -FullData
        
        Returns full computer objects in the 'testing' domain.

    .LINK

        https://github.com/darkoperator/Posh-SecMod/blob/master/Audit/Audit.psm1
#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [Alias('HostName')]
        [String]
        $ComputerName = '*',

        [String]
        $SPN,

        [String]
        $OperatingSystem,

        [String]
        $ServicePack,

        [String]
        $Filter,

        [Switch]
        $Printers,

        [Switch]
        $Ping,

        [Switch]
        $FullData,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $Unconstrained,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        # so this isn't repeated if users are passed on the pipeline
        $CompSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -PageSize $PageSize
    }

    process {

        if ($CompSearcher) {

            # if we're checking for unconstrained delegation
            if($Unconstrained) {
                Write-Verbose "Searching for computers with for unconstrained delegation"
                $Filter += "(userAccountControl:1.2.840.113556.1.4.803:=524288)"
            }
            # set the filters for the seracher if it exists
            if($Printers) {
                Write-Verbose "Searching for printers"
                # $CompSearcher.filter="(&(objectCategory=printQueue)$Filter)"
                $Filter += "(objectCategory=printQueue)"
            }
            if($SPN) {
                Write-Verbose "Searching for computers with SPN: $SPN"
                $Filter += "(servicePrincipalName=$SPN)"
            }
            if($OperatingSystem) {
                $Filter += "(operatingsystem=$OperatingSystem)"
            }
            if($ServicePack) {
                $Filter += "(operatingsystemservicepack=$ServicePack)"
            }

            $CompSearcher.filter = "(&(sAMAccountType=805306369)(dnshostname=$ComputerName)$Filter)"

            try {

                $CompSearcher.FindAll() | Where-Object {$_} | ForEach-Object {
                    $Up = $True
                    if($Ping) {
                        # TODO: how can these results be piped to ping for a speedup?
                        $Up = Test-Connection -Count 1 -Quiet -ComputerName $_.properties.dnshostname
                    }
                    if($Up) {
                        # return full data objects
                        if ($FullData) {
                            # convert/process the LDAP fields for each result
                            Convert-LDAPProperty -Properties $_.Properties
                        }
                        else {
                            # otherwise we're just returning the DNS host name
                            $_.properties.dnshostname
                        }
                    }
                }
            }
            catch {
                Write-Warning "Error: $_"
            }
        }
    }
}


function Get-DomainSID {
<#
    .SYNOPSIS

        Gets the SID for the domain.

    .PARAMETER Domain

        The domain to query, defaults to the current domain.

    .EXAMPLE

        C:\> Get-DomainSID -Domain TEST
        
        Returns SID for the domain 'TEST'
#>

    param(
        [String]
        $Domain
    )

    $FoundDomain = Get-NetDomain -Domain $Domain
    
    if($FoundDomain) {
        # query for the primary domain controller so we can extract the domain SID for filtering
        $PrimaryDC = $FoundDomain.PdcRoleOwner
        $PrimaryDCSID = (Get-NetComputer -Domain $Domain -ComputerName $PrimaryDC -FullData).objectsid
        $Parts = $PrimaryDCSID.split("-")
        $Parts[0..($Parts.length -2)] -join "-"
    }
}




function Convert-SidToName {
<#
    .SYNOPSIS
    
        Converts a security identifier (SID) to a group/user name.

    .PARAMETER SID
    
        The SID to convert.

    .EXAMPLE

        PS C:\> Convert-SidToName S-1-5-21-2620891829-2411261497-1773853088-1105
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [String]
        $SID
    )

    process {
        try {
            $SID2 = $SID.trim('*')

            # try to resolve any built-in SIDs first
            #   from https://support.microsoft.com/en-us/kb/243330
            Switch ($SID2)
            {
                'S-1-0'         { 'Null Authority' }
                'S-1-0-0'       { 'Nobody' }
                'S-1-1'         { 'World Authority' }
                'S-1-1-0'       { 'Everyone' }
                'S-1-2'         { 'Local Authority' }
                'S-1-2-0'       { 'Local' }
                'S-1-2-1'       { 'Console Logon ' }
                'S-1-3'         { 'Creator Authority' }
                'S-1-3-0'       { 'Creator Owner' }
                'S-1-3-1'       { 'Creator Group' }
                'S-1-3-2'       { 'Creator Owner Server' }
                'S-1-3-3'       { 'Creator Group Server' }
                'S-1-3-4'       { 'Owner Rights' }
                'S-1-4'         { 'Non-unique Authority' }
                'S-1-5'         { 'NT Authority' }
                'S-1-5-1'       { 'Dialup' }
                'S-1-5-2'       { 'Network' }
                'S-1-5-3'       { 'Batch' }
                'S-1-5-4'       { 'Interactive' }
                'S-1-5-6'       { 'Service' }
                'S-1-5-7'       { 'Anonymous' }
                'S-1-5-8'       { 'Proxy' }
                'S-1-5-9'       { 'Enterprise Domain Controllers' }
                'S-1-5-10'      { 'Principal Self' }
                'S-1-5-11'      { 'Authenticated Users' }
                'S-1-5-12'      { 'Restricted Code' }
                'S-1-5-13'      { 'Terminal Server Users' }
                'S-1-5-14'      { 'Remote Interactive Logon' }
                'S-1-5-15'      { 'This Organization ' }
                'S-1-5-17'      { 'This Organization ' }
                'S-1-5-18'      { 'Local System' }
                'S-1-5-19'      { 'NT Authority' }
                'S-1-5-20'      { 'NT Authority' }
                'S-1-5-80-0'    { 'All Services ' }
                'S-1-5-32-544'  { 'BUILTIN\Administrators' }
                'S-1-5-32-545'  { 'BUILTIN\Users' }
                'S-1-5-32-546'  { 'BUILTIN\Guests' }
                'S-1-5-32-547'  { 'BUILTIN\Power Users' }
                'S-1-5-32-548'  { 'BUILTIN\Account Operators' }
                'S-1-5-32-549'  { 'BUILTIN\Server Operators' }
                'S-1-5-32-550'  { 'BUILTIN\Print Operators' }
                'S-1-5-32-551'  { 'BUILTIN\Backup Operators' }
                'S-1-5-32-552'  { 'BUILTIN\Replicators' }
                'S-1-5-32-554'  { 'BUILTIN\Pre-Windows 2000 Compatible Access' }
                'S-1-5-32-555'  { 'BUILTIN\Remote Desktop Users' }
                'S-1-5-32-556'  { 'BUILTIN\Network Configuration Operators' }
                'S-1-5-32-557'  { 'BUILTIN\Incoming Forest Trust Builders' }
                'S-1-5-32-558'  { 'BUILTIN\Performance Monitor Users' }
                'S-1-5-32-559'  { 'BUILTIN\Performance Log Users' }
                'S-1-5-32-560'  { 'BUILTIN\Windows Authorization Access Group' }
                'S-1-5-32-561'  { 'BUILTIN\Terminal Server License Servers' }
                'S-1-5-32-562'  { 'BUILTIN\Distributed COM Users' }
                'S-1-5-32-569'  { 'BUILTIN\Cryptographic Operators' }
                'S-1-5-32-573'  { 'BUILTIN\Event Log Readers' }
                'S-1-5-32-574'  { 'BUILTIN\Certificate Service DCOM Access' }
                'S-1-5-32-575'  { 'BUILTIN\RDS Remote Access Servers' }
                'S-1-5-32-576'  { 'BUILTIN\RDS Endpoint Servers' }
                'S-1-5-32-577'  { 'BUILTIN\RDS Management Servers' }
                'S-1-5-32-578'  { 'BUILTIN\Hyper-V Administrators' }
                'S-1-5-32-579'  { 'BUILTIN\Access Control Assistance Operators' }
                'S-1-5-32-580'  { 'BUILTIN\Access Control Assistance Operators' }
                Default { 
                    $Obj = (New-Object System.Security.Principal.SecurityIdentifier($SID2))
                    $Obj.Translate( [System.Security.Principal.NTAccount]).Value
                }
            }
        }
        catch {
            # Write-Warning "Invalid SID: $SID"
            $SID
        }
    }
}


function Convert-NameToSid {
<#
    .SYNOPSIS

        Converts a given user/group name to a security identifier (SID).

    .PARAMETER ObjectName

        The user/group name to convert, can be 'user' or 'DOMAIN\user' format.

    .PARAMETER Domain

        Specific domain for the given user account, defaults to the current domain.

    .EXAMPLE

        PS C:\> Convert-NameToSid 'DEV\dfm'
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [String]
        [Alias('Name')]
        $ObjectName,

        [String]
        $Domain = (Get-NetDomain).Name
    )

    process {
        
        $ObjectName = $ObjectName -replace "/","\"
        
        if($ObjectName.contains("\")) {
            # if we get a DOMAIN\user format, auto convert it
            $Domain = $ObjectName.split("\")[0]
            $ObjectName = $ObjectName.split("\")[1]
        }

        try {
            $Obj = (New-Object System.Security.Principal.NTAccount($Domain,$ObjectName))
            $Obj.Translate([System.Security.Principal.SecurityIdentifier]).Value
        }
        catch {
            Write-Verbose "Invalid object/name: $Domain\$ObjectName"
            $Null
        }
    }
}


function Convert-LDAPProperty {
    # helper to convert specific LDAP property result fields
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateNotNullOrEmpty()]
        $Properties
    )

    $ObjectProperties = @{}

    $Properties.PropertyNames | ForEach-Object {
        if (($_ -eq "objectsid") -or ($_ -eq "sidhistory")) {
            # convert the SID to a string
            $ObjectProperties[$_] = (New-Object System.Security.Principal.SecurityIdentifier($Properties[$_][0],0)).Value
        }
        elseif($_ -eq "objectguid") {
            # convert the GUID to a string
            $ObjectProperties[$_] = (New-Object Guid (,$Properties[$_][0])).Guid
        }
        elseif( ($_ -eq "lastlogon") -or ($_ -eq "lastlogontimestamp") -or ($_ -eq "pwdlastset") -or ($_ -eq "lastlogoff") -or ($_ -eq "badPasswordTime") ) {
            # convert timestamps
            if ($Properties[$_][0] -is [System.MarshalByRefObject]) {
                # if we have a System.__ComObject
                $Temp = $Properties[$_][0]
                [Int32]$High = $Temp.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                [Int32]$Low  = $Temp.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                $ObjectProperties[$_] = ([datetime]::FromFileTime([Int64]("0x{0:x8}{1:x8}" -f $High, $Low)))
            }
            else {
                $ObjectProperties[$_] = ([datetime]::FromFileTime(($Properties[$_][0])))
            }
        }
        elseif($Properties[$_][0] -is [System.MarshalByRefObject]) {
            # convert misc com objects
            $Prop = $Properties[$_]
            try {
                $Temp = $Prop[$_][0]
                Write-Verbose $_
                [Int32]$High = $Temp.GetType().InvokeMember("HighPart", [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                [Int32]$Low  = $Temp.GetType().InvokeMember("LowPart",  [System.Reflection.BindingFlags]::GetProperty, $null, $Temp, $null)
                $ObjectProperties[$_] = [Int64]("0x{0:x8}{1:x8}" -f $High, $Low)
            }
            catch {
                $ObjectProperties[$_] = $Prop[$_]
            }
        }
        elseif($Properties[$_].count -eq 1) {
            $ObjectProperties[$_] = $Properties[$_][0]
        }
        else {
            $ObjectProperties[$_] = $Properties[$_]
        }
    }

    New-Object -TypeName PSObject -Property $ObjectProperties
}




function Get-NetGroupMember {
<#
    .SYNOPSIS

        This function users [ADSI] and LDAP to query the current AD context
        or trusted domain for users in a specified group. If no GroupName is
        specified, it defaults to querying the "Domain Admins" group.
        This is a replacement for "net group 'name' /domain"

    .PARAMETER GroupName

        The group name to query for users.

    .PARAMETER SID

        The Group SID to query for users. If not given, it defaults to 512 "Domain Admins"

    .PARAMETER Filter

        A customized ldap filter string to use, e.g. "(description=*admin*)"

    .PARAMETER Domain

        The domain to query for group users, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER FullData

        Switch. Returns full data objects instead of just group/users.

    .PARAMETER Recurse

        Switch. If the group member is a group, recursively try to query its members as well.

    .PARAMETER UseMatchingRule

        Switch. Use LDAP_MATCHING_RULE_IN_CHAIN in the LDAP search query when -Recurse is specified.
        Much faster than manual recursion, but doesn't reveal cross-domain groups.

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-NetGroupMember
        
        Returns the usernames that of members of the "Domain Admins" domain group.

    .EXAMPLE

        PS C:\> Get-NetGroupMember -Domain testing -GroupName "Power Users"
        
        Returns the usernames that of members of the "Power Users" group in the 'testing' domain.

    .LINK

        http://www.powershellmagazine.com/2013/05/23/pstip-retrieve-group-membership-of-an-active-directory-group-recursively/
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $GroupName,

        [String]
        $SID,

        [String]
        $Domain = (Get-NetDomain).Name,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $FullData,

        [Switch]
        $Recurse,

        [Switch]
        $UseMatchingRule,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        # so this isn't repeated if users are passed on the pipeline
        $GroupSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -PageSize $PageSize

        if(!$DomainController) {
            $DomainController = ((Get-NetDomain).PdcRoleOwner).Name
        }
    }

    process {
        ##
        #$GroupSearcher.PropertiesToLoad.AddRange(('distinguishedName','samaccounttype','lastlogon','lastlogontimestamp','dscorepropagationdata','objectsid','whencreated','badpasswordtime','accountexpires','iscriticalsystemobject','name','usnchanged','objectcategory','description','codepage','instancetype','countrycode','distinguishedname','cn','admincount','logonhours','objectclass','logoncount','usncreated','useraccountcontrol','objectguid','primarygroupid','lastlogoff','samaccountname','badpwdcount','whenchanged','memberof','pwdlastset','adspath'))
        if ($GroupSearcher) {

            if ($Recurse -and $UseMatchingRule) {
                # resolve the group to a distinguishedname
                if ($GroupName) {
                    $Group = Get-NetGroup -GroupName $GroupName -Domain $Domain -FullData -PageSize $PageSize
                }
                elseif ($SID) {
                    $Group = Get-NetGroup -SID $SID -Domain $Domain -FullData -PageSize $PageSize
                }
                else {
                    # default to domain admins
                    $SID = (Get-DomainSID -Domain $Domain) + "-512"
                    $Group = Get-NetGroup -SID $SID -Domain $Domain -FullData -PageSize $PageSize
                }
                $GroupDN = $Group.distinguishedname
                $GroupFoundName = $Group.name

                if ($GroupDN) {
                    $GroupSearcher.filter = "(&(samAccountType=805306368)(memberof:1.2.840.113556.1.4.1941:=$GroupDN)$Filter)"
                    #updated
                    $GroupSearcher.PropertiesToLoad.AddRange(('distinguishedName','samaccounttype','lastlogon','lastlogontimestamp','dscorepropagationdata','objectsid','whencreated','badpasswordtime','accountexpires','iscriticalsystemobject','name','usnchanged','objectcategory','description','codepage','instancetype','countrycode','distinguishedname','cn','admincount','logonhours','objectclass','logoncount','usncreated','useraccountcontrol','objectguid','primarygroupid','lastlogoff','samaccountname','badpwdcount','whenchanged','memberof','pwdlastset','adspath'))
                    #$GroupSearcher.PropertiesToLoad.AddRange(('distinguishedName','samaccounttype','objectsid','name','cn','objectclass','useraccountcontrol','objectguid','memberof','adspath'))

                    $Members = $GroupSearcher.FindAll()
                    $GroupFoundName = $GroupName
                }
                else {
                    Write-Error "Unable to find Group"
                }
            }
            else {
                if ($GroupName) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(name=$GroupName)$Filter)"
                }
                elseif ($SID) {
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }
                else {
                    # default to domain admins
                    $SID = (Get-DomainSID -Domain $Domain) + "-512"
                    $GroupSearcher.filter = "(&(objectCategory=group)(objectSID=$SID)$Filter)"
                }

                $GroupSearcher.FindAll() | ForEach-Object {
                    try {
                        if (!($_) -or !($_.properties) -or !($_.properties.name)) { continue }

                        $GroupFoundName = $_.properties.name[0]
                        $Members = @()

                        if ($_.properties.member.Count -eq 0) {
                            $Finished = $False
                            $Bottom = 0
                            $Top = 0
                            while(!$Finished) {
                                $Top = $Bottom + 1499
                                $MemberRange="member;range=$Bottom-$Top"
                                $Bottom += 1500
                                $GroupSearcher.PropertiesToLoad.Clear()
                                [void]$GroupSearcher.PropertiesToLoad.Add("$MemberRange")
                                try {
                                    $Result = $GroupSearcher.FindOne()
                                    if ($Result) {
                                        $RangedProperty = $_.Properties.PropertyNames -like "member;range=*"
                                        $Results = $_.Properties.item($RangedProperty)
                                        if ($Results.count -eq 0) {
                                            $Finished = $True
                                        }
                                        else {
                                            $Results | ForEach-Object {
                                                $Members += $_
                                            }
                                        }
                                    }
                                    else {
                                        $Finished = $True
                                    }
                                } 
                                catch [System.Management.Automation.MethodInvocationException] {
                                    $Finished = $True
                                }
                            }
                        } 
                        else {
                            $Members = $_.properties.member
                        }
                    } 
                    catch {
                        Write-Verbose $_
                    }
                }
            }

            $Members | Where-Object {$_} | ForEach-Object {
                # if we're doing the LDAP_MATCHING_RULE_IN_CHAIN recursion
                if ($Recurse -and $UseMatchingRule) {
                    $Properties = $_.Properties
                } 
                else {
                    if($DomainController) {
                        $Result = [adsi]"LDAP://$DomainController/$_"
                    }
                    else {
                        $Result = [adsi]"LDAP://$_"
                    }
                    if($Result){
                        $Properties = $Result.Properties
                    }
                }

                if($Properties) {

                    if($Properties.samaccounttype -notmatch '805306368') {
                        $IsGroup = $True
                    }
                    else {
                        $IsGroup = $False
                    }

                    if ($FullData) {
                        $GroupMember = Convert-LDAPProperty -Properties $Properties
                    }
                    else {
                        $GroupMember = New-Object PSObject
                    }

                    $GroupMember | Add-Member Noteproperty 'GroupDomain' $Domain
                    $GroupMember | Add-Member Noteproperty 'GroupName' $GroupFoundName

                    try {
                        $MemberDN = $Properties.distinguishedname[0]
                        
                        # extract the FQDN from the Distinguished Name
                        $MemberDomain = $MemberDN.subString($MemberDN.IndexOf("DC=")) -replace 'DC=','' -replace ',','.'
                    }
                    catch {
                        $MemberDN = $Null
                        $MemberDomain = $Null
                    }

                    if ($Properties.samaccountname) {
                        # forest users have the samAccountName set
                        $MemberName = $Properties.samaccountname[0]
                    } 
                    else {
                        # external trust users have a SID, so convert it
                        try {
                            $MemberName = Convert-SidToName $Properties.cn[0]
                        }
                        catch {
                            # if there's a problem contacting the domain to resolve the SID
                            $MemberName = $Properties.cn
                        }
                    }
                    
                    if($Properties.objectSid) {
                        $MemberSid = ((New-Object System.Security.Principal.SecurityIdentifier $Properties.objectSid[0],0).Value)
                    }
                    else {
                        $MemberSid = $Null
                    }

                    $GroupMember | Add-Member Noteproperty 'MemberDomain' $MemberDomain
                    $GroupMember | Add-Member Noteproperty 'MemberName' $MemberName
                    $GroupMember | Add-Member Noteproperty 'MemberSid' $MemberSid
                    $GroupMember | Add-Member Noteproperty 'IsGroup' $IsGroup
                    $GroupMember | Add-Member Noteproperty 'MemberDN' $MemberDN
                    $GroupMember

                    # if we're doing manual recursion
                    if ($Recurse -and !$UseMatchingRule -and $IsGroup -and $MemberName) {
                        Get-NetGroupMember -FullData -Domain $MemberDomain -DomainController $DomainController -GroupName $MemberName -Recurse -PageSize $PageSize
                    }
                }

            }
        }
    }
}


function Get-DomainSearcher {
<#
    .SYNOPSIS

        Helper used by various functions that takes an ADSpath and
        domain specifier and builds the correct ADSI searcher object.

    .PARAMETER Domain

        The domain to use for the query, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER ADSprefix

        Prefix to set for the searcher (like "CN=Sites,CN=Configuration")

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-DomainSearcher -Domain testlab.local

    .EXAMPLE

        PS C:\> Get-DomainSearcher -Domain testlab.local -DomainController SECONDARY.dev.testlab.local
#>

    [CmdletBinding()]
    param(
        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    if(!$Domain) {
        $Domain = (Get-NetDomain).name
    }
    else {
        if(!$DomainController) {
            try {
                # if there's no -DomainController specified, try to pull the primary DC
                #   to reflect queries through
                $DomainController = ((Get-NetDomain).PdcRoleOwner).Name
            }
            catch {
                throw "Get-DomainSearcher: Error in retrieving PDC for current domain"
            }
        }
    }

    $SearchString = "LDAP://"

    if($DomainController) {
        $SearchString += $DomainController + "/"
    }
    if($ADSprefix) {
        $SearchString += $ADSprefix + ","
    }

    if($ADSpath) {
        if($ADSpath -like "GC://*") {
            # if we're searching the global catalog
            $DistinguishedName = $AdsPath
            $SearchString = ""
        }
        else {
            if($ADSpath -like "LDAP://*") {
                $ADSpath = $ADSpath.Substring(7)
            }
            $DistinguishedName = $ADSpath
        }
    }
    else {
        $DistinguishedName = "DC=$($Domain.Replace('.', ',DC='))"
    }

    $SearchString += $DistinguishedName
    Write-Verbose "Get-DomainSearcher search string: $SearchString"

    $Searcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]$SearchString)
    $Searcher.PageSize = $PageSize
    <#new - to search only specific properties
    $Properies = "samaccountname","displayname", "SID", "userprincipalname", "memberof","ObjectClass","objectsid", "objectguid","distinguishedName","name","cn", "dnshostname"
    foreach ($Property in $Properies)
    {
        $Searcher.PropertiesToLoad.Add($Property) | Out-Null
    }
    #>
    $Searcher
}


function Get-NetOU {
<#
    .SYNOPSIS

        Gets a list of all current OUs in a domain.

    .PARAMETER OUName

        The OU name to query for, wildcards accepted.

    .PARAMETER GUID

        Only return OUs with the specified GUID in their gplink property.

    .PARAMETER Domain

        The domain to query for OUs, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER ADSpath

        The LDAP source to search through.

    .PARAMETER FullData

        Switch. Return full OU objects instead of just object names (the default).

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-NetOU
        
        Returns the current OUs in the domain.

    .EXAMPLE

        PS C:\> Get-NetOU -OUName *admin* -Domain testlab.local
        
        Returns all OUs with "admin" in their name in the testlab.local domain.

     .EXAMPLE

        PS C:\> Get-NetOU -GUID 123-...
        
        Returns all OUs with linked to the specified group policy object.    
#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $OUName = '*',

        [String]
        $GUID,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [Switch]
        $FullData,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    begin {
        $OUSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -PageSize $PageSize
    }
    process {
        if ($OUSearcher) {
            if ($GUID) {
                # if we're filtering for a GUID in .gplink
                $OUSearcher.filter="(&(objectCategory=organizationalUnit)(name=$OUName)(gplink=*$GUID*))"
            }
            else {
                $OUSearcher.filter="(&(objectCategory=organizationalUnit)(name=$OUName))"
            }

            $OUSearcher.FindAll() | Where-Object {$_} | ForEach-Object {
                if ($FullData) {
                    # convert/process the LDAP fields for each result
                    Convert-LDAPProperty -Properties $_.Properties
                }
                else { 
                    # otherwise just returning the ADS paths of the OUs
                    $_.properties.adspath
                }
            }
        }
    }
}


function Get-NetForest {
<#
    .SYNOPSIS

        Returns a given forest object.

    .PARAMETER Forest

        The forest name to query for, defaults to the current domain.

    .EXAMPLE
    
        PS C:\> Get-NetForest -Forest external.domain
#>

    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Forest
    )

    process {
        if($Forest) {
            $ForestContext = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext('Forest', $Forest)
            try {
                $ForestObject = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($ForestContext)
            }
            catch {
                Write-Debug "The specified forest $Forest does not exist, could not be contacted, or there isn't an existing trust."
                $Null
            }
        }
        else {
            # otherwise use the current forest
            $ForestObject = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        }

        if($ForestObject) {
            # get the SID of the forest root
            $ForestSid = (New-Object System.Security.Principal.NTAccount($ForestObject.RootDomain,"krbtgt")).Translate([System.Security.Principal.SecurityIdentifier]).Value
            $Parts = $ForestSid -Split "-"
            $ForestSid = $Parts[0..$($Parts.length-2)] -join "-"
            $ForestObject | Add-Member NoteProperty 'RootDomainSid' $ForestSid
            $ForestObject
        }
    }
}


function Get-ADObject {
<#
    .SYNOPSIS

        Takes a domain SID and returns the user, group, or computer object
        associated with it.

    .PARAMETER SID

        The SID of the domain object you're querying for.

    .PARAMETER Name

        The Name of the domain object you're querying for.

    .PARAMETER SamAccountName

        The SamAccountName of the domain object you're querying for. 

    .PARAMETER Domain

        The domain to query for objects, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER Filter

        Additional LDAP filter string for the query.

    .PARAMETER ReturnRaw

        Switch. Return the raw object instead of translating its properties.
        Used by Set-ADObject to modify object properties.

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-ADObject -SID "S-1-5-21-2620891829-2411261497-1773853088-1110"
        
        Get the domain object associated with the specified SID.
        
    .EXAMPLE

        PS C:\> Get-ADObject -ADSpath "CN=AdminSDHolder,CN=System,DC=testlab,DC=local"
        
        Get the AdminSDHolder object for the testlab.local domain.
#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $SID,

        [String]
        $Name,

        [String]
        $SamAccountName,

        [String]
        $Domain,

        [String]
        $DomainController,

        [String]
        $ADSpath,

        [String]
        $Filter,

        [Switch]
        $ReturnRaw,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )
    process {
        if($SID) {
            # if a SID is passed, try to resolve it to a reachable domain name for the searcher
            try {
                $Name = Convert-SidToName $SID
                if($Name) {
                    $Canonical = Convert-NT4toCanonical -ObjectName $Name
                    if($Canonical) {
                        $Domain = $Canonical.split("/")[0]
                    }
                    else {
                        Write-verbose "Error resolving SID '$SID'"
                        return $Null
                    }
                }
            }
            catch {
                Write-verbose "Error resolving SID '$SID' : $_"
                return $Null
            }
        }

        $ObjectSearcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -PageSize $PageSize

        if($ObjectSearcher) {

            if($SID) {
                $ObjectSearcher.filter = "(&(objectsid=$SID)$Filter)"
            }
            elseif($Name) {
                $ObjectSearcher.filter = "(&(name=$Name)$Filter)"
            }
            elseif($SamAccountName) {
                $ObjectSearcher.filter = "(&(samAccountName=$SamAccountName)$Filter)"
            }

            $ObjectSearcher.FindAll() | Where-Object {$_} | ForEach-Object {
                if($ReturnRaw) {
                    $_
                }
                else {
                    # convert/process the LDAP fields for each result
                    Convert-LDAPProperty -Properties $_.Properties
                }
            }
        }
    }
}



function Get-GUIDMap {
<#
    .SYNOPSIS

        Helper to build a hash table of [GUID] -> resolved names

        Heavily adapted from http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx

    .PARAMETER Domain
    
        The domain to use for the query, defaults to the current domain.

    .PARAMETER DomainController
    
        Domain controller to reflect LDAP queries through.

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .LINK

        http://blogs.technet.com/b/ashleymcglone/archive/2013/03/25/active-directory-ou-permissions-report-free-powershell-script-download.aspx
#>

    [CmdletBinding()]
    Param (
        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )

    $GUIDs = @{'00000000-0000-0000-0000-000000000000' = 'All'}

    $SchemaPath = (Get-NetForest).schema.name

    $SchemaSearcher = Get-DomainSearcher -ADSpath $SchemaPath -DomainController $DomainController -PageSize $PageSize
    if($SchemaSearcher) {
        $SchemaSearcher.filter = "(schemaIDGUID=*)"
        try {
            $SchemaSearcher.FindAll() | Where-Object {$_} | ForEach-Object {
                # convert the GUID
                $GUIDs[(New-Object Guid (,$_.properties.schemaidguid[0])).Guid] = $_.properties.name[0]
            }
        }
        catch {
            Write-Debug "Error in building GUID map: $_"
        }      
    }

    $RightsSearcher = Get-DomainSearcher -ADSpath $SchemaPath.replace("Schema","Extended-Rights") -DomainController $DomainController -PageSize $PageSize
    if ($RightsSearcher) {
        $RightsSearcher.filter = "(objectClass=controlAccessRight)"
        try {
            $RightsSearcher.FindAll() | Where-Object {$_} | ForEach-Object {
                # convert the GUID
                $GUIDs[$_.properties.rightsguid[0].toString()] = $_.properties.name[0]
            }
        }
        catch {
            Write-Debug "Error in building GUID map: $_"
        }
    }

    $GUIDs
}

function Get-ObjectAcl {
<#
    .SYNOPSIS
        Returns the ACLs associated with a specific active directory object.

    .PARAMETER SamAccountName

        Object name to filter for.        

    .PARAMETER Name

        Object name to filter for.

    .PARAMETER DistinguishedName

        Object distinguished name to filter for.

    .PARAMETER Filter

        A customized ldap filter string to use, e.g. "(description=*admin*)"
     
    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER ADSprefix

        Prefix to set for the searcher (like "CN=Sites,CN=Configuration")

    .PARAMETER RightsFilter

        Only return results with the associated rights, "All", "ResetPassword","WriteMembers"

    .PARAMETER Domain

        The domain to use for the query, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Get-ObjectAcl -SamAccountName matt.admin -domain testlab.local
        
        Get the ACLs for the matt.admin user in the testlab.local domain

    .EXAMPLE

        PS C:\> Get-ObjectAcl -SamAccountName matt.admin -domain testlab.local -ResolveGUIDs
        
        Get the ACLs for the matt.admin user in the testlab.local domain and
        resolve relevant GUIDs to their display names.
#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Full = $False,
        
        [String]
        $SamAccountName,

        [String]
        $Name = "*",

        [Alias('DN')]
        [String]
        $DistinguishedName = "*",

        [String]
        $Filter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        [ValidateSet("All","ResetPassword","WriteMembers")]
        $RightsFilter,

        [String]
        $Domain,

        [String]
        $DomainController,

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200,

        [String]
        $exportCsvFile = "C:\scanACLsResults.csv"
    )

    begin {
        $Searcher = Get-DomainSearcher -Domain $Domain -DomainController $DomainController -ADSpath $ADSpath -ADSprefix $ADSprefix -PageSize $PageSize

        # get a GUID -> name mapping
        $GUIDs = Get-GUIDMap -Domain $Domain -DomainController $DomainController -PageSize $PageSize
    }

    process {

        if ($Searcher) {

            if($SamAccountName) {
                $Searcher.filter="(&(samaccountname=$SamAccountName)(name=$Name)(distinguishedname=$DistinguishedName)$Filter)"  
            }
            else {
                $Searcher.filter="(&(name=$Name)(distinguishedname=$DistinguishedName)$Filter)"  
            }
            try {
                $Searcher.PropertiesToLoad.Clear()
                $Properies = "samaccountname","displayname", "SID", "userprincipalname", "memberof","ObjectClass","objectsid", "objectguid","distinguishedName","name","cn", "dnshostname"
                foreach ($Property in $Properies)
                {
                    $Searcher.PropertiesToLoad.Add($Property) | Out-Null
                }

                $GroupMembersDB = @{}
                $numberObjectsDone = 0
                $counter = -1
                $Searcher.FindAll() | Where-Object {$_} | Foreach-Object {
                    if ($counter -eq -1) {
                        $counter++
                        Write-Host "Got more objects, analyzing.."
                    }
                    $Object = [adsi]($_.path)
                    if($Object.distinguishedname) {
                        $Access = $Object.PsBase.ObjectSecurity.access
                        $Access | ForEach-Object {
                            $_ | Add-Member NoteProperty 'ObjectDN' ($Object.distinguishedname[0])
                            $Objectclass = ''
                            $ObjectclassList = $Object.PsBase.properties.objectclass
                            foreach ($class in $ObjectclassList){   
                                $Objectclass += $class
                                $Objectclass += ' '
                            }
                            $_ | Add-Member NoteProperty 'ObjectClass' ($Objectclass)
                            $_ | Add-Member NoteProperty 'ObjectOwner' ($Object.PsBase.ObjectSecurity.Owner)
                            $GroupMembers = $Null
                            $GroupName = $Object.PsBase.Properties.cn.value

                            if($Object.objectsid[0]){
                                $S = (New-Object System.Security.Principal.SecurityIdentifier($Object.objectsid[0],0)).Value
                            }
                            else {
                                $S = $Null
                            }
                            $_ | Add-Member NoteProperty 'ObjectSID' $S

                            $NameIdentityReference = $_.IdentityReference
                            $NamefromSID = $NameIdentityReference                             
                            if ($_.IdentityReference -match 's-1-'){
                                try {
                                        $NamefromSID = Convert-SidToName $NameIdentityReference
                                    }
                                    catch {$NamefromSID = $NameIdentityReference}
                                }
                            $_ | Add-Member NoteProperty 'UpdatedIdentityReference' ($NamefromSID)
                            
                            #counter for printing counting                        
                            $numberObjectsDone ++
                            $counter++
                            $_
                            }
                        }
                } | ForEach-Object {
                    if($RightsFilter) {
                        $GuidFilter = Switch ($RightsFilter) {
                            "ResetPassword" { "00299570-246d-11d0-a768-00aa006e0529" }
                            "WriteMembers" { "bf9679c0-0de6-11d0-a285-00aa003049e2" }
                            Default { "00000000-0000-0000-0000-000000000000"}
                        }
                        if($_.ObjectType -eq $GuidFilter) { $_ }
                    }
                    else {
                        $_
                    }
                } | Foreach-Object {
                    if($GUIDs) {
                        # if we're resolving GUIDs, map them them to the resolved hash table
                        $AclProperties = @{}
                        $_.psobject.properties | ForEach-Object {
                            if( ($_.Name -eq 'ObjectType') -or ($_.Name -eq 'InheritedObjectType') ) {
                                try {
                                    $AclProperties[$_.Name] = $GUIDS[$_.Value.toString()]
                                }
                                catch {
                                    $AclProperties[$_.Name] = $_.Value
                                }
                            }
                            else {
                                $AclProperties[$_.Name] = $_.Value
                            }
                        }
                        New-Object -TypeName PSObject -Property $AclProperties
                    }
                    else { $_ }
                
                }
            }
            catch {
                Write-Warning $_
            }
        }
    }
}


function Invoke-ACLScanner {
<#
    .SYNOPSIS
        Searches for ACLs for specifable AD objects (default to all domain objects)
        It filtered to the ones who have modifiable rights.

    .PARAMETER SamAccountName

        Object name to filter for.        

    .PARAMETER Name

        Object name to filter for.

    .PARAMETER DistinguishedName

        Object distinguished name to filter for.

    .PARAMETER Filter

        A customized ldap filter string to use, e.g. "(description=*admin*)"
     
    .PARAMETER ADSpath

        The LDAP source to search through, e.g. "LDAP://OU=secret,DC=testlab,DC=local"
        Useful for OU queries.

    .PARAMETER ADSprefix

        Prefix to set for the searcher (like "CN=Sites,CN=Configuration")

    .PARAMETER Domain

        The domain to use for the query, defaults to the current domain.

    .PARAMETER DomainController

        Domain controller to reflect LDAP queries through.

    .PARAMETER PageSize

        The PageSize to set for the LDAP searcher object.

    .EXAMPLE

        PS C:\> Invoke-ACLScanner -ResolveGUIDs | Export-CSV -NoTypeInformation acls.csv

        Enumerate all modifable ACLs in the current domain, resolving GUIDs to display 
        names, and export everything to a .csv
#>

    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$True)]
        [String]
        $Full = $False,
        
        [String]
        $SamAccountName,

        [String]
        $Name = "*",

        [Alias('DN')]
        [String]
        $DistinguishedName = "*",

        [String]
        $Filter,

        #[String]
        #$RightsFilter,

        [String]
        $ADSpath,

        [String]
        $ADSprefix,

        [String]
        $Domain,

        [String]
        $DomainController,
                
        [String]
        $exportCsvFile = "C:\scanACLsResults.csv",

        [ValidateRange(1,10000)] 
        [Int]
        $PageSize = 200
    )
    
    # Get all domain ACLs with the appropriate parameters
    try{
        if ($ADSpath) 
            {write-host "Current path to search: $ADSpath"}

        Get-ObjectACL @PSBoundParameters | ForEach-Object {
            # add in the translated SID for the object identity
            $_ | Add-Member Noteproperty 'IdentitySID' ($_.IdentityReference.Translate([System.Security.Principal.SecurityIdentifier]).Value)
            $_
        } | Where-Object {
            #
            # Important Note - you can:
            #
            # check for any ACLs with SIDs > -1000
            # or change to "(-499)" to include all the users and groups - include the built-in entities
            # or chenge to "(-1)" to include all the users and groups - include the also the general and local groups (like Authenticated Users)
            try {
                [int]($_.IdentitySid.split("-")[-1]) -ge (-1)
            }
            catch {}
        } | Where-Object {
            #
            # Important Note - you can change here the filter and get more interesting results:
            #
            # filter for all modifiable rights and with Allow permissions:
            #($_.ActiveDirectoryRights -eq "GenericAll") -or ($_.ActiveDirectoryRights -match "Write") -or ($_.ActiveDirectoryRights -match "Create") -or ($_.ActiveDirectoryRights -match "Delete") -or (($_.ActiveDirectoryRights -match "ExtendedRight") -and ($_.AccessControlType -eq "Allow"))
            # if you scan non-"user account" objects - filter for modifiable rights with less false-positves of permissions:
            #(($_.ActiveDirectoryRights -eq "GenericAll") -or ($_.ActiveDirectoryRights -match "Write") -or ($_.ActiveDirectoryRights -match "Create") -or ($_.ActiveDirectoryRights -match "Delete") -or (($_.ActiveDirectoryRights -match "ExtendedRight") -and (($_.ObjectType -ne "User-Change-Password") -and ($_.ObjectType -ne "Update-Password-Not-Required-Bit") -and ($_.ObjectType -ne "Unexpire-Password") -and ($_.ObjectType -ne "Enable-Per-User-Reversibly-Encrypted-Password") -and ($_.ObjectType -ne "Send-To")))) -and ($_.AccessControlType -eq "Allow")
            # for more accurate result -  this filter use "black list" approach for the most privileged permissions:
            (($_.ActiveDirectoryRights -eq "GenericAll") -or ($_.ActiveDirectoryRights -match "Write") -or ($_.ActiveDirectoryRights -match "Create") -or ($_.ActiveDirectoryRights -match "Delete") -or (($_.ActiveDirectoryRights -match "ExtendedRight") -and (($_.ObjectType -eq "DS-Replication-Get-Changes") -or ($_.ObjectType -eq "DS-Replication-Get-Changes-All") -or ($_.ObjectType -eq "DS-Replication-Get-Changes-In-Filtered-Set") -or ($_.ObjectType -eq "User-Force-Change-Password")))) -and ($_.AccessControlType -eq "Allow")
            ######         
            # or you can write here your own filters - for example, filter for accounts that have only the GenericAll permission.
            ######

        } | Export-Csv -NoTypeInformation -append $exportCsvFile
    }
    catch{
        Write-Warning "`n$_"
        Write-Warning "Sorry but there was an error during the scanning in one or more objects."
    }
} 
