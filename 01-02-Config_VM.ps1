# THIS SCRIPT MUST BE RUN AS ADMINISTRATOR ON SRV1, CLI1 and MGR
# VM's for the lab needs DC1 IP-address as DNS server (must be done on VM's: SRV1, CLI1 and MGR)
# Why? Because the DNS server is the only one that knows about the domain
$ipaddressdc1 = "192.168.x.x" # IP-address of DC1
Get-NetAdapter | Set-DnsClientServerAddress -ServerAddresses $ipaddressdc1

# Check if configuration is correct
# Find DNS Servers . . . . . . . . . . . : IP.ADR.TIL.DC (192.168.x.x)
ipconfig /all

# Add the computer to the domain
$domainName = "DomainName.whatever"

$cred = Get-Credential -UserName "Administrator@$domainName" -Message 'Provide credentials for the domain Administrator'
Add-Computer -Credential $cred -DomainName $domainName -PassThru -Verbose
Restart-Computer

# NB! NB! When restarted, the computer will be joined to the domain, and you can log in with a domain admin or user account
