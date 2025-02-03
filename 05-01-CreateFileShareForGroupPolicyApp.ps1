# In this script we will create a file share on the remote server to store the installation files.

$remoteComputerName = "srv1"

# Create a new POwerShell Session to the remote server
$session = New-PSSession -ComputerName $remoteComputerName

# Define the directory to create on the remote server
$newDirectory = "C:\shares\installfiles"

# Create the new directory on the remote server
Invoke-Command -Session $session -ScriptBlock {
    param($newDirectory)
    If(-not (Test-Path $newDirectory)) {
        # Create the new directory if it does not exist
        New-Item -Path $newDirectory -ItemType Directory
        Write-Host "Directory created at $newDirectory"
    } else {
        Write-Host "Directory already exists at $newDirectory"
    }
} -ArgumentList $newDirectory

# Close the PowerShell session
Remove-PSSession -Session $session