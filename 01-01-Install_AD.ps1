# THIS SCRIPT MUST BE RUN AS ADMINISTRATOR ON DC1
# variable containing the computer name
$env:COMPUTERNAME
# If you want to change the computer name, you can use the Rename-Computer cmdlet
$newcompname = Read-host "Skriv inn ønsket hostname på maskinen"
Rename-Computer -Newname $newcompname -Restart -Force

# Check what features are installed
Get-WindowsFeature | Where-Object {$_. installstate -eq "installed"}


# Install Active Directory Domain Services (AD DS)
# Needs to be run as Administrator
Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
$Password = Read-Host -Prompt 'Enter Password' -AsSecureString
Set-LocalUser -Password $Password Administrator

$Params = @{
    DomainMode = 'WinThreshold'
    DomainName = 'core.sec'
    DomainNetbiosName = 'core'
    ForestMode = 'WinThreshold'
    InstallDns = $true
    NoRebootOnCompletion = $true
    SafeModeAdministratorPassword = $Password
    Force = $true
}

# Install AD DS with the parameters defined above
Install-ADDSForest @Params
Restart-Computer
# Log in as Administrator@YourDomanName.whatever with password from above
# Test our domain
Get-ADRootDSE
# The Get-ADRootDSE cmdlet gets the object that represents the root of the directory information tree of a directory server. 
# This tree provides information about the configuration and capabilities of the directory server, 
# such as the distinguished name for the configuration container, the current time on the directory server, 
# and the functional levels of the directory server and the domain.
#
Get-ADForest
# The Get-ADForest cmdlet gets the Active Directory forest specified by the parameters.
Get-ADDomain
# The Get-ADDomain cmdlet gets the Active Directory domain specified by the parameters.
# Any computers joined the domain?
Get-ADComputer -Filter * | Select-Object DNSHostName