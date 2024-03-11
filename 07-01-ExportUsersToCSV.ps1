# Define the path to the CSV file where the user data will be saved
$csvFilePath = ""

# Define the LDAP path to the specific OU from which to retrieve users
# Replace 'OU=TestOU,DC=example,DC=com' with the actual path to your OU
$ouPath = "OU=,DC=infrait,DC=sec"

# Retrieve all user objects from the specified OU and select the desired properties
Get-ADUser -Filter * -SearchBase $ouPath -Properties surName, givenName, displayName, userPrincipalName, companyName, department |
    Select-Object surName, givenName, displayName, userPrincipalName, companyName, department |
    Export-Csv -Path $csvFilePath -NoTypeInformation

# Output a completion message
Write-Output "Export completed. The user data has been saved to $csvFilePath"
