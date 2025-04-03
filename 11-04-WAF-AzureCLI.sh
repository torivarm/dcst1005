#!/bin/bash

# Variables - Modify these to match your environment
RESOURCE_GROUP="rg-vnet-shared-tim"
LOCATION="norwayeast"
HUB_VNET_NAME="vnet-hub-norwayeast"
HUB_VNET_PREFIX="10.70.0.0/16"
AG_SUBNET_NAME="snet-ag-demo-ne-tim"
AG_SUBNET_PREFIX="10.70.2.0/24"
SPOKE_VNET_NAME="vnet-dev-norwayeast"
SPOKE_VNET_PREFIX="10.10.0.0/16"
APP_SUBNET_NAME="snet-privateendpoints-dev-norwayeast"
APP_SUBNET_PREFIX="10.10.3.0/24"
AG_NAME="ag-demo-ne-tim"
AG_PIP_NAME="pip-ag-public-ne-tim"
WAF_POLICY_NAME="waf-policy"
APP_SERVICE_PLAN_NAME="app-service-plan"
WEB_APP_NAME="webapp-$(date +%s)"  # Ensures unique name
PRIVATE_ENDPOINT_NAME="app-private-endpoint"

# If your VNETs and subnets already exist, comment out these VNET and subnet creation commands
# and keep only the commands you need

# Create resource group if needed
# az group create --name $RESOURCE_GROUP --location $LOCATION

# Only uncomment these if you need to create the VNETs and subnets
: '
# Create Hub VNET
az network vnet create \
  --name $HUB_VNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --address-prefix $HUB_VNET_PREFIX \
  --subnet-name $AG_SUBNET_NAME \
  --subnet-prefix $AG_SUBNET_PREFIX

# Create Spoke VNET
az network vnet create \
  --name $SPOKE_VNET_NAME \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --address-prefix $SPOKE_VNET_PREFIX \
  --subnet-name $APP_SUBNET_NAME \
  --subnet-prefix $APP_SUBNET_PREFIX
'

# Setup VNET Peering (Hub to Spoke) if not already established
: '
az network vnet peering create \
  --name HubToSpoke \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $HUB_VNET_NAME \
  --remote-vnet $SPOKE_VNET_NAME \
  --allow-vnet-access

# Setup VNET Peering (Spoke to Hub) if not already established
az network vnet peering create \
  --name SpokeToHub \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $SPOKE_VNET_NAME \
  --remote-vnet $HUB_VNET_NAME \
  --allow-vnet-access
'

# Create public IP for App Gateway
az network public-ip create \
  --resource-group $RESOURCE_GROUP \
  --name $AG_PIP_NAME \
  --allocation-method Static \
  --sku Standard

# Create WAF policy
az network application-gateway waf-policy create \
  --name $WAF_POLICY_NAME \
  --resource-group $RESOURCE_GROUP \
  --type OWASP \
  --version 3.2

# Create Application Gateway in the Hub VNET
az network application-gateway create \
  --name $AG_NAME \
  --location $LOCATION \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $HUB_VNET_NAME \
  --subnet $AG_SUBNET_NAME \
  --capacity 2 \
  --sku WAF_v2 \
  --http-settings-cookie-based-affinity Disabled \
  --frontend-port 80 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --public-ip-address $AG_PIP_NAME \
  --waf-policy $WAF_POLICY_NAME \
  --priority 1

# Create App Service Plan
az appservice plan create \
  --name $APP_SERVICE_PLAN_NAME \
  --resource-group $RESOURCE_GROUP \
  --sku P1V2 \
  --is-linux

# Create Web App
az webapp create \
  --resource-group $RESOURCE_GROUP \
  --plan $APP_SERVICE_PLAN_NAME \
  --name $WEB_APP_NAME \
  --runtime "PYTHON|3.9"

# Configure Web App for VNET integration
az webapp vnet-integration add \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --vnet $SPOKE_VNET_NAME \
  --subnet $APP_SUBNET_NAME

# Disable public access to the web app
az webapp update \
  --resource-group $RESOURCE_GROUP \
  --name $WEB_APP_NAME \
  --set publicNetworkAccess=Disabled

  az network vnet subnet create \
  --name snet-privateendpoints-dev-norwayeast \
  --resource-group rg-vnet-shared-tim \
  --vnet-name vnet-dev-norwayeast \
  --address-prefix 10.10.3.0/24 \
  --disable-private-endpoint-network-policies true

# Create Private Endpoint for App Service
az network private-endpoint create \
  --name $PRIVATE_ENDPOINT_NAME \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $SPOKE_VNET_NAME \
  --subnet $APP_SUBNET_NAME \
  --private-connection-resource-id $(az webapp show --name $WEB_APP_NAME --resource-group $RESOURCE_GROUP --query id -o tsv) \
  --group-id sites \
  --connection-name AppServiceConnection

# Get the private IP of the endpoint
PRIVATE_IP=$(az network private-endpoint show --name $PRIVATE_ENDPOINT_NAME --resource-group $RESOURCE_GROUP --query "customDnsConfigs[0].ipAddresses[0]" -o tsv)

# Create backend pool on App Gateway
az network application-gateway address-pool create \
  --gateway-name $AG_NAME \
  --resource-group $RESOURCE_GROUP \
  --name AppServiceBackendPool \
  --servers $PRIVATE_IP

# Create probe for health checking
az network application-gateway probe create \
  --gateway-name $AG_NAME \
  --resource-group $RESOURCE_GROUP \
  --name AppServiceProbe \
  --protocol Http \
  --host $WEB_APP_NAME.azurewebsites.net \
  --path / \
  --interval 30 \
  --timeout 30 \
  --threshold 3

# Update HTTP settings to use the probe and correct host name
az network application-gateway http-settings update \
  --gateway-name $AG_NAME \
  --resource-group $RESOURCE_GROUP \
  --name appGatewayBackendHttpSettings \
  --host-name $WEB_APP_NAME.azurewebsites.net \
  --probe AppServiceProbe

# Create routing rule
az network application-gateway rule create \
  --gateway-name $AG_NAME \
  --resource-group $RESOURCE_GROUP \
  --name AppServiceRule \
  --address-pool AppServiceBackendPool \
  --http-settings appGatewayBackendHttpSettings \
  --http-listener appGatewayHttpListener \
  --priority 100

# Display the Application Gateway public IP
echo "Application Gateway Public IP: $(az network public-ip show --resource-group $RESOURCE_GROUP --name $AG_PIP_NAME --query ipAddress -o tsv)"
echo "Web App Name: $WEB_APP_NAME"