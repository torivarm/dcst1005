# Define the CSV file path to export the data
$csvFilePath = "C:\git-projects\dcst1005\dcst1005\"

# Initialize an array to hold the output data
$outputDataServices = @()
$outputDataShares = @()
$outputDataNTFS = @()

# List DFS Replication service on DC1
$dfsReplicationService = Invoke-Command -ComputerName dc1 -ScriptBlock { Get-Service -Name DFSR }
$outputDataServices += [PSCustomObject]@{
    ComputerName = "dc1"
    ServiceName = $dfsReplicationService.DisplayName
    Status = $dfsReplicationService.Status
}

# List DFS Namespace service on SRV1
$dfsNamespaceService = Invoke-Command -ComputerName srv1 -ScriptBlock { Get-Service -Name DFS }
$outputDataServices += [PSCustomObject]@{
    ComputerName = "srv1"
    ServiceName = $dfsNamespaceService.DisplayName
    Status = $dfsNamespaceService.Status
}

# List SRV1 shared folders and share rights
$sharedFolders = Get-SmbShare -CimSession "srv1" | Where-Object { $_.Name -notlike "ADMIN$" -and $_.Name -notlike "C$" -and $_.Name -notlike "IPC$" }
foreach ($folder in $sharedFolders) {
    $shareName = $folder.Name
    $sharePermissions = Get-SmbShareAccess -Name $folder.Name -CimSession "srv1"
    
    foreach ($permission in $sharePermissions) {
        $outputDataShares += [PSCustomObject]@{
            ComputerName = "srv1"
            ShareName = $shareName
            AccountName = $permission.AccountName
            AccessRight = $permission.AccessRight
        }
    }
}

# List SRV1 shared folders NTFS rights
foreach ($folder in $sharedFolders) {
    $ntfsRights = (Get-Acl -Path "\\srv1\$($folder.Name)").Access | ForEach-Object {
        "$($_.FileSystemRights) by $($_.IdentityReference)"
    }

    $outputDataNTFS += [PSCustomObject]@{
        ComputerName = "srv1"
        FolderName = $folder.Name
        NTFSRights = $ntfsRights -join "; "
    }
}

# Export the data to a CSV file
$outputDataServices | Export-Csv -Path "$csvFilePath RunningServices.csv" -NoTypeInformation
$outputDataShares | Export-Csv -Path "$csvFilePath SharedFolders" -NoTypeInformation
$outputDataNTFS | Export-Csv -Path "$csvFilePath NTFSRights" -NoTypeInformation
