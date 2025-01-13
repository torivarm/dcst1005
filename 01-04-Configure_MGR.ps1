################################################################################
# MAKE SURE YOUR ARE LOGED IN AS A YOUR DOMAIN ADMIN USER - NOT ADMINISTRATOR :D
################################################################################


# Installere Choco 
# Hva er Choco: https://chocolatey.org/
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco upgrade chocolatey
# Installere programvare med Choco
choco install -y powershell-core
choco install -y git.install
choco install -y vscode
#choco install -y sysinternals

# Konfigurer Git
git config --global user.name "NAVN"
git config --global user.email "EPOST@EPOST.EPOST"
#

# Check if computer is domain joined (CIM (Common Information Model))
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -Property Name, Domain, PartOfDomain

# Remote Server Administrative Tools (RSAT)
# Installere RSAT - RSAT is a tool that allows you to manage roles and features in Windows Server remotely from a Windows 10/11 machine.
Add-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools -Online