
$departments = @("hr","sales","consultant","it","finance")
foreach ($department in $departments) {
    $departmentUsers = Get-ADUser -Filter "Department -eq '$department'" -Properties Department | 
                        Select-Object samAccountName, Name, Department
    
    foreach ($user in $departmentUsers) {
        Add-ADGroupMember -Identity "g_$department" -Members $user.samAccountName
    }


}

