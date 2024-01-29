# SCRIPT TO INSTALL DFS NAMESPACE

# Install DFS Namespace on srv1
Invoke-Command -ComputerName srv1 -ScriptBlock {
    Install-WindowsFeature -Name FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con -IncludeManagementTools
}


# Create folders on srv1

# NB When you pass an array as an argument to a script block in Invoke-Command, 
# it is treated as a single argument, not as an array. 
# This can lead to unexpected behavior in the script block, particularly in how the foreach loop is processed.
# To avoid this, you can use the unary comma operator (,) to force the array to be treated as a collection of arguments.
$departments = @("HR", "Consultant", "Finance", "IT", "Sales", "Shared")

Invoke-Command -ComputerName srv1 -ScriptBlock {
    param([string[]]$departments)
    $dfsRootsPath = New-Item -Path "c:\" -Name 'dfsroots' -ItemType "directory" -Force
    $filesFolderPath = New-Item -Path "$dfsRootsPath\files" -ItemType "directory" -Force
    New-SMBShare -Name "FilesShare" -Path $filesFolderPath.FullName -FullAccess "Everyone"
    
    $sharesPath = New-Item -Path "c:\" -Name 'shares' -ItemType "directory" -Force
    foreach ($dept in $departments) {
        $folderPath = New-Item -Path "$sharesPath\$dept" -ItemType "directory" -Force
        $shareName = "$dept-Share"
        New-SMBShare -Name $shareName -Path $folderPath.FullName -FullAccess "Everyone"
    }
} -ArgumentList (,$departments)


# Create DFS namespace Root - IT WILL FAIL!! 
# New-DfsnRoot: A general error occurred that is not covered by a more specific error code.
# Must be run localy on srv1 i PowerShell 7.x som administrator and NOT through Invoke-Command
<#
Invoke-Command -ComputerName srv1 -ScriptBlock {
    New-DfsnRoot -Path "\\infrait.sec\files" -TargetPath "\\srv1\FilesShare" -Type DomainV2
}
#>

<#
Copy from PowerShell windows on Srv1:
PS C:\Users\melling> New-DfsnRoot -Path "\\infrait.sec\files" -TargetPath "\\srv1\FilesShare" -Type DomainV2

Path                Type      Properties TimeToLiveSec State  Description
----                ----      ---------- ------------- -----  -----------
\\infrait.sec\files Domain V2            300           Online

PS C:\Users\melling>

#>








