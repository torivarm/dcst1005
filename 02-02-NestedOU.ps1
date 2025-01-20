# Define the OU structure using a hashtable
$ouStructure = @{
    "IT" = @(
        "Hardware",
        "Software",
        "Network",
        "Support"
    )
    "HR" = @(
        "Recruitment",
        "Training",
        "Benefits",
        "Employee Records"
    )
    "Finance" = @(
        "Accounting",
        "Payroll",
        "Budgeting",
        "Reporting"
    )
}

$domainPath = "DC=InfraIT,DC=sec"

# Function to create an OU with error handling
function New-CustomADOU {
    param (
        [string]$Name,
        [string]$Path,
        [switch]$DisableProtection
    )
    
    try {
        # Check if OU exists
        $existingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -ErrorAction SilentlyContinue
        
        if (-not $existingOU) {
            # Create new OU
            $params = @{
                Name = $Name
                Path = $Path
                ProtectedFromAccidentalDeletion = -not $DisableProtection
            }
            
            New-ADOrganizationalUnit @params
            Write-Host "Successfully created OU: $Name in $Path" -ForegroundColor Green
            return $true
        } else {
            Write-Host "OU already exists: $Name in $Path" -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Host "Failed to create OU: $Name" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Function to remove an OU with error handling
function Remove-CustomADOU {
    param (
        [string]$Identity
    )
    
    try {
        # Check if OU exists
        $ou = Get-ADOrganizationalUnit -Identity $Identity -ErrorAction SilentlyContinue
        
        if ($ou) {
            # Disable protection
            Set-ADOrganizationalUnit -Identity $Identity -ProtectedFromAccidentalDeletion $false
            
            # Remove OU
            Remove-ADOrganizationalUnit -Identity $Identity -Confirm:$false
            Write-Host "Successfully removed OU: $Identity" -ForegroundColor Green
            return $true
        } else {
            Write-Host "OU does not exist: $Identity" -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Host "Failed to remove OU: $Identity" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Create all OUs
foreach ($parentOU in $ouStructure.Keys) {
    # Create parent OU
    $parentPath = $domainPath
    $parentCreated = New-CustomADOU -Name $parentOU -Path $parentPath
    
    if ($parentCreated) {
        # Create child OUs
        foreach ($childOU in $ouStructure[$parentOU]) {
            $childPath = "OU=$parentOU,$domainPath"
            New-CustomADOU -Name $childOU -Path $childPath
        }
    }
}

# Example of how to remove the entire structure
function Remove-OUStructure {
    param (
        [hashtable]$Structure,
        [string]$DomainPath
    )
    
    # Remove child OUs first
    foreach ($parentOU in $Structure.Keys) {
        foreach ($childOU in $Structure[$parentOU]) {
            $childPath = "OU=$childOU,OU=$parentOU,$DomainPath"
            Remove-CustomADOU -Identity $childPath
        }
        
        # Then remove parent OU
        $parentPath = "OU=$parentOU,$DomainPath"
        Remove-CustomADOU -Identity $parentPath
    }
}

# Example usage to remove the structure:
# Remove-OUStructure -Structure $ouStructure -DomainPath $domainPath