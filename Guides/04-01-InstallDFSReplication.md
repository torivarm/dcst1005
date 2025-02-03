# Remote DFS Replication Installation Guide for DC1

## Prerequisites
Before starting the remote installation, ensure:
- DC1 is domain-joined
- Administrative privileges on DC1
- PowerShell remoting enabled on DC1
- WinRM configured for remote management
- Sufficient disk space on DC1 for replicated data
- Stable network connection to DC1

## Enable PowerShell Remoting (if not enabled)
```powershell
# Test connection to DC1
Test-WSMan -ComputerName "DC1"

# If not enabled, enable remotely using psexec or locally on DC1:
Enable-PSRemoting -Force
```
[Test-WSMan](https://learn.microsoft.com/en-us/powershell/module/microsoft.wsman.management/test-wsman) - Tests if WS-Management is configured and running on DC1.

## Installation Steps

### 1. Establish Remote Session
```powershell
$session = New-PSSession -ComputerName "DC1"
```
[New-PSSession](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/new-pssession) - Creates a persistent remote session to DC1 for running commands.

### 2. Install DFS Replication Role
```powershell
Invoke-Command -Session $session -ScriptBlock {
    Install-WindowsFeature FS-DFS-Replication -IncludeManagementTools
}
```
[Install-WindowsFeature](https://learn.microsoft.com/en-us/powershell/module/servermanager/install-windowsfeature) - Remotely installs the DFS Replication role and management tools on DC1.

### 3. Install DFS Namespaces
```powershell
Invoke-Command -Session $session -ScriptBlock {
    Install-WindowsFeature FS-DFS-Namespace -IncludeManagementTools
}
```

## Basic Configuration Steps

### 1. Create a Replication Group
```powershell
New-DfsReplicationGroup -GroupName "DC1RepGroup" -Description "DC1 Replication Group" -DomainName "domain.local"
```
[New-DfsReplicationGroup](https://learn.microsoft.com/en-us/powershell/module/dfsr/new-dfsreplicationgroup) - Creates a new replication group for DC1.

### 2. Add DC1 as Replication Member
```powershell
Add-DfsrMember -GroupName "DC1RepGroup" -ComputerName "DC1"
```
[Add-DfsrMember](https://learn.microsoft.com/en-us/powershell/module/dfsr/add-dfsrmember) - Adds DC1 to the replication group.

### 3. Create Replication Folder on DC1
```powershell
Invoke-Command -Session $session -ScriptBlock {
    # Create the directory if it doesn't exist
    New-Item -Path "D:\SharedData" -ItemType Directory -Force
}

New-DfsReplicatedFolder -GroupName "DC1RepGroup" -FolderName "Share1" -ContentPath "D:\SharedData"
```
[New-DfsReplicatedFolder](https://learn.microsoft.com/en-us/powershell/module/dfsr/new-dfsreplicatedfolder) - Creates a replicated folder on DC1.

### 4. Set DC1 as Primary Member
```powershell
Set-DfsrMembership -GroupName "DC1RepGroup" -FolderName "Share1" -ContentPath "D:\SharedData" -ComputerName "DC1" -PrimaryMember $true
```
[Set-DfsrMembership](https://learn.microsoft.com/en-us/powershell/module/dfsr/set-dfsrmembership) - Configures DC1 as the primary member.

## Remote Verification Commands

### Check Replication Status on DC1
```powershell
Invoke-Command -ComputerName "DC1" -ScriptBlock {
    Get-DfsrState -GroupName "DC1RepGroup" -FolderName "Share1"
}
```
[Get-DfsrState](https://learn.microsoft.com/en-us/powershell/module/dfsr/get-dfsrstate) - Shows the current replication state on DC1.

### View DC1 Replication Configuration
```powershell
Get-DfsReplicationGroup | Where-Object {$_.Members -contains "DC1"} | Format-List *
```
[Get-DfsReplicationGroup](https://learn.microsoft.com/en-us/powershell/module/dfsr/get-dfsreplicationgroup) - Shows detailed information about DC1's replication groups.

## Maintenance Commands for DC1

### Update DC1 Configuration
```powershell
Update-DfsrConfigurationFromAD -ComputerName "DC1"
```
[Update-DfsrConfigurationFromAD](https://learn.microsoft.com/en-us/powershell/module/dfsr/update-dfsrconfigurationfromad) - Forces a refresh of DFS Replication configuration from AD on DC1.

### Force Immediate Sync on DC1
```powershell
Sync-DfsReplicationGroup -GroupName "DC1RepGroup"
```
[Sync-DfsReplicationGroup](https://learn.microsoft.com/en-us/powershell/module/dfsr/sync-dfsreplicationgroup) - Initiates immediate replication for DC1's group.

## Troubleshooting DC1

### Check DC1 Health Report
```powershell
Get-DfsrHealthReport -GroupName "DC1RepGroup" -ComputerName "DC1"
```
[Get-DfsrHealthReport](https://learn.microsoft.com/en-us/powershell/module/dfsr/get-dfsrhealthreport) - Generates a health report for DC1's replication.

### Create Detailed HTML Report for DC1
```powershell
Write-DfsrHealthReport -GroupName "DC1RepGroup" -Path "\\DC1\C$\DFSReport.html"
```
[Write-DfsrHealthReport](https://learn.microsoft.com/en-us/powershell/module/dfsr/write-dfsrhealthreport) - Creates a detailed HTML report of DC1's DFS Replication health.

### Clean Up Remote Session
```powershell
Remove-PSSession $session
```
[Remove-PSSession](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/remove-pssession) - Closes the remote session to DC1.

## Best Practices for DC1
1. Verify WinRM configuration before starting
2. Monitor DC1's disk space regularly
3. Check DC1's event logs for replication errors
4. Document all configuration changes made to DC1
5. Keep track of DC1's replication partners
6. Maintain proper backup of DC1's replicated data

## Note
- Ensure proper network connectivity to DC1 before starting
- Verify DNS resolution for DC1
- Check firewall rules for remote management
- Monitor DC1's resource usage during initial sync
- Consider using robocopy for initial data seeding on DC1