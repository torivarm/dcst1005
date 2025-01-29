# Function to check if remote computer is accessible
function Test-RemoteComputer {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ComputerName
    )
    
    try {
        $result = Test-Connection -ComputerName $ComputerName -Count 1 -Quiet
        return $result
    }
    catch {
        Write-Host "Error testing connection to $ComputerName : $_" -ForegroundColor Red
        return $false
    }
}

# Function to get and format NTFS permissions
function Get-FolderPermissions {
    param (
        [Parameter(Mandatory=$true)]
        [string]$FolderPath,
        [string]$FolderName = (Split-Path $FolderPath -Leaf)
    )

    try {
        # Check if folder exists
        if (-not (Test-Path -Path $FolderPath)) {
            Write-Host "Folder not found: $FolderPath" -ForegroundColor Red
            return $null
        }

        # Get ACL information
        $acl = Get-Acl -Path $FolderPath
        
        Write-Host "`nPermissions for $FolderName folder:" -ForegroundColor Green
        Write-Host "Path: $FolderPath" -ForegroundColor Cyan
        
        # Get inherited/explicit permissions status
        $inheritanceEnabled = $acl.AreAccessRulesProtected
        Write-Host "Inheritance Enabled: $(-not $inheritanceEnabled)" -ForegroundColor Yellow
        
        # Create custom objects for better formatting
        $permissions = $acl.Access | ForEach-Object {
            [PSCustomObject]@{
                'Identity' = $_.IdentityReference
                'Rights' = $_.FileSystemRights
                'Type' = $_.AccessControlType
                'Inherited' = $_.IsInherited
                'InheritanceFlags' = $_.InheritanceFlags
                'PropagationFlags' = $_.PropagationFlags
            }
        }

        # Display permissions in a formatted table
        $permissions | Format-Table -AutoSize

        return $permissions
    }
    catch {
        Write-Host "Error getting permissions for $FolderPath : $_" -ForegroundColor Red
        return $null
    }
}

# Function to export permissions to CSV
function Export-FolderPermissions {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Permissions,
        [Parameter(Mandatory=$true)]
        [string]$FolderName,
        [string]$OutputPath = ".\FolderPermissions"
    )

    try {
        # Create output directory if it doesn't exist
        if (-not (Test-Path -Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath | Out-Null
        }

        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $outputFile = Join-Path $OutputPath "$($FolderName)_Permissions_$timestamp.csv"
        
        $Permissions | Export-Csv -Path $outputFile -NoTypeInformation
        Write-Host "Permissions exported to: $outputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error exporting permissions to CSV: $_" -ForegroundColor Red
    }
}

# Main script block for remote execution #
# !!!! MAKE SURE TO UPDATE THE FOLDER NAME AND PATHS IF THEY ARE DIFFERENT ON YOUR SERVER (srv1) !!!! #
$remoteScriptBlock = {
    param($OutputPath)

    # Configuration
    $folders = @('HR', 'IT', 'Sales', 'Finance', 'Consultants')
    $basePath = "C:\shares"
    $dfsRootPath = "C:\dfsroots\files"
    
    # Store all permissions for export
    $allPermissions = @{}

    # Check shared folders
    foreach ($folder in $folders) {
        $folderPath = Join-Path $basePath $folder
        $permissions = Get-FolderPermissions -FolderPath $folderPath -FolderName $folder
        
        if ($permissions) {
            $allPermissions[$folder] = $permissions
            Export-FolderPermissions -Permissions $permissions -FolderName $folder -OutputPath $OutputPath
        }
    }

    # Check DFS root
    if (Test-Path $dfsRootPath) {
        Write-Host "`nChecking DFS root permissions:" -ForegroundColor Yellow
        $dfsPermissions = Get-FolderPermissions -FolderPath $dfsRootPath -FolderName "DFSRoot"
        
        if ($dfsPermissions) {
            $allPermissions["DFSRoot"] = $dfsPermissions
            Export-FolderPermissions -Permissions $dfsPermissions -FolderName "DFSRoot" -OutputPath $OutputPath
        }
    }
    else {
        Write-Host "DFS root path not found: $dfsRootPath" -ForegroundColor Red
    }

    return $allPermissions
}

# Main execution
$serverName = "srv1"
$outputPath = "\\$serverName\SharedLogs\FolderPermissions"

# Test connection to server
if (Test-RemoteComputer -ComputerName $serverName) {
    try {
        # Create output directory if it doesn't exist
        if (-not (Test-Path -Path $outputPath)) {
            New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
        }

        Write-Host "Starting permission check on $serverName..." -ForegroundColor Cyan
        
        # Execute remote script
        $results = Invoke-Command -ComputerName $serverName -ScriptBlock $remoteScriptBlock -ArgumentList $outputPath
        
        # Generate summary report
        $summaryFile = Join-Path $outputPath "PermissionsSummary_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        
        "Folder Permissions Summary" | Out-File $summaryFile
        "Generated on: $(Get-Date)" | Out-File $summaryFile -Append
        "Server: $serverName" | Out-File $summaryFile -Append
        
        foreach ($folder in $results.Keys) {
            "`n=== $folder Folder ===" | Out-File $summaryFile -Append
            $results[$folder] | Format-Table | Out-File $summaryFile -Append
        }
        
        Write-Host "`nPermission check completed. Summary saved to: $summaryFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error executing remote script: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "Unable to connect to server $serverName. Please check if the server is accessible." -ForegroundColor Red
}