# Azure Management Group Creation Script
# This script creates a hierarchical management group structure for InfraIT
# Run this script in Azure Cloud Shell (PowerShell)

# Ensure the AZ module is installed and you're logged in
# If not already logged in, run: Connect-AzAccount

# Define Management Group structure
$rootMg = @{
    Id = "mg-infrait-sec"
    DisplayName = "MG InfraIT SEC"
    ParentId = $null  # Root level
}

$level1Mgs = @(
    @{
        Id = "mg-infrait-trondheim"
        DisplayName = "MG InfraIT Trondheim"
        ParentId = "mg-infrait-sec"
    },
    @{
        Id = "mg-infrait-oslo"
        DisplayName = "MG InfraIT Oslo"
        ParentId = "mg-infrait-sec"
    }
)

$level2Mgs = @(
    # Trondheim departments
    @{
        Id = "mg-infrait-trondheim-hr"
        DisplayName = "MG InfraIT Trondheim HR"
        ParentId = "mg-infrait-trondheim"
    },
    @{
        Id = "mg-infrait-trondheim-development"
        DisplayName = "MG InfraIT Trondheim Development"
        ParentId = "mg-infrait-trondheim"
    },
    @{
        Id = "mg-infrait-trondheim-it"
        DisplayName = "MG InfraIT Trondheim IT"
        ParentId = "mg-infrait-trondheim"
    },
    
    # Oslo departments
    @{
        Id = "mg-infrait-oslo-sales"
        DisplayName = "MG InfraIT Oslo Sales"
        ParentId = "mg-infrait-oslo"
    },
    @{
        Id = "mg-infrait-oslo-finance"
        DisplayName = "MG InfraIT Oslo Finance"
        ParentId = "mg-infrait-oslo"
    }
)

$level3Mgs = @(
    # Trondheim HR environments
    @{
        Id = "mg-infrait-trondheim-hr-prod-tim"
        DisplayName = "MG InfraIT Trondheim HR Prod TIM"
        ParentId = "mg-infrait-trondheim-hr"
    },
    @{
        Id = "mg-infrait-trondheim-hr-dev-tim"
        DisplayName = "MG InfraIT Trondheim HR Dev TIM"
        ParentId = "mg-infrait-trondheim-hr"
    },
    
    # Trondheim Development environments
    @{
        Id = "mg-infrait-trondheim-development-prod-tim"
        DisplayName = "MG InfraIT Trondheim Development Prod TIM"
        ParentId = "mg-infrait-trondheim-development"
    },
    @{
        Id = "mg-infrait-trondheim-development-dev-tim"
        DisplayName = "MG InfraIT Trondheim Development Dev TIM"
        ParentId = "mg-infrait-trondheim-development"
    },
    
    # Trondheim IT environments
    @{
        Id = "mg-infrait-trondheim-it-prod-tim"
        DisplayName = "MG InfraIT Trondheim IT Prod TIM"
        ParentId = "mg-infrait-trondheim-it"
    },
    @{
        Id = "mg-infrait-trondheim-it-dev-tim"
        DisplayName = "MG InfraIT Trondheim IT Dev TIM"
        ParentId = "mg-infrait-trondheim-it"
    },
    
    # Oslo Sales environments
    @{
        Id = "mg-infrait-oslo-sales-prod-tim"
        DisplayName = "MG InfraIT Oslo Sales Prod TIM"
        ParentId = "mg-infrait-oslo-sales"
    },
    @{
        Id = "mg-infrait-oslo-sales-dev-tim"
        DisplayName = "MG InfraIT Oslo Sales Dev TIM"
        ParentId = "mg-infrait-oslo-sales"
    },
    
    # Oslo Finance environments
    @{
        Id = "mg-infrait-oslo-finance-prod-tim"
        DisplayName = "MG InfraIT Oslo Finance Prod TIM"
        ParentId = "mg-infrait-oslo-finance"
    },
    @{
        Id = "mg-infrait-oslo-finance-dev-tim"
        DisplayName = "MG InfraIT Oslo Finance Dev TIM"
        ParentId = "mg-infrait-oslo-finance"
    }
)

# Function to create management groups
function Create-MgHierarchy {
    param (
        [Parameter(Mandatory=$true)]
        [array]$ManagementGroups
    )
    
    foreach ($mg in $ManagementGroups) {
        # Check if management group exists
        $existingMg = Get-AzManagementGroup -GroupId $mg.Id -ErrorAction SilentlyContinue
        
        if ($null -eq $existingMg) {
            Write-Host "Creating management group: $($mg.DisplayName) ($($mg.Id))" -ForegroundColor Green
            
            # Create new management group
            if ($null -eq $mg.ParentId) {
                # Root level management group
                New-AzManagementGroup -GroupId $mg.Id -DisplayName $mg.DisplayName
            }
            else {
                # Child management group with parent - use full resource ID format
                $parentResourceId = "/providers/Microsoft.Management/managementGroups/$($mg.ParentId)"
                New-AzManagementGroup -GroupId $mg.Id -DisplayName $mg.DisplayName -ParentId $parentResourceId
            }
        }
        else {
            Write-Host "Management group already exists: $($mg.DisplayName) ($($mg.Id))" -ForegroundColor Yellow
            
            # Update display name if needed
            if ($existingMg.DisplayName -ne $mg.DisplayName) {
                Write-Host "Updating display name for: $($mg.Id)" -ForegroundColor Cyan
                Update-AzManagementGroup -GroupId $mg.Id -DisplayName $mg.DisplayName
            }
            
            # Update parent if needed and if not root
            if ($null -ne $mg.ParentId) {
                $parentResourceId = "/providers/Microsoft.Management/managementGroups/$($mg.ParentId)"
                $existingParentId = $existingMg.ParentId
                if ($existingParentId -ne $parentResourceId) {
                    Write-Host "Updating parent for: $($mg.Id)" -ForegroundColor Cyan
                    Update-AzManagementGroup -GroupId $mg.Id -ParentId $parentResourceId
                }
            }
        }
    }
}

# Main execution
try {
    # Check if user is logged in
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "You are not logged in to Azure. Please run Connect-AzAccount first." -ForegroundColor Red
        exit
    }
    
    Write-Host "Starting Management Group creation process..." -ForegroundColor Cyan
    
    # Create hierarchy level by level to ensure parent groups exist first
    Write-Host "Creating Root Management Group..." -ForegroundColor Cyan
    Create-MgHierarchy -ManagementGroups @($rootMg)
    
    Write-Host "Creating Level 1 Management Groups..." -ForegroundColor Cyan
    Create-MgHierarchy -ManagementGroups $level1Mgs
    
    Write-Host "Creating Level 2 Management Groups..." -ForegroundColor Cyan
    Create-MgHierarchy -ManagementGroups $level2Mgs
    
    Write-Host "Creating Level 3 Management Groups..." -ForegroundColor Cyan
    Create-MgHierarchy -ManagementGroups $level3Mgs
    
    Write-Host "Management Group hierarchy creation completed successfully!" -ForegroundColor Green
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace
}