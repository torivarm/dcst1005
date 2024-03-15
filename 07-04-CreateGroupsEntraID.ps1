# Title: Create security groups in Microsoft Entra Identity
# Created: 2024-03-15
# This scrip creates security groups in Microsoft Entra Identity based on a CSV-file with group names
#
# The script uses the Microsoft Graph PowerShell SDK to create the groups
# The script also checks if the groups already exists
# The script uses the New-MgGroup and Get-MgGroup cmdlets
#
# Micorosoft Learn: Groups
# New-MgGroup - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.groups/new-mggroup?view=graph-powershell-1.0
# Get-MgGroup - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.groups/get-mggroup?view=graph-powershell-1.0
#
#

$TenantID = "bd0944c8-c04e-466a-9729-d7086d13a653" # Remember to change this to your own TenantID
Connect-MgGraph -TenantId $TenantID -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory"

# Get the current session details
$Details = Get-MgContext
$Scopes = $Details | Select-Object -ExpandProperty Scopes
$Scopes = $Scopes -join ","
$OrgName = (Get-MgOrganization).DisplayName
""
""
"Microsoft Graph current session details:"
"---------------------------------------"
"Tenant Id = $($Details.TenantId)"
"Client Id = $($Details.ClientId)"
"Org name  = $OrgName"
"App Name  = $($Details.AppName)"
"Account   = $($Details.Account)"
"Scopes    = $Scopes"
"---------------------------------------"




# Root folder for the project
$rootFolder = "/Users/melling/git-projects/dcst1005"
$csvfile = "07-00-CSV-groups.csv"

# Variables for groups created and not created
$groupsCreated = @()
$groupsNotCreated = @()
$groupsExists = @()

# Group prefix / suffix
$prefix = "s_" # s_ for security groups, m_ for Microsoft 365 groups etc.
$suffix = "_group"


# Import the CSV-file with users
$groups = Import-Csv -Path "$rootFolder/$csvfile" -Delimiter "," # Remember to put the / \ in the path (depending on OS)

foreach ($group in $groups) {
    $group = $prefix + $group.groups + $suffix
    $existingGroup = Get-MgGroup -Filter "displayName eq '$group'"
    if ($existingGroup) {
        Write-Host "Group $group already exists" -ForegroundColor Red
        $groupsExists += $group
    }
    else {
        try {
            Write-Host "Creating group $group" -ForegroundColor Green
            New-MgGroup -DisplayName $group -MailEnabled:$false -MailNickname $group -SecurityEnabled:$true
            $groupsCreated += $group
        }
        catch {
            Write-Host "Failed to create group $group" -ForegroundColor Red
            $groupsNotCreated += $group
        }
    }
}


# Convert the array of strings to an array of objects with a 'GroupName' property
$groupsCreatedObjects = $groupsCreated | ForEach-Object { [PSCustomObject]@{GroupName = $_} }
$groupsNotCreatedObjects = $groupsNotCreated | ForEach-Object { [PSCustomObject]@{GroupName = $_} }
$groupsExistsObjects = $groupsExists | ForEach-Object { [PSCustomObject]@{GroupName = $_} }

# Export the results to CSV files
$groupsCreatedObjects | Export-Csv -Path "$rootFolder/groups_created.csv" -NoTypeInformation -Encoding UTF8
$groupsNotCreatedObjects | Export-Csv -Path "$rootFolder/groups_not_created.csv" -NoTypeInformation -Encoding UTF8
$groupsExistsObjects | Export-Csv -Path "$rootFolder/groups_exists.csv" -NoTypeInformation -Encoding UTF8
