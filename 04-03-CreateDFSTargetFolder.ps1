##########################################################
# MAKE SURE TO CHANGE HARD CODED SERVER NAMES TO VARIABLES
##########################################################

# Define the shared folders (names used in 04-02-installDFSNamespace.ps1)
$SharedFolders = @("FilesShare", "HR-Share", "Consultant-Share", "Finance-Share", "IT-Share", "Sales-Share", "Shared-Share")

# Script block to be executed on the remote server
Invoke-Command -ComputerName srv1 -ScriptBlock {
    param([string[]]$SharedFolders)
    foreach ($Share in $SharedFolders) {
        # Define the DFS folder path
        $DfsFolderPath = "\\infrait.sec\files\$Share"
        Write-Host $DfsFolderPath -ForegroundColor Green

        # Define the target path (UNC path to the shared folder)
        $TargetPath = "\\srv1\$Share"
        Write-Host $TargetPath -ForegroundColor Green

        # Add the target to the DFS folder
        New-DfsnFolderTarget -Path $DfsFolderPath -TargetPath $TargetPath
    }
} -ArgumentList (,$SharedFolders)


