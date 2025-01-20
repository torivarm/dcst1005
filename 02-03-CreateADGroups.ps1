function New-CustomADGroup {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Path,
        [ValidateSet("Global", "Universal", "DomainLocal")]
        [string]$Scope = "Global",
        [ValidateSet("Security", "Distribution")]
        [string]$Category = "Security",
        [string]$Description
    )
    
    try {
        # Check if group exists
        $existingGroup = Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($null -eq $existingGroup) {
            # Create new group
            $params = @{
                Name = $Name
                GroupScope = $Scope
                GroupCategory = $Category
                Path = $Path
            }
            
            if ($Description) {
                $params.Add("Description", $Description)
            }
            
            New-ADGroup @params
            Write-Host "Successfully created group: $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Group already exists: $Name" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "Failed to create group: $Name" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Define groups to create
$groups = @(
    @{
        Name = "FinatTest1"
        Path = "CN=Users,DC=InfraIT,DC=sec"
        Scope = "Global"
        Category = "Security"
    },
    @{
        Name = "FinalTest2"
        Path = "CN=Users,DC=InfraIT,DC=sec"
        Scope = "Global"
        Category = "Security"
    }
)

# Create groups and add members
foreach ($group in $groups) {
    if (New-CustomADGroup -Name $group.Name -Path $group.Path -Scope $group.Scope -Category $group.Category) {
        if ($group.Members) {
            # Add-CustomADGroupMember -GroupName $group.Name -Members $group.Members
        }
    }
}

# Example of removing members
# Remove-CustomADGroupMember -GroupName "IT Support" -Members @("John.Doe")

# Example of adding new members
# Add-CustomADGroupMember -GroupName "HR Team" -Members @("New.Employee")

