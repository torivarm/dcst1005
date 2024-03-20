# Description: This script is used to connect to Azure using the Az module
# Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Import the Az module
# Import-Module Az

# Variables - Remember to change these to your own TenantID and SubscriptionID found in the Azure Portal
$tenantID = "bd0944c8-c04e-466a-9729-d7086d13a653"
$subscrptionID = "41082359-57d6-4427-b5d9-21e269157652"

# Connect to Azure
Connect-AzAccount -Tenant $tenantID -Subscription $subscrptionID