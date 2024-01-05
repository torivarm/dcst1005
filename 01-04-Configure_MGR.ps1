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