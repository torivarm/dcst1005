#!/bin/bash

# Script to create two Ubuntu Linux VMs in Azure without public IPs
# This script prompts for subnet information and uses password authentication

# Exit on error
set -e

# Variables - change these as needed
RESOURCE_GROUP="rg-vm-ubuntu-ne-tim"
LOCATION="norwayeast"
VM_SIZE="Standard_B1s"  # Small VM size
VM_NAME_PREFIX="ubuntu-vm"
VNET_NAME="vnet-dev-norwayeast"
VM_USERNAME="timUbuntu"
UBUNTU_VERSION="20.04-LTS"  # Ubuntu version

# Create resource group if it doesn't exist
echo "Checking if resource group exists..."
if ! az group show --name $RESOURCE_GROUP &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create --name $RESOURCE_GROUP --location $LOCATION
else
    echo "Resource group $RESOURCE_GROUP already exists"
fi

# Check if VNET exists
echo "Checking if Virtual Network exists..."
if ! az network vnet show --resource-group $RESOURCE_GROUP --name $VNET_NAME &>/dev/null; then
    echo "ERROR: Virtual Network $VNET_NAME does not exist in resource group $RESOURCE_GROUP"
    echo "Please create the VNET first with appropriate subnets"
    exit 1
fi

# Get list of subnets in the VNET
SUBNET_LIST=$(az network vnet subnet list --resource-group $RESOURCE_GROUP --vnet-name $VNET_NAME --query "[].name" -o tsv)

if [ -z "$SUBNET_LIST" ]; then
    echo "ERROR: No subnets found in VNET $VNET_NAME"
    exit 1
fi

# Display available subnets
echo "Available subnets in $VNET_NAME:"
echo "$SUBNET_LIST"

# Prompt for subnet selection for VM1
echo ""
read -p "Enter subnet name for VM1: " SUBNET_VM1
if ! echo "$SUBNET_LIST" | grep -q "^$SUBNET_VM1$"; then
    echo "ERROR: Subnet $SUBNET_VM1 not found in VNET $VNET_NAME"
    exit 1
fi

# Prompt for subnet selection for VM2
echo ""
read -p "Enter subnet name for VM2: " SUBNET_VM2
if ! echo "$SUBNET_LIST" | grep -q "^$SUBNET_VM2$"; then
    echo "ERROR: Subnet $SUBNET_VM2 not found in VNET $VNET_NAME"
    exit 1
fi

# Not creating NSG since subnets already have NSGs attached

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
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name "${VM_NAME_PREFIX}-1" \
    --image "Canonical:UbuntuServer:${UBUNTU_VERSION}:latest" \
    --admin-username $VM_USERNAME \
    --admin-password "$VM_PASSWORD" \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_VM1 \
    --size $VM_SIZE \
    --public-ip-address "" \
    --no-wait

# Create VM2
echo "Creating VM2: ${VM_NAME_PREFIX}-2"
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name "${VM_NAME_PREFIX}-2" \
    --image "Canonical:UbuntuServer:${UBUNTU_VERSION}:latest" \
    --admin-username $VM_USERNAME \
    --admin-password "$VM_PASSWORD" \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_VM2 \
    --size $VM_SIZE \
    --public-ip-address "" \
    --no-wait

echo ""
echo "VM creation started in the background. You can check status with:"
echo "az vm list --resource-group $RESOURCE_GROUP --query \"[].{Name:name, ProvisioningState:provisioningState}\" -o table"

echo ""
echo "Once complete, you can get the private IP addresses with:"
echo "az vm list-ip-addresses --resource-group $RESOURCE_GROUP --output table"