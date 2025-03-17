# Azure Policy Setup Script for Education Environment
# This script sets up Azure Policies for allowed locations, tag inheritance, VM SKUs, and required tagging

# Connect to Azure Account
Connect-AzAccount

# Get subscription and tenant details for context
# Select the subscription to apply policies to (replace with your subscription ID)
$subscription = Get-AzSubscription -SubscriptionId "41082359-57d6-4427-b5d9-21e269157652"
Set-AzContext -Subscription $subscription.id

Write-Host "Setting up policies for subscription: $($subscription.Name) ($($subscription.Id))"

# 1. Allowed Locations Policy
$allowedLocations = @("norwayeast", "norwaywest", "northeurope", "westeurope", "uksouth")

# Create the policy definition in JSON format
$locationPolicyRule = @"
{
    "if": {
        "not": {
            "field": "location",
            "in": ["norwayeast", "norwaywest", "northeurope", "westeurope", "uksouth"]
        }
    },
    "then": {
        "effect": "deny"
    }
}
"@

$locationPolicyDefinition = @{
    Name         = "allowed-locations-policy"
    DisplayName  = "Allowed Locations for Resources"
    Description  = "This policy restricts the locations that can be used for resource deployment"
    Policy       = $locationPolicyRule
}

# Create location policy
$locationPolicy = New-AzPolicyDefinition @locationPolicyDefinition -Metadata '{"category":"Location"}'
Write-Host "Created location policy: $($locationPolicy.Name)"


# Create inherit tag policy
$inheritTagPolicy = New-AzPolicyDefinition @inheritTagPolicyDefinition -Metadata '{"category":"Tags"}'
Write-Host "Created inherit tag policy: $($inheritTagPolicy.Name)"

# 2. Allowed VM SKUs Policy
# Selected education-friendly, cost-effective SKUs
$vmSkuPolicyRule = @"
{
    "if": {
        "allOf": [
            {
                "field": "type",
                "equals": "Microsoft.Compute/virtualMachines"
            },
            {
                "not": {
                    "field": "Microsoft.Compute/virtualMachines/sku.name",
                    "in": [
                        "Standard_B1s", "Standard_B1ms", "Standard_B2s", "Standard_B2ms",
                        "Standard_D2s_v3", "Standard_D2_v3", "Standard_D4s_v3",
                        "Standard_F2s_v2", "Standard_F4s_v2",
                        "Standard_DS1_v2", "Standard_DS2_v2", 
                        "Standard_A1_v2", "Standard_A2_v2"
                    ]
                }
            }
        ]
    },
    "then": {
        "effect": "deny"
    }
}
"@

$vmSkuPolicyDefinition = @{
    Name         = "allowed-vm-skus-policy"
    DisplayName  = "Allowed VM SKUs for Education"
    Description  = "This policy restricts the VM SKUs that can be deployed to cost-effective options suitable for education environments"
    Policy       = $vmSkuPolicyRule
}

# Create VM SKU policy
$vmSkuPolicy = New-AzPolicyDefinition @vmSkuPolicyDefinition -Metadata '{"category":"Compute"}'
Write-Host "Created VM SKU policy: $($vmSkuPolicy.Name)"

# 3. Enforce Owner Tag Policy
$requireOwnerTagPolicyRule = @"
{
    "if": {
        "field": "tags['Owner']",
        "exists": "false"
    },
    "then": {
        "effect": "deny"
    }
}
"@

$requireOwnerTagPolicyDefinition = @{
    Name         = "require-owner-tag-policy"
    DisplayName  = "Require Owner tag on all resources"
    Description  = "This policy enforces that all resources must have an Owner tag"
    Policy       = $requireOwnerTagPolicyRule
}

# Create tag requirement policy
$requireOwnerTagPolicy = New-AzPolicyDefinition @requireOwnerTagPolicyDefinition -Metadata '{"category":"Tags"}'
Write-Host "Created require Owner tag policy: $($requireOwnerTagPolicy.Name)"

# Assign policies at subscription level
Write-Host "Assigning policies to subscription $($subscription.Id)..."

# 1. Assign location policy
$locationAssignment = New-AzPolicyAssignment -Name "allowed-locations-assignment" `
                       -DisplayName "Restrict Resource Locations" `
                       -Scope "/subscriptions/$($subscription.Id)" `
                       -PolicyDefinition $locationPolicy

# 2. Assign VM SKU policy
$vmSkuAssignment = New-AzPolicyAssignment -Name "vm-sku-assignment" `
                    -DisplayName "Restrict VM Sizes for Education" `
                    -Scope "/subscriptions/$($subscription.Id)" `
                    -PolicyDefinition $vmSkuPolicy

# 3. Assign Owner tag policy
$requireOwnerTagAssignment = New-AzPolicyAssignment -Name "require-owner-tag-assignment" `
                              -DisplayName "Require Owner Tag on Resources" `
                              -Scope "/subscriptions/$($subscription.Id)" `
                              -PolicyDefinition $requireOwnerTagPolicy

Write-Host "Policy setup complete. All policies have been assigned to subscription $($subscription.Id)."
Write-Host "NOTE: For the tag inheritance policy to work, you must first add an Owner tag to your subscription."

# Add an Owner tag to the subscription (uncomment to use)
# $subscriptionId = $subscription.Id
# $subscriptionTag = @{"Owner"="Education Admin"}
# Update-AzTag -ResourceId "/subscriptions/$subscriptionId" -Tag $subscriptionTag -Operation Merge