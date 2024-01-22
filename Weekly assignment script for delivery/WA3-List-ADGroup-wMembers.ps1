# Edit this variables to match your environment
$OU = "InfraIT_Groups"

# Retrieve the OU's distinguished name
$ouPath = Get-ADOrganizationalUnit -Filter * | where-Object {$_.name -eq "$OU"}


# Retrieve all groups from the specified OU
$groups = Get-ADGroup -Filter * -SearchBase $ouPath.DistinguishedName 

# Iterate through each group and list its members
foreach ($group in $groups) {
    Write-Host "Group: $($group.Name)"
    Write-Host "Members:"
    
    # Retrieve members of the group
    $members = Get-ADGroupMember -Identity $group -Recursive | Select-Object Name
    
    # List each member
    foreach ($member in $members) {
        Write-Host " - $($member.Name)"
    }
    Write-Host "" # Adds a blank line for readability
}

