Invoke-Command -ComputerName srv1 -ScriptBlock {
    $folders = @('HR', 'IT', 'Sales', 'Finance', 'Consultants')
    foreach ($folder in $folders) {
        Write-Host "`nPermissions for $folder folder:" -ForegroundColor Yellow
        (Get-Acl -Path "C:\shares\$folder").Access | Format-Table IdentityReference,FileSystemRights
    }

    Write-Host "`nPermissions for DFS root:" -ForegroundColor Yellow
    (Get-Acl -Path "C:\dfsroots\files").Access | Format-Table IdentityReference,FileSystemRights
}