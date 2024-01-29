# Change ACL for HR Share (make sure do the same for all shares)

$acl = Get-acl -Path "\\infrait.sec\files\HR-Share"
$acl.access
$AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("l_FileShareHR_FullControll","FullControl","Allow")
$acl.SetAccessRule($AccessRule)
$acl | Set-Acl -Path "\\infrait.sec\files\HR-Share"

$acl = Get-acl -Path "\\infrait.sec\files\HR-Share"
$acl.access

# Change inheritance for HR Share (make sure do the same for all shares)

$ACL = Get-Acl -Path "\\infrait.sec\files\HR-Share"
$ACL.SetAccessRuleProtection($true,$true)
$ACL | Set-Acl -Path "\\infrait.sec\files\HR-Share"

<#
$true: Enable ACL protection, which means the folder will no longer inherit permissions from its parent.
$true: Preserve inherited permissions by converting them into explicit permissions on this object.
#>

# Remove BUILTIN\Users from ACL for HR Share (make sure do the same for all shares)
$acl = Get-Acl "\\infrait.sec\files\HR-Share"
    $acl.Access | Where-Object {$_.IdentityReference -eq "BUILTIN\Users" } | ForEach-Object { $acl.RemoveAccessRuleSpecific($_) }
    Set-Acl "\\infrait.sec\files\HR-Share" $acl
    (Get-ACL -Path "\\infrait.sec\files\HR-Share").Access | 
        Format-Table IdentityReference,FileSystemRights,AccessControlType,IsInherited,InheritanceFlags -AutoSize




