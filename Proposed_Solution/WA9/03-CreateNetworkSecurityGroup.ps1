# In this PowerShell script, we will create one Network Security Group
# The NSG will be attached to appropriate subnets in the virtual networks on 04-AttachNSGtoSubnet.ps1.
# Then the script will create a rule that allows for inbound traffic on port 80 and 22.

$prefix = "tim"
$nsgName = "$prefix-nsg-port80-22"
$resourceGroupName = "$prefix-rg-network-001"
$location = "uksouth"

# Attempt to fetch an existing NSG
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

# If the NSG doesn't exist, create it
if (-not $nsg) {
    $nsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $nsgName
}

# Define the rule for HTTP traffic on port 80
$httpRule = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "AllowHTTP" `
    -Description "Allow HTTP traffic" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" `
    -Priority 100 -SourceAddressPrefix "Internet" -SourcePortRange "*" `
    -DestinationAddressPrefix "*" -DestinationPortRange 80 -ErrorAction Stop

# Define the rule for SSH traffic on port 22
$sshRule = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $nsg -Name "AllowSSH" `
    -Description "Allow SSH traffic" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" `
    -Priority 110 -SourceAddressPrefix "Internet" -SourcePortRange "*" `
    -DestinationAddressPrefix "*" -DestinationPortRange 22 -ErrorAction Stop

# Update the NSG to include the new rules
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $nsg

# Output the updated NSG rules to verify
$nsgUpdated = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName
$nsgUpdated.SecurityRules | Format-Table Name, Access, Protocol, Direction, Priority, SourceAddressPrefix, DestinationPortRange
