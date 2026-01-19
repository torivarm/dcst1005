try {
    
    $department = "finance"
    $groupName = "g_all_$department"

    $users = Get-ADUser -Filter "Department -eq '$department'" -ErrorAction Stop
    
    if ($users) {
        foreach ($user in $users) {
            Add-ADGroupMember -Identity $groupName -Members $user -ErrorAction Stop
            Write-Host "Added $($user.Name) to $groupName"
        }
    } else {
        Write-Warning "No users found in department: $department"
    }
} catch {
    Write-Error "Error: $_"
}