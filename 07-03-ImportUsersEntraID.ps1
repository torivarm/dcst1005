$TenantID = "bd0944c8-c04e-466a-9729-d7086d13a653"
Connect-MgGraph -TenantId $TenantID -Scopes "User.ReadWrite.All", "Group.ReadWrite.All", "Directory.ReadWrite.All", "RoleManagement.ReadWrite.Directory"


$users = Import-CSV -Path '/Users/melling/git-projects/dcst1005/07-00-CSV-Users.csv' -Delimiter ","

$PasswordProfile = @{
    Password = 'DemoPassword12345!'
    }
foreach ($user in $users) {
    $Params = @{
        UserPrincipalName = $user.userPrincipalName + "@digsec.onmicrosoft.com"
        DisplayName = $user.displayName
        GivenName = $user.GivenName
        Surname = $user.Surname
        MailNickname = $user.userPrincipalName
        AccountEnabled = $true
        PasswordProfile = $PasswordProfile
        Department = $user.Department
        CompanyName = "InfraIT Sec"
        Country = "Norway"
        City = "Trondheim"
    }
    $Params
    New-MgUser @Params
}
