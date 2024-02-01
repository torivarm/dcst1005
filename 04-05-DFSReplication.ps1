# Install DFS Replication and create folders for replication on DC1
Install-WindowsFeature -name FS-DFS-Replication -IncludeManagementTools -ComputerName dc1

$departments = @("HR", "Consultant", "Finance", "IT", "Sales", "Shared")

Invoke-Command -ComputerName dc1 -ScriptBlock {
    param([string[]]$departments)
    $dfsReplicationRootFolder = New-Item -Path "c:\" -Name 'dfsreplication' -ItemType "directory" -Force
    foreach ($dept in $departments) {
        $folderPath = New-Item -Path "$dfsReplicationRootFolder\$dept" -ItemType "directory" -Force
    }
} -ArgumentList (,$departments)