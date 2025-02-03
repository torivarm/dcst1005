# DFS Namespace and Replication Setup Guide for \\infrait\files

## Prerequisites
Before starting, ensure:
- Windows Server 2016 or later on DC1 and SRV1
- Both servers are domain-joined
- Administrative privileges on both servers
- PowerShell remoting enabled
- Existing shares on SRV1 for:
  - Finance
  - Sales
  - IT
  - Consultants
  - HR

## Install DFS Services on DC1

### 1. Establish Remote Session to DC1
```powershell
$session = New-PSSession -ComputerName "DC1"
```
[New-PSSession](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-pssession) - Creates a remote session to DC1.

### 2. Install DFS Services
```powershell
Invoke-Command -Session $session -ScriptBlock {
    Install-WindowsFeature FS-DFS-Namespace, FS-DFS-Replication -IncludeManagementTools
}
```
[Install-WindowsFeature](https://learn.microsoft.com/en-us/powershell/module/servermanager/install-windowsfeature) - Installs both DFS Namespace and Replication roles.

## Create Folders on DC1

### 1. Create Base Directory Structure
```powershell
Invoke-Command -Session $session -ScriptBlock {
    $basePath = "D:\DFSRoots"
    $folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
    
    # Create base directory
    New-Item -Path $basePath -ItemType Directory -Force

    # Create individual folders
    foreach ($folder in $folders) {
        New-Item -Path "$basePath\$folder" -ItemType Directory -Force
        
    }
}
```

### 2. Share Folders on DC1
```powershell
Invoke-Command -Session $session -ScriptBlock {
    $folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
    foreach ($folder in $folders) {
        New-SmbShare -Name $folder -Path "D:\DFSRoots\$folder" -FullAccess "Everyone"
        # Adjust share permissions according to your security requirements
    }
}
```
[New-SmbShare](https://learn.microsoft.com/en-us/powershell/module/smbshare/new-smbshare) - Creates network shares for the folders.

## Configure DFS Namespace

### 1. Create DFS Namespace
```powershell
New-DfsnRoot -TargetPath "\\DC1\files" -Type DomainV2 -Path "\\infrait\files"
```
[New-DfsnRoot](https://learn.microsoft.com/en-us/powershell/module/dfsn/new-dfsnroot) - Creates the DFS namespace root.

### 2. Add Folders to Namespace
```powershell
$folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
foreach ($folder in $folders) {
    # Add namespace folder
    New-DfsnFolder -Path "\\infrait\files\$folder" -TargetPath "\\SRV1\$folder"
    # Add DC1 as additional target
    New-DfsnFolderTarget -Path "\\infrait\files\$folder" -TargetPath "\\DC1\$folder"
}
```
[New-DfsnFolder](https://learn.microsoft.com/en-us/powershell/module/dfsn/new-dfsnfolder) - Creates folders in the namespace.
[New-DfsnFolderTarget](https://learn.microsoft.com/en-us/powershell/module/dfsn/new-dfsntarget) - Adds targets to namespace folders.

## Configure DFS Replication

### 1. Create Replication Group
```powershell
New-DfsReplicationGroup -GroupName "InfraIT_Files" -Description "InfraIT Files Replication"
```
[New-DfsReplicationGroup](https://learn.microsoft.com/en-us/powershell/module/dfsr/new-dfsreplicationgroup) - Creates a new replication group.

### 2. Add Members to Replication Group
```powershell
Add-DfsrMember -GroupName "InfraIT_Files" -ComputerName "SRV1","DC1"
```
[Add-DfsrMember](https://learn.microsoft.com/en-us/powershell/module/dfsr/add-dfsrmember) - Adds both servers to the replication group.

### 3. Create Replicated Folders
```powershell
$folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
foreach ($folder in $folders) {
    # Create replicated folder
    New-DfsReplicatedFolder -GroupName "InfraIT_Files" -FolderName $folder -DfsnPath "\\infrait\files\$folder"
    
    # Configure SRV1 as primary member (source)
    Set-DfsrMembership -GroupName "InfraIT_Files" -FolderName $folder `
        -ComputerName "SRV1" -ContentPath "D:\Shares\$folder" -PrimaryMember $true
    
    # Configure DC1 as secondary member (destination)
    Set-DfsrMembership -GroupName "InfraIT_Files" -FolderName $folder `
        -ComputerName "DC1" -ContentPath "D:\DFSRoots\$folder"
}
```
[New-DfsReplicatedFolder](https://learn.microsoft.com/en-us/powershell/module/dfsr/new-dfsreplicatedfolder) - Creates replicated folders.
[Set-DfsrMembership](https://learn.microsoft.com/en-us/powershell/module/dfsr/set-dfsrmembership) - Configures replication membership.

## Verification and Monitoring

### 1. Check Replication Status
```powershell
foreach ($folder in $folders) {
    Get-DfsrBacklog -GroupName "InfraIT_Files" -FolderName $folder `
        -SourceComputerName "SRV1" -DestinationComputerName "DC1"
}
```
[Get-DfsrBacklog](https://learn.microsoft.com/en-us/powershell/module/dfsr/get-dfsrbacklog) - Shows pending replication items.

### 2. Monitor Health
```powershell
# Generate health report
Write-DfsrHealthReport -GroupName "InfraIT_Files" -Path "C:\DFSReport.html"

# Check replication status
Get-DfsrState -GroupName "InfraIT_Files" -ComputerName "DC1"
```

### 3. Force Replication
```powershell
Sync-DfsReplicationGroup -GroupName "InfraIT_Files"
```
[Sync-DfsReplicationGroup](https://learn.microsoft.com/en-us/powershell/module/dfsr/sync-dfsreplicationgroup) - Forces immediate replication.

## Cleanup
```powershell
Remove-PSSession $session
```

## Best Practices
1. Monitor initial replication progress closely
2. Verify NTFS permissions are correctly set on both servers
3. Check event logs for replication errors
4. Monitor disk space on both servers
5. Document namespace and replication configuration
6. Regular health checks using DFS Management console

## Note
- Adjust paths and permissions according to your environment
- Initial replication might take time depending on data volume
- Configure appropriate staging quota based on file sizes
- Consider bandwidth between servers for replication timing