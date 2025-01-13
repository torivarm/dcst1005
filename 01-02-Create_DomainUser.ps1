# THIS SCRIPT MUST BE RUN AS ADMINISTRATOR ON DC1

# Define new user parameters
$username = "NewAdminUser" # Change this to the desired username
$Password = Read-Host -Prompt 'Enter Password' -AsSecureString
$userPrincipalName = $username + "@" # Change to your domain
$displayName = "" # Change this to the desired display name
$description = "" # Change this to a suitable description
$path = "CN=Users,DC=<yourDomainName>,DC=<yourDomainNameEnding>" # Change the path to the appropriate path in your AD structure
# My path in the video CN=Users,DC=InfraIT,DC=sec (CN stands for Common Name, and DC stands for Domain Component)
# Users is a container in the root of the domain and not a OU (Organizational Unit)

# Create the new user
New-ADUser -Name $displayName `
            -GivenName $username `
            -UserPrincipalName $userPrincipalName `
            -SamAccountName $username `
            -AccountPassword $password `
            -DisplayName $displayName `
            -Description $description `
            -Path $path `
            -Enabled $true

# Add the new user to the Domain Admins group
Add-ADGroupMember -Identity "Domain Admins" -Members $username

Write-Host "User $username created and added to Domain Admins group."