# DFS Namespace and Replication Setup Guide for \\infrait\files

## Prerequisites
Before starting, ensure:
- Servers are domain-joined
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
    $basePath = "C:\DFSRoots"
    $folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
    
    # Create base directory
    New-Item -Path $basePath -ItemType Directory -Force

    # Create individual folders
    foreach ($folder in $folders) {
        New-Item -Path "$basePath\$folder" -ItemType Directory -Force
        
    }
}
```

### 2. Share Folders on DC1 (OPTIONAL)
```powershell
Invoke-Command -Session $session -ScriptBlock {
    $folders = @('Finance', 'Sales', 'IT', 'Consultants', 'HR')
    foreach ($folder in $folders) {
        New-SmbShare -Name $folder -Path "C:\DFSRoots\$folder" -FullAccess "Everyone"
        # Adjust share permissions according to your security requirements
    }
}
```
[New-SmbShare](https://learn.microsoft.com/en-us/powershell/module/smbshare/new-smbshare) - Creates network shares for the folders.

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