#!/bin/bash

# Script to create two Ubuntu Linux VMs in Azure without public IPs
# VMs will be created in a new resource group
# Each VM will connect to a different VNet/Subnet in an existing resource group

# Exit on error
set -e

# Function to handle exit
function cleanup {
  echo "Script execution completed or interrupted."
}

# Register the function to be called on exit
trap cleanup EXIT

# VM settings - change these as needed
VM_RESOURCE_GROUP="rg-vm-ne-tim"
VM_LOCATION="norwayeast"
VM_SIZE="Standard_B1s"  # Small VM size
VM_NAME_PREFIX="vm-ubuntu-tim"
VM_USERNAME="timubuntu"
UBUNTU_VERSION="20.04-LTS"  # Ubuntu version

# Prompt for networking resource group
echo "The VNets and Subnets should be in an existing resource group"
read -p "Enter the resource group name for VNets/Subnets: " NETWORK_RESOURCE_GROUP

# Check if networking resource group exists
if ! az group show --name "$NETWORK_RESOURCE_GROUP" &>/dev/null; then
    echo "ERROR: Resource group $NETWORK_RESOURCE_GROUP does not exist"
    exit 1
fi

# Get list of VNets in the networking resource group
VNET_LIST=$(az network vnet list --resource-group "$NETWORK_RESOURCE_GROUP" --query "[].name" -o tsv)

if [ -z "$VNET_LIST" ]; then
    echo "ERROR: No virtual networks found in resource group $NETWORK_RESOURCE_GROUP"
    exit 1
fi

# Display available VNets for VM1
echo "Available virtual networks in $NETWORK_RESOURCE_GROUP for VM1:"
echo "$VNET_LIST"

# Prompt for VNet selection for VM1
echo ""
read -p "Enter VNet name for VM1: " VNET_VM1
if ! echo "$VNET_LIST" | grep -q "^$VNET_VM1$"; then
    echo "ERROR: VNet $VNET_VM1 not found in resource group $NETWORK_RESOURCE_GROUP"
    exit 1
fi

# Get list of subnets in the selected VNet for VM1
SUBNET_LIST_VM1=$(az network vnet subnet list --resource-group "$NETWORK_RESOURCE_GROUP" --vnet-name "$VNET_VM1" --query "[].name" -o tsv)

if [ -z "$SUBNET_LIST_VM1" ]; then
    echo "ERROR: No subnets found in VNet $VNET_VM1"
    exit 1
fi

# Display available subnets for VM1
echo "Available subnets in $VNET_VM1 for VM1:"
echo "$SUBNET_LIST_VM1"

# Prompt for subnet selection for VM1
echo ""
read -p "Enter subnet name for VM1: " SUBNET_VM1
if ! echo "$SUBNET_LIST_VM1" | grep -q "^$SUBNET_VM1$"; then
    echo "ERROR: Subnet $SUBNET_VM1 not found in VNet $VNET_VM1"
    exit 1
fi

# Display available VNets for VM2
echo "Available virtual networks in $NETWORK_RESOURCE_GROUP for VM2:"
echo "$VNET_LIST"

# Prompt for VNet selection for VM2
echo ""
read -p "Enter VNet name for VM2: " VNET_VM2
if ! echo "$VNET_LIST" | grep -q "^$VNET_VM2$"; then
    echo "ERROR: VNet $VNET_VM2 not found in resource group $NETWORK_RESOURCE_GROUP"
    exit 1
fi

# Get list of subnets in the selected VNet for VM2
SUBNET_LIST_VM2=$(az network vnet subnet list --resource-group "$NETWORK_RESOURCE_GROUP" --vnet-name "$VNET_VM2" --query "[].name" -o tsv)

if [ -z "$SUBNET_LIST_VM2" ]; then
    echo "ERROR: No subnets found in VNet $VNET_VM2"
    exit 1
fi

# Display available subnets for VM2
echo "Available subnets in $VNET_VM2 for VM2:"
echo "$SUBNET_LIST_VM2"

# Prompt for subnet selection for VM2
echo ""
read -p "Enter subnet name for VM2: " SUBNET_VM2
if ! echo "$SUBNET_LIST_VM2" | grep -q "^$SUBNET_VM2$"; then
    echo "ERROR: Subnet $SUBNET_VM2 not found in VNet $VNET_VM2"
    exit 1
fi

# Create VM resource group if it doesn't exist
echo "Checking if VM resource group exists..."
if ! az group show --name "$VM_RESOURCE_GROUP" &>/dev/null; then
    echo "Creating resource group: $VM_RESOURCE_GROUP"
    az group create --name "$VM_RESOURCE_GROUP" --location "$VM_LOCATION"
else
    echo "Resource group $VM_RESOURCE_GROUP already exists"
fi

# Prompt for password (with hidden input)
echo ""
read -sp "Enter password for VMs (min 12 chars with uppercase, lowercase, numbers, and special chars): " VM_PASSWORD
echo ""

# Validate password meets Azure requirements
if [[ ${#VM_PASSWORD} -lt 12 ]]; then
    echo "ERROR: Password must be at least 12 characters long"
    exit 1
fi

# Create VM1
echo "Creating VM1: ${VM_NAME_PREFIX}-1"
set +e  # Turn off exit on error for VM creation
az vm create \
    --resource-group "$VM_RESOURCE_GROUP" \
    --name "${VM_NAME_PREFIX}-1" \
    --image "Canonical:UbuntuServer:${UBUNTU_VERSION}:latest" \
    --admin-username "$VM_USERNAME" \
    --admin-password "$VM_PASSWORD" \
    --vnet-name "$VNET_VM1" \
    --subnet "$SUBNET_VM1" \
    --vnet-resource-group "$NETWORK_RESOURCE_GROUP" \
    --size "$VM_SIZE" \
    --public-ip-address "" \
    --no-wait
set -e  # Turn exit on error back on

# Create VM2
echo "Creating VM2: ${VM_NAME_PREFIX}-2"
set +e  # Turn off exit on error for VM creation
az vm create \
    --resource-group "$VM_RESOURCE_GROUP" \
    --name "${VM_NAME_PREFIX}-2" \
    --image "Canonical:UbuntuServer:${UBUNTU_VERSION}:latest" \
    --admin-username "$VM_USERNAME" \
    --admin-password "$VM_PASSWORD" \
    --vnet-name "$VNET_VM2" \
    --subnet "$SUBNET_VM2" \
    --vnet-resource-group "$NETWORK_RESOURCE_GROUP" \
    --size "$VM_SIZE" \
    --public-ip-address "" \
    --no-wait
set -e  # Turn exit on error back on

echo ""
echo "VM creation commands have been submitted."
echo ""
echo "To check VM deployment status, run:"
echo "az vm list --resource-group $VM_RESOURCE_GROUP --query \"[].{Name:name, ProvisioningState:provisioningState}\" -o table"
echo ""
echo "To get the private IP addresses once VMs are deployed, run:"
echo "az vm list-ip-addresses --resource-group $VM_RESOURCE_GROUP --output table"
echo ""
echo "Script completed successfully!"