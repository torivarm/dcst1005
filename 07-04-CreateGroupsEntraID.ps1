$TenantID = "bd0944c8-c04e-466a-9729-d7086d13a653" # Remember to change this to your own TenantID
Connect-MgGraph -TenantId $TenantID -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory"
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

#
# Micorosoft Learn: Groups
# New-MgGroup - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.groups/new-mggroup?view=graph-powershell-1.0
# Get-MgGroup - https://learn.microsoft.com/en-us/powershell/module/microsoft.graph.groups/get-mggroup?view=graph-powershell-1.0
#

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
            New-MgGroup -DisplayName $group -MailEnabled $false -MailNickname $group -SecurityEnabled $true
            $groupsCreated += $group
        }
        catch {
            Write-Host "Failed to create group $group" -ForegroundColor Red
            $groupsNotCreated += $group
        }
    }
}
