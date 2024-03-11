# Define the path to the CSV file where the user data will be saved
$csvFilePath = "C:\git-projects\dcst1005\dcst1005\07-00-CSV-Users.csv"

# Define the LDAP path to the specific OU from which to retrieve users
# get-adorganizationalUnit -Filter * | where-Object {$_.name -like "*users*"} | ft name, distinguishedName
$ouPath = "OU=InfraIT_Users,DC=InfraIT,DC=sec"

# Retrieve all user objects from the specified OU
$users = Get-ADUser -Filter * -SearchBase $ouPath -Properties surName, givenName, displayName, userPrincipalName, company, department, sAMAccountName

# Prepare a list to hold user information with group memberships
$userList = @()

foreach ($user in $users) {
    # Retrieve groups for the current user
    $groups = Get-ADPrincipalGroupMembership -Identity $user | Select-Object -ExpandProperty Name

    # Create a semi-colon separated string of group names
    $groupString = $groups -join ';'

    # Add user information and group memberships to the list
    $userList += [PSCustomObject]@{
        surName        = $user.surName
        givenName      = $user.givenName
        displayName    = $user.displayName
        userPrincipalName = $user.userPrincipalName
        company        = $user.company
        department     = $user.department
        userLogonName  = $user.sAMAccountName
        groups         = $groupString
    }
}

# Export the user list to a CSV file
$userList | Export-Csv -Path $csvFilePath -NoTypeInformation

# Output a completion message
Write-Output "Export completed. The user data has been saved to $csvFilePath"
