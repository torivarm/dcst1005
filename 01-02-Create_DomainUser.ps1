# THIS SCRIPT MUST BE RUN AS ADMINISTRATOR ON DC1

# Define new user parameters
$username = "NewAdminUser" # Change this to the desired username
$Password = Read-Host -Prompt 'Enter Password' -AsSecureString
$userPrincipalName = $username + "@" # Change to your domain
$displayName = "" # Change this to the desired display name
$description = "" # Change this to a suitable description
$path = "OU=,DC=,DC=" # Change the path to the appropriate OU in your AD structure

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