# Variables
#$tenantID = "bd0944c8-c04e-466a-9729-d7086d13a653" # Remember to change this to your own TenantID
#$subscrptionID = "41082359-57d6-4427-b5d9-21e269157652" # Remember to change this to your own SubscriptionID

# Connect to Azure
#Connect-AzAccount -Tenant $tenantID -Subscription $subscrptionID

# Variables - REMEMBER to change $prefix to your own prefix
$prefix = 'demo'
# Resource group:
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'

# Create Resource Group for the VNETs with a function
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