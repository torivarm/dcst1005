#https://docs.microsoft.com/en-us/azure/vpn-gateway/vpn-gateway-peering-gateway-transit

$prefix = 'demo'
$hubvnet = "$prefix-vnet-hub-shared-uk"
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'
$vnet1name = "$prefix-vnet-web-shared-uk-001"
$vnet2name = "$prefix-vnet-hr-prod-uk-001"
$vnet3name = "$prefix-vnet-hrdev-dev-uk-001"
$peeringNameHUBvnet1 = "$hubvnet-to-$vnet1name"
$peeringNameHUBvnet2 = "$hubvnet-to-$vnet2name"
$peeringNameHUBvnet3 = "$hubvnet-to-$vnet3name"
$hubvnet1peeringName = "$vnet1name-to-$hubvnet"
$hubvnet2peeringName = "$vnet2name-to-$hubvnet"
$hubvnet3peeringName = "$vnet3name-to-$hubvnet"

$LinkHubToSpoke1 = Get-AzVirtualNetworkPeering `
                      -VirtualNetworkName $hubvnet `
                      -ResourceGroupName $resourceGroupName `
                      -Name $peeringNameHUBvnet1

$LinkHubToSpoke1.AllowGatewayTransit = $True
$LinkHubToSpoke1.AllowForwardedTraffic = $True

Set-AzVirtualNetworkPeering -VirtualNetworkPeering $LinkHubToSpoke1

$LinkSpoke1toHub = Get-AzVirtualNetworkPeering `
                      -VirtualNetworkName $vnet1name `
                      -ResourceGroupName $resourceGroupName `
                      -Name $hubvnet1peeringName

$LinkSpoke1toHub.UseRemoteGateways = $True
$LinkSpoke1toHub.AllowForwardedTraffic = $True

Set-AzVirtualNetworkPeering -VirtualNetworkPeering $LinkSpoke1toHub


$LinkHubToSpoke2 = Get-AzVirtualNetworkPeering `
                      -VirtualNetworkName $hubvnet `
                      -ResourceGroupName $resourceGroupName `
                      -Name $peeringNameHUBvnet2

$LinkHubToSpoke2.AllowGatewayTransit = $True
$LinkHubToSpoke2.AllowForwardedTraffic = $True

Set-AzVirtualNetworkPeering -VirtualNetworkPeering $LinkHubToSpoke2

$LinkSpoke2toHub = Get-AzVirtualNetworkPeering `
                      -VirtualNetworkName $vnet2name `
                      -ResourceGroupName $resourceGroupName `
                      -Name $hubvnet2peeringName

$LinkSpoke2toHub.UseRemoteGateways = $True
$LinkSpoke2toHub.AllowForwardedTraffic = $True

Set-AzVirtualNetworkPeering -VirtualNetworkPeering $LinkSpoke2toHub


$LinkHubToSpoke3 = Get-AzVirtualNetworkPeering `
                      -VirtualNetworkName $hubvnet `
                      -ResourceGroupName $resourceGroupName `
                      -Name $peeringNameHUBvnet3

$LinkHubToSpoke3.AllowGatewayTransit = $True
$LinkHubToSpoke3.AllowForwardedTraffic = $True

Set-AzVirtualNetworkPeering -VirtualNetworkPeering $LinkHubToSpoke3


$LinkSpoke3toHub = Get-AzVirtualNetworkPeering `
                      -VirtualNetworkName $vnet3name `
                      -ResourceGroupName $resourceGroupName `
                      -Name $hubvnet3peeringName

$LinkSpoke3toHub.UseRemoteGateways = $True
$LinkSpoke3toHub.AllowForwardedTraffic = $True

Set-AzVirtualNetworkPeering -VirtualNetworkPeering $LinkSpoke3toHub

