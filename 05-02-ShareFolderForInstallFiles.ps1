# Define the computer name for the remote session
$remoteComputerName = "srv1"

# Define the directory to be shared
$directoryPath = "C:\shares\installfiles"

# Define the share name
$shareName = "InstallFiles"

# Create a new PowerShell session to the remote computer
$session = New-PSSession -ComputerName $remoteComputerName

# Share the folder and set NTFS permissions
Invoke-Command -Session $session -ScriptBlock {
    param($directoryPath, $shareName)
    
    # Share the folder on the network with read access for Everyone
    New-SmbShare -Name $shareName -Path $directoryPath -ReadAccess 'Everyone'
    
    <# Set NTFS permission to read-only for Everyone
    # Get the ACL of the directory
    $acl = Get-Acl $directoryPath
    # Create a new FileSystemAccessRule
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Everyone", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
    # Add the FileSystemAccessRule to the ACL
    $acl.SetAccessRule($accessRule)
    # Set the modified ACL back to the directory
    Set-Acl -Path $directoryPath -AclObject $acl
    #>
    Write-Output "Folder shared with read access for Everyone."
} -ArgumentList $directoryPath, $shareName

# Close the PowerShell session
Remove-PSSession -Session $session
