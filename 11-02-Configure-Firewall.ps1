# In this script, we will configure the Azure Firewall created in 11-01-Create-AzFirewall.ps1 to allow from VMs in the spoke VNETs to the internet.
# This is done by creating a network default route for the spoke VNETs to the Azure Firewall.
# We will also configure the firewall to allow traffic from Internet to a VM with a web server in the spoke VNET: $PREFIX-vnet-web-shared-uk-001

# Variables
$prefix = 'demo'
$resourceGroupName = $prefix + '-rg-network-001'
$location = 'uksouth'
$vnetNameHUB = "$prefix-vnet-hub-shared-uk"
$fwName = "$prefix-Azfw"
$spokeVNET1 = "$prefix-vnet-web-shared-uk-001"

# VM
$resourceGroupNameVM = $prefix + '-rg-vm-001'
$vmName = "$prefix-vm-web-prod-uk-001"

# Get the Azure Firewall
"Getting the Azure Firewall..."
try {
    $fw = Get-AzFirewall -Name $fwName -ResourceGroupName $resourceGroupName
    $fw.Name
}
catch {
    Write-Error "Azure Firewall '$fwName' not found. Please create the Azure Firewall or check the name."
    exit
}

# Get the spoke VNETs
"Getting the spoke VNETs..."
try {
    $vnet1 = Get-AzVirtualNetwork -Name $spokeVNET1 -ResourceGroupName $resourceGroupName
    $vnet1.Name
}
catch {
    Write-Error "VNET '$spokeVNET1' not found. Please create the VNET or check the name."
    exit
}

# Get the VM
"Getting the VM..."
try {
    $vm = Get-AzVM -Name $vmName -ResourceGroupName $resourceGroupNameVM
    $vm.Name
}
catch {
    Write-Error "VM '$vmName' not found. Please create the VM or check the name."
    exit
}



# Create a routing table for the Azure Firewall
$AzFirewallRouteTable = New-AzRouteTable `
                -Name "$prefix-azfw-routetable" `
                -ResourceGroupName $resourceGroupName `
                -location $Location

# Create a new default route for the Azure Firewall and attach it to the routing table
Get-AzRouteTable -ResourceGroupName $resourceGroupName `
                -Name $AzFirewallRouteTable.Name | Add-AzRouteConfig `
                -Name "DefaultRoute" `
                -AddressPrefix "0.0.0.0/0" `
                -NextHopType "VirtualAppliance" `
                -NextHopIpAddress $fw.IpConfigurations.PrivateIpAddress `
                | Set-AzRouteTable
 

# Associate the routing table to the web spoke VNET subnet
$subnetName = "$prefix-snet-web-prod-uk-001"
"Associating the routing table to the subnet '$subnetName'..."
try {
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet1
    $subnet.Name

    try {
        Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet1 `
                                        -Name $subnetName  `
                                        -AddressPrefix $subnet.AddressPrefix `
                                        -RouteTable $AzFirewallRouteTable | Set-AzVirtualNetwork
    }
    catch {
        Write-Error "Failed to associate the route table with the subnet '$subnetName'."
        exit
    }
}
catch {
    Write-Error "Subnet '$subnetName' not found. Please create the subnet or check the name."
    exit
}


# Configure for external access to the web server in the spoke VNET
# Getting the Firewall Public IP
"Getting the public IP address of the Azure Firewall..."
try {
    $fwpip = Get-AzPublicIpAddress -Name ($fwName + '-pip') -ResourceGroupName $resourceGroupName
    $fwpip.Name
    $fwpip.IpAddress
}
catch {
    Write-Error "Public IP for the Azure Firewall not found. Please create the public IP or check the name."
    exit
}

# Getting the NIC of the VM
"Getting the NIC of the VM..."
try {
    $nic = Get-AzNetworkInterface -Name ($vmName + '-nic') -ResourceGroupName $resourceGroupNameVM
    $nic.Name
    $nic = Get-AzNetworkInterface -ResourceId $Vm.NetworkProfile.NetworkInterfaces.id
    $nic.IpConfigurations.PrivateIpAddress

}
catch {
    Write-Error "NIC for the VM not found. Please create the NIC or check the name."
    exit
}

# Create a NAT rule collection for the web server

# NAT Rule
$natRule = New-AzFirewallNatRule `
                -Name "WebServer" `
                -Protocol "TCP" `
                -SourceAddress "*" `
                -DestinationAddress $fwpip.IpAddress `
                -DestinationPort "80" `
                -TranslatedAddress $nic.IpConfigurations.PrivateIpAddress `
                -TranslatedPort "80" 


# Create NAT rule collection for the web server
$collectionRule = New-AzFirewallNatRuleCollection `
                -Name "WebServer" `
                -Priority 100 `
                -Rule $natRule

# Update the Azure Firewall with the NAT rule collection
$fw.NatRuleCollections = $collectionRule
$fw | Set-AzFirewall