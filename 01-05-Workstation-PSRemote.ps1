# THIS SCRIPT MUST BE RUN AS ADMINISTRATOR ON VM'S WITH WINDOWS 10/11 IF PSREMOTE DONT WORK
winrm set winrm/config/service/auth '@{Kerberos="true"}' 
# List auth: 
winrm get winrm/config/service/auth
# Enable PSRemote: Enable-PSRemoting -Force
Enable-PSRemoting -Force
