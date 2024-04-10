# Description: This script will deploy a hub VPN gateway in Azure
# Parameters:
#   - resourceGroupName: The name of the resource group to deploy the VPN gateway
#   - hubvnet: The name of the hub virtual network
#   - hubsubnet: The name of the hub subnet
#   - hubgateway: The name of the hub gateway



$prefix = 'tim'
# Resource group:
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'




# Hub VNET already exists and created in the previous script for WA9
$hubvnet = $prefix + '-vnet-hub-shared-uk'
$gatewaySubnetAddressPrefix = '10.10.1.0/27'



# Get the hub VNET
try {
    $vnet = Get-AzVirtualNetwork -Name $hubvnet -ResourceGroupName $resourceGroupName -ErrorAction Stop
    Write-Output "Hub VNET $hubvnet exists"
} catch {
    ritWe-Error "Hub VNET $hubvnet does not exist. Creates the VNET first."
    Write-Host "Run the 01-CreateVNET-and-subnet.ps1 in WA9 script to create the VNET."
    exit
}




# Check if the Gateway Subnet already exists and create it if it does not
# GatewaySubnet must be named 'GatewaySubnet'
# https://learn.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-vpn-faq
$gatewaySubnet = $vnet.Subnets | Where-Object { $_.Name -eq 'GatewaySubnet' }
if (-not $gatewaySubnet) {
    $gatewaySubnet = Add-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -AddressPrefix $gatewaySubnetAddressPrefix -VirtualNetwork $vnet -ErrorAction Stop
    $vnet | Set-AzVirtualNetwork -ErrorAction Stop
    Write-Output "Added GatewaySubnet to $hubvnet"
} else {
    Write-Output "GatewaySubnet already exists in $hubvnet."
}


# Create the public IP address for the VPN gateway
$publicIPName = $prefix + '-pip-vpngw-001'
$gwpip = New-AzPublicIpAddress -Name $publicIPName -ResourceGroupName $resourceGroupName -Location $location -AllocationMethod Static

# Create the IP configuration for the VPN gateway
$vnet = Get-AzVirtualNetwork -Name $hubvnet -ResourceGroupName $resourceGroupName
$gwsubnet = Get-AzVirtualNetworkSubnetConfig -Name 'GatewaySubnet' -VirtualNetwork $vnet
$gwipconfig = New-AzVirtualNetworkGatewayIpConfig -Name gwipconfig1 -SubnetId $gwsubnet.Id -PublicIpAddressId $gwpip.Id

# Create the VPN gateway - NOTE! Takes about 45 minutes to create
$gwname = $prefix + '-gw-vpngw-001'
New-AzVirtualNetworkGateway -Name $gwname -ResourceGroupName $resourceGroupName -Location $location -IpConfigurations $gwipconfig -GatewayType Vpn -VpnType RouteBased -EnableBgp $false -GatewaySku VpnGw2 -VpnGatewayGeneration "Generation2" -VpnClientProtocol OpenVPN

# Sleeps for 4 minutes after creating the gateway
Start-Sleep -Seconds 240

$VPNClientAddressPool = "172.16.201.0/24"
$Gateway = Get-AzVirtualNetworkGateway -ResourceGroupName $resourceGroupName -Name $gwname
Set-AzVirtualNetworkGateway -VirtualNetworkGateway $Gateway -VpnClientAddressPool $VPNClientAddressPool

# Output the VPN gateway information and IP address
Write-Output "VPN Gateway Name: $gwname"
Write-Output "VPN Gateway Public IP Address: $($gwpip.IpAddress)"


# Checks subnets in hub VNET and list address prefixes
Write-host $vnet.Name -ForegroundColor Green
$vnet.Subnets | ForEach-Object {
    Write-Output "Subnet: $($_.Name) AddressPrefix: $($_.AddressPrefix)"
}
