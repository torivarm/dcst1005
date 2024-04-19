# Retrieve all virtual networks within the current subscription context
# Get's all VNET based on a name prefix variable $prefix
$prefix = 'tim'
$vnetList = Get-AzVirtualNetwork | Where-Object { $_.Name -like "$prefix*" }

# Check if we found any VNETs, if not, exit
if (-not $vnetList) {
    Write-Host "No Virtual Networks found in the current subscription."
    exit
}

# Iterate over each VNET
foreach ($vnet in $vnetList) {
    Write-Host "VNET Name: $($vnet.Name)"
    Write-Host "Resource Group: $($vnet.ResourceGroupName)"
    Write-Host "Location: $($vnet.Location)"
    Write-Host "Subnets:"

    # Check if the VNET has any subnets
    if ($vnet.Subnets.Count -gt 0) {
        # Iterate over each subnet in the current VNET
        foreach ($subnet in $vnet.Subnets) {
            Write-Host "`tSubnet Name: $($subnet.Name)"
            Write-Host "`tAddress Prefix: $($subnet.AddressPrefix)"
        }
    } else {
        Write-Host "`tNo subnets found."
    }

    # Add a blank line for better readability
    Write-Host ""
}