# THIS SCRIPT TAKES ONLY HR AS AN EXAMPLE 
# MAKE SURE TO CONFIGURE ALL DEPARTMENTS SHARED FOLDERS

# Define the shared folders (names used in 04-02-installDFSNamespace.ps1)
# Define the path to the HR-Share folder
$folderPath = "C:\shares\HR" # Update this path to the actual path of your HR-Share folder

# Define the domain groups
$readGroupName = "DOMAIN\l_FileShareHR_Read" # Replace DOMAIN with your actual domain name
$writeGroupName = "DOMAIN\l_FileShareHR_Write" # Replace DOMAIN with your actual domain name

# Get the current ACL of the folder
$acl = Get-Acl $folderPath

# Define Read and Write permissions
$readPermission = "ReadAndExecute, Synchronize"
$writePermission = "Modify, Synchronize"

# Create Access Rule for the Read group
$readAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($readGroupName, $readPermission, "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.SetAccessRule($readAccessRule)

# Create Access Rule for the Write group
$writeAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($writeGroupName, $writePermission, "ContainerInherit, ObjectInherit", "None", "Allow")
$acl.SetAccessRule($writeAccessRule)

# Set the new ACL on the folder
Set-Acl $folderPath $acl
