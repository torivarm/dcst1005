# Create Resource Group for VMs with a function

# Define the prefix for the resource group and resources
$prefix = 'demo'
# Resource group:
$resourceGroupName = $prefix + '-rg-vm-001'
$location = 'uksouth'

function New-ResourceGroup {
    param (
        [string]$resourceGroupName,
        [string]$location
    )

    # Check if the Resource Group already exists
    $resourceGroup = Get-AzResourceGroup -Name $resourceGroupName -ErrorAction SilentlyContinue

    if (-not $resourceGroup) {
        # Resource Group does not exist, so create it
        New-AzResourceGroup -Name $resourceGroupName -Location $location -ErrorAction Stop
        Write-Output "Created Resource Group: $resourceGroupName in $location"
    } else {
        Write-Output "Resource Group $resourceGroupName already exists."
    }
}


# Create the resource group, if it does not exist
New-ResourceGroup -resourceGroupName $resourceGroupName -location $location