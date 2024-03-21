# In this script, we will create a new VNET in the Azure Portal
# We need the Az module to create the VNET and other resources 
# Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Import the Az module
# Import-Module Az



# Variables
$tenantID = "bd0944c8-c04e-466a-9729-d7086d13a653" # Remember to change this to your own TenantID
$subscrptionID = "41082359-57d6-4427-b5d9-21e269157652" # Remember to change this to your own SubscriptionID

# Connect to Azure
Connect-AzAccount -Tenant $tenantID -Subscription $subscrptionID



