<#
Description: This script creates a shared folder and adds it as a folder target to a DFS Namespace folder.
If the shared folder already exists, it will be reused and added as a folder target to the DFS Namespace folder.
If it is already shared, the script will add it as a folder target to the DFS Namespace folder.
#>
# Define the folder name, shared folder path, and share name
$folderName = "installfiles"
$sharedFolderPath = "C:\shares\installfiles"
$shareName = "installfiles" # The share name should match the DFS folder target share name

# Define the DFS Namespace path and the target path for the DFS folder
$dfsNamespace = "\\infrait.sec\files" # Adjust this to your actual DFS Namespace root
$dfsFolderPath = "$dfsNamespace\$folderName"
$targetPath = "\\srv1\$shareName"

# Script block to check if the folder is already shared, create the shared folder, and add it as a DFSN folder target
$scriptBlock = {
    param($folderName, $sharedFolderPath, $shareName, $dfsFolderPath, $targetPath)

    # Check if the shared folder already exists
    $existingShare = Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue

    # Create the directory if it does not exist
    if (-not (Test-Path -Path $sharedFolderPath)) {
        New-Item -ItemType Directory -Path $sharedFolderPath
    }

    # Share the directory if it is not already shared
    if ($null -eq $existingShare) {
        New-SmbShare -Name $shareName -Path $sharedFolderPath -FullAccess 'Everyone'
        Write-Host "Folder shared as $shareName."
    } else {
        Write-Host "Folder is already shared as $shareName."
    }

    # Check if the DFS folder target already exists
    $existingDfsTarget = Get-DfsnFolderTarget -Path $dfsFolderPath -ErrorAction SilentlyContinue

    # Add the folder target to DFS Namespace if it does not exist
    if ($existingDfsTarget -eq $null) {
        New-DfsnFolder -Path $dfsFolderPath -TargetPath $targetPath -ErrorAction SilentlyContinue
        New-DfsnFolderTarget -Path $dfsFolderPath -TargetPath $targetPath
        Write-Host "DFS folder target added for $shareName."
    } else {
        Write-Host "DFS folder target for $shareName already exists."
    }
}

# Execute the script block on the remote server srv1 with the defined parameters
Invoke-Command -ComputerName srv1 -ScriptBlock $scriptBlock -ArgumentList $folderName, $sharedFolderPath, $shareName, $dfsFolderPath, $targetPath
