# Define the computer name for the remote session
$remoteComputerName = "srv1"

# Create a new PowerShell session to the remote computer
$session = New-PSSession -ComputerName $remoteComputerName

# Define the directory to be created on the remote computer
$newDirectory = "C:\shares\installfiles"

# Create the new directory on the remote computer
Invoke-Command -Session $session -ScriptBlock {
    param($newDirectory)
    
    # Check if the directory already exists
    if(-not (Test-Path $newDirectory)) {
        # Create the directory if it does not exist
        New-Item -ItemType Directory -Path $newDirectory
        Write-Output "Directory created: $newDirectory"
    } else {
        Write-Output "Directory already exists: $newDirectory"
    }
} -ArgumentList $newDirectory

# Close the PowerShell session
Remove-PSSession -Session $session
