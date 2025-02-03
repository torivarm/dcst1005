# DFS Replication Configuration Guide with PowerShell

## Prerequisites
First, verify that the required PowerShell module is installed on your management PC:

```powershell
# Check if DFSN module is installed
Get-Module -ListAvailable -Name DFSN

# Check if DFSR module is installed
Get-Module -ListAvailable -Name DFSR

# If not installed, install the modules (requires admin privileges)
Add-WindowsFeature -Name RSAT-DFS-Mgmt-Con
```

## Environment Overview

### Source Server (SRV1)
- DFS Namespace installed
- Namespace configured: \\infrait\files
- Shared folders:
  - c:\shares\finance
  - c:\shares\sales
  - c:\shares\hr
  - c:\shares\it
  - c:\shares\consultants

### Destination Server (DC1)
- DFS Replication installed
- Target folders:
  - c:\dfsroots\consultants
  - c:\dfsroots\finance
  - c:\dfsroots\hr
  - c:\dfsroots\it
  - c:\dfsroots\sales

## Configuration Steps

### 1. Create Replication Group

```powershell
# Create a new replication group
New-DfsReplicationGroup -GroupName "FileServerGroup" -Description "Replication between SRV1 and DC1"
```

### 2. Add Replication Group Members

```powershell
# Add both servers to the replication group
Add-DfsrMember -GroupName "FileServerGroup" -ComputerName "SRV1"
Add-DfsrMember -GroupName "FileServerGroup" -ComputerName "DC1"
```

### 3. Create Replication Folders

```powershell
# Create replication folders for each shared directory
$folders = @("finance", "sales", "hr", "it", "consultants")

foreach ($folder in $folders) {
    Add-DfsrFolderMember -GroupName "FileServerGroup" `
        -FolderName $folder `
        -ContentPath "c:\shares\$folder" `
        -ComputerName "SRV1" `
        -PrimaryMember $true

    Add-DfsrFolderMember -GroupName "FileServerGroup" `
        -FolderName $folder `
        -ContentPath "c:\dfsroots\$folder" `
        -ComputerName "DC1"
}
```

### 4. Configure Replication Connections

```powershell
# Set up bidirectional replication between servers
Add-DfsrConnection -GroupName "FileServerGroup" `
    -SourceComputerName "SRV1" `
    -DestinationComputerName "DC1"
```

### 5. Verify Configuration

```powershell
# Check replication group status
Get-DfsReplicationGroup -GroupName "FileServerGroup" | Format-List

# Check connection status
Get-DfsrConnection -GroupName "FileServerGroup"

# Check folder configuration
Get-DfsReplicatedFolder -GroupName "FileServerGroup"
```

## Monitoring and Maintenance

### Check Replication Status

```powershell
# View replication backlog
Get-DfsrBacklog -GroupName "FileServerGroup" `
    -SourceComputerName "SRV1" `
    -DestinationComputerName "DC1" `
    -FolderName "finance"

# Check replication health
Write-DfsrHealth -SourceComputerName "SRV1" -DestinationComputerName "DC1"
```

### Common Troubleshooting Commands

```powershell
# Reset replication if needed
Update-DfsrConfigurationFromAD -ComputerName "SRV1"
Update-DfsrConfigurationFromAD -ComputerName "DC1"

# Check DFS service status
Get-Service DFSR -ComputerName "SRV1"
Get-Service DFSR -ComputerName "DC1"
```

## Important Notes

1. Ensure both servers have adequate disk space for replication.
2. Monitor initial replication progress as it may take time depending on data volume.
3. Check event logs (Event Viewer > Applications and Services Logs > DFS Replication) for detailed status.
4. Consider bandwidth usage and schedule replication during off-peak hours if necessary.

## Additional Resources

- Use `Get-Help` for detailed information about DFS PowerShell cmdlets
  ```powershell
  Get-Help *dfsr*
  Get-Help Add-DfsrConnection -Detailed
  ```