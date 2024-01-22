# Root folder for the project
$rootFolder = "C:\git-projects\dcst1005\dcst1005\"

# CSV-file with users
$users = Import-Csv -Path "$rootFolder\02-03-tmp_csv-users-example.csv" -Delimiter ","

foreach ($user in $users) {
    # Retrieve the user's department
    $department = $user.Department

    # Determine the AD group based on the department
    # This is an example. Modify it according to your group naming convention and departments
    $groupName = "g_" + $department

    try {
        # Get the AD user object
        $adUser = Get-ADUser -Identity $user.Username -ErrorAction Stop

        # Add the user to the group
        Add-ADGroupMember -Identity $groupName -Members $adUser -ErrorAction Stop

        Write-Host "Added user $($adUser.SamAccountName) to group $groupName."
    } catch {
        Write-Host "Error adding user $($user.Username) to group $groupName."
    }
}

Write-Host "Process completed."