# In this scrip we will add the created shared folder for installfiles to the dfsnamespace infrait\files on SRV1

# Define the remote computer name
$remoteComputerName = "srv1"

# Define the share name
$shareName = "InstallFiles"

# Define the folderName
$folderName = "installfiles"

# Define the ShareFolderPath
$ShareFolderPath = "C:\shares\$folderName"

# Define the DFSNamespace
$DFSNamespace = "InfraIT\Files"

$dfsfolder = "\\$remoteComputerName\$shareName"

# DFS Target Path
$DFSTargetPath = "\\$remoteComputerName\$shareName"

# Create a new PowerShell session to the remote server
$session = New-PSSession -ComputerName $remoteComputerName

# Add the folder to the DFS Namespace and add new dfsn folder target
Invoke-Command -Session $session -ScriptBlock {
    param($DFSNamespace, $folderName, $DFSTargetPath)
    # Add the folder to the DFS Namespace
    New-DfsnFolder -Path "$DFSNamespace\$folderName" -TargetPath $DFSTargetPath -ErrorAction SilentlyContinue
    New-DfsnFoldertarget -Path "$DFSNamespace\$folderName" -TargetPath $DFSTargetPath -ErrorAction SilentlyContinue
    Write-Host "Folder added to DFS Namespace"
} -ArgumentList $DFSNamespace, $folderName, $DFSTargetPath