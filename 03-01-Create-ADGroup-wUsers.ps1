# Root folder for the project
$rootFolder = "C:\git-projects\dcst1005\dcst1005\"

# CSV-file with users
$groups = Import-Csv -Path "$rootFolder\03-01-global-groups-example.csv" -Delimiter ","

# Initialize arrays to store the results
$groupsCreated = @()
$groupsNotCreated = @()
$groupExists = @()

# Create global groups
foreach ($group in $groups) {
    $group = "g_" + $group.group
    $existingGroup = Get-ADGroup -Filter "Name -eq '$group'"
    # Conditional statement used to check if the variable $existingGroup has a value that is considered 'true'
    if ($existingGroup) {
        Write-Host "Group $group already exists" -ForegroundColor Red
        $groupExists += $group
    }
        else {
            try {
                Write-Host "Creating group $group" -ForegroundColor Green
                New-ADGroup -Name $group -GroupScope Global -GroupCategory Security
                $groupsCreated += $group
            }
            catch {
                Write-Host "Failed to create group $group" -ForegroundColor Red
                $groupsNotCreated += $group
            }
        }
}


# Export the results to CSV files
$groupsCreated | Export-Csv "$rootFolder\groups_created.csv" -NoTypeInformation -Encoding utf8
$groupsNotCreated | Export-Csv "$rootFolder\groups_not_created.csv" -NoTypeInformation -Encoding utf8
$groupExists | Export-Csv "$rootFolder\groups_exists.csv" -NoTypeInformation -Encoding utf8

Write-Host "Export complete. Groups created: $($groupsCreated.Count). `
            Groups not created: $($groupsNotCreated.Count). `
            Groups already exists $($groupExists.Count)" -ForegroundColor Green
