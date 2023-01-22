# Subnet identifier for ping sweep
$subnet = "172.16.2" # Change this
 
# Host IP to start ping sweep
$start = 1
 
# Host IP to finish ping sweep
$end = 254
 
# Number of times to attempt each ping
$ping = 1
 
# Path and filename for results file
Write-Host "LiveHost.txt will be in C:\Windows\Temp\"
$OutPath ="C:\Windows\Temp\LiveHost.txt"
 
While ($start -le $end) {
$IP = "$subnet.$start"
$Test = Test-Connection -ComputerName $IP -count $ping -Quiet
Write-Host "$IP,$Test"
Add-Content -LiteralPath $OutPath -Value "$IP,$Test"
$start++
}
