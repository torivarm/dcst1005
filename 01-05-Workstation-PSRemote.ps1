# TEST PSREMOTE: Connect-PSRemoting -ComputerName FROM MGR TO WORKSTATIONS/SERVERS IN DOMAIN
Enter-PSSession -ComputerName dc1
Enter-PSSession -ComputerName srv1
Enter-PSSession -ComputerName cl1

# Install PowerShell 7.x on remote machine.
# Enable-PSRemoting -Force <- This command must be run as administrator on remote machine if PSRemote dont work.
$session = New-PSSession -ComputerName dc1 -ConfigurationName PowerShell.7
Copy-Item -Path "C:\install\PowerShell-7.4.0-win-x64.msi" -Destination "C:\install" -ToSession $session
Invoke-Command -Session $session -ScriptBlock {
    Start-Process "msiexec.exe" -ArgumentList "/i C:\install\PowerShell-7.4.0-win-x64.msi /quiet /norestart" -Wait
}
Invoke-Command -Session $session -ScriptBlock { $PSVersionTable }


# IF PSREMOTE DONT WORK, THIS COMMANDS MUST BE RUN AS ADMINISTRATOR ON VM'S WITH WINDOWS 10/11 
# Enable PSRemote: Enable-PSRemoting -Force
Enable-PSRemoting -Force
winrm set winrm/config/service/auth '@{Kerberos="true"}' 
# List auth: 
winrm get winrm/config/service/auth

