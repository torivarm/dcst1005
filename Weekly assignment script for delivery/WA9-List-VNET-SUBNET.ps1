# Define the prefix for virtual networks (e.g., "mycompany-vnet")
$prefix = Read-Host "Enter the prefix for virtual networks"

# Authenticate to Azure (you can modify this part based on your authentication method)
# Connect-AzAccount

# Get all virtual networks with the specified prefix
$vnetList = Get-AzVirtualNetwork | Where-Object { $_.Name -like "$prefix*" }

# Loop through each virtual network
foreach ($vnet in $vnetList) {
    Write-Host "Virtual Network: $($vnet.Name)" -ForegroundColor Green
    Write-Host "    Address Space: $($vnet.AddressSpace.AddressPrefixes)" -ForegroundColor Green
    
    # Get all subnets within the virtual network
    $subnets = $vnet.Subnets
    
    # Print subnet details
    foreach ($subnet in $subnets) {
        Write-Host "  Subnet: $($subnet.Name)" -ForegroundColor Yellow
        Write-Host "    Address Prefix: $($subnet.AddressPrefix)" -ForegroundColor Yellow
        ""
    }
}

# Disconnect from Azure (optional)
# Disconnect-AzAccount 