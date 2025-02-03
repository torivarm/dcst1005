# In this script we will create a file share

$remoteComputerName = "srv1"

# define the directory path
$directoryPath = "C:\shares\installfiles"

# Define the share name
$shareName = "InstallFiles"

# Create a new PowerShell session to the remote server
$session = New-PSSession -ComputerName $remoteComputerName

# Share The folder and set NTFS Permissions
Invoke-Command -Session $session -ScriptBlock {
    param($directoryPath, $shareName)
    # Create the new directory if it does not exist
    If(-not (Test-Path $directoryPath)) {
        New-Item -Path $directoryPath -ItemType Directory
        Write-Host "Directory created at $directoryPath"
    } else {
        Write-Host "Directory already exists at $directoryPath"
    }

    # Share the folder
    New-SmbShare -Name $shareName -Path $directoryPath -FullAccess "Everyone"
    Write-Host "Folder shared as $shareName"
} -ArgumentList $directoryPath, $shareName