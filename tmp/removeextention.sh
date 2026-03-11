#!/bin/bash

# =============================================================================
# Script: Disable Microsoft Defender for Cloud on Arc Machines (v3.0 - FIXED)
# Purpose: List all Arc machines with Defender, then remove after confirmation
# Version: 3.0 - Search by extension NAME instead of TYPE
# =============================================================================

echo "=========================================="
echo "Defender Extension Scanner for Arc Machines"
echo "=========================================="
echo ""

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Get current subscription info
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo -e "${CYAN}Current Subscription:${NC} $SUBSCRIPTION_NAME"
echo -e "${CYAN}Subscription ID:${NC} $SUBSCRIPTION_ID"
echo ""

# Install/update connectedmachine extension if needed
echo "Ensuring Azure CLI connectedmachine extension is installed..."
az extension add --name connectedmachine --upgrade --yes 2>/dev/null
echo ""

echo "Scanning for Arc-enabled machines with Defender extensions..."
echo ""

# Defender extension NAME patterns to look for
DEFENDER_NAMES=(
    "MDE.Windows"
    "MDE.Linux"
    "MicrosoftDefenderForEndpoint"
    "AzureSecurityWindowsAgent"
    "AzureSecurityLinuxAgent"
)

# First, get all resource groups
echo "Step 1: Finding resource groups..."
RESOURCE_GROUPS=$(az group list --query "[].name" -o tsv)

if [ -z "$RESOURCE_GROUPS" ]; then
    echo -e "${YELLOW}No resource groups found in this subscription.${NC}"
    exit 0
fi

RG_COUNT=$(echo "$RESOURCE_GROUPS" | wc -l)
echo -e "${GREEN}Found $RG_COUNT resource groups${NC}"
echo ""

# Get Arc machines from all resource groups
echo "Step 2: Scanning resource groups for Arc machines..."
TOTAL_MACHINES=0
ALL_MACHINES_JSON="[]"

CURRENT_RG=0
while IFS= read -r rg; do
    ((CURRENT_RG++))
    echo -ne "\rScanning RG $CURRENT_RG/$RG_COUNT: $rg...                    "
    
    # Get Arc machines in this RG
    MACHINES_IN_RG=$(az connectedmachine list \
        --resource-group "$rg" \
        --query "[].{name:name, resourceGroup:'$rg', osName:osName}" \
        -o json 2>/dev/null)
    
    if [ $? -eq 0 ] && [ "$MACHINES_IN_RG" != "[]" ]; then
        # Merge with existing machines
        ALL_MACHINES_JSON=$(echo "$ALL_MACHINES_JSON $MACHINES_IN_RG" | jq -s 'add')
        MACHINE_COUNT=$(echo "$MACHINES_IN_RG" | jq '. | length')
        ((TOTAL_MACHINES += MACHINE_COUNT))
    fi
done <<< "$RESOURCE_GROUPS"

echo "" # New line after progress
echo ""

if [ "$TOTAL_MACHINES" -eq 0 ]; then
    echo -e "${YELLOW}No Arc-enabled machines found in this subscription.${NC}"
    exit 0
fi

echo -e "${GREEN}Total Arc machines found: $TOTAL_MACHINES${NC}"
echo ""

# Clean up temp file if exists
rm -f /tmp/defender_machines.txt

# Scan each machine for Defender extensions
echo "Step 3: Scanning each machine for Defender extensions..."
echo ""

SCAN_COUNT=0
echo "$ALL_MACHINES_JSON" | jq -c '.[]' | while read -r machine; do
    MACHINE_NAME=$(echo $machine | jq -r '.name')
    RESOURCE_GROUP=$(echo $machine | jq -r '.resourceGroup')
    OS_NAME=$(echo $machine | jq -r '.osName')
    
    ((SCAN_COUNT++))
    echo -ne "\rScanning machine $SCAN_COUNT / $TOTAL_MACHINES...        "
    
    # Get all extensions on this machine
    EXTENSIONS=$(az connectedmachine extension list \
        --machine-name "$MACHINE_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "[].{name:name}" \
        -o json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        continue
    fi
    
    # Check for Defender extensions BY NAME (not type!)
    HAS_DEFENDER=false
    DEFENDER_EXT_LIST=""
    
    for DEFENDER_NAME in "${DEFENDER_NAMES[@]}"; do
        # Check if extension name matches
        EXT_FOUND=$(echo $EXTENSIONS | jq -r --arg name "$DEFENDER_NAME" '
            .[] | 
            select(.name == $name) | 
            .name
        ')
        
        if [ ! -z "$EXT_FOUND" ]; then
            HAS_DEFENDER=true
            if [ ! -z "$DEFENDER_EXT_LIST" ]; then
                DEFENDER_EXT_LIST="$DEFENDER_EXT_LIST, $EXT_FOUND"
            else
                DEFENDER_EXT_LIST="$EXT_FOUND"
            fi
        fi
    done
    
    # If Defender found, save to temporary file
    if [ "$HAS_DEFENDER" = true ]; then
        echo "$MACHINE_NAME|$RESOURCE_GROUP|$OS_NAME|$DEFENDER_EXT_LIST" >> /tmp/defender_machines.txt
    fi
done

echo "" # New line after progress
echo ""

# Check if any machines with Defender were found
if [ ! -f /tmp/defender_machines.txt ]; then
    echo -e "${GREEN}✓ No Defender extensions found on any Arc machines!${NC}"
    echo -e "${GREEN}✓ No action needed.${NC}"
    exit 0
fi

# Count machines with Defender
MACHINES_WITH_DEFENDER_COUNT=$(wc -l < /tmp/defender_machines.txt)

echo "=========================================="
echo -e "${RED}MACHINES WITH DEFENDER EXTENSIONS${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}Found $MACHINES_WITH_DEFENDER_COUNT machines with Defender extensions:${NC}"
echo ""

# Display table header
printf "%-40s %-35s %-15s %-60s\n" "MACHINE NAME" "RESOURCE GROUP" "OS" "DEFENDER EXTENSIONS"
printf "%-40s %-35s %-15s %-60s\n" "------------" "--------------" "--" "-------------------"

# Display each machine
while IFS='|' read -r machine_name rg os_name extensions; do
    printf "%-40s %-35s %-15s %-60s\n" "$machine_name" "$rg" "$os_name" "$extensions"
done < /tmp/defender_machines.txt

echo ""
echo "=========================================="
echo -e "${RED}ESTIMATED COST IMPACT${NC}"
echo "=========================================="
echo ""
echo "Defender for Servers cost: ~€13/server/month"
echo -e "Total machines: ${YELLOW}$MACHINES_WITH_DEFENDER_COUNT${NC}"
echo -e "Estimated monthly cost: ${RED}€$(($MACHINES_WITH_DEFENDER_COUNT * 13))${NC}"
echo ""
echo "By removing Defender extensions, you will save this cost."
echo ""

# CRITICAL CONFIRMATION
echo "=========================================="
echo -e "${RED}⚠️  CONFIRMATION REQUIRED${NC}"
echo "=========================================="
echo ""
echo "This will REMOVE Defender extensions from all machines listed above."
echo "This action cannot be undone."
echo ""
echo -e "${YELLOW}To proceed, type exactly:${NC} ${GREEN}YES${NC} (in capital letters)"
echo -e "${YELLOW}To cancel, type anything else or press Ctrl+C${NC}"
echo ""

read -p "Your response: " CONFIRMATION

if [[ "$CONFIRMATION" != "YES" ]]; then
    echo ""
    echo -e "${YELLOW}Operation cancelled. No changes were made.${NC}"
    rm -f /tmp/defender_machines.txt
    exit 0
fi

echo ""
echo "=========================================="
echo "REMOVING DEFENDER EXTENSIONS"
echo "=========================================="
echo ""

# Statistics
TOTAL_EXTENSIONS_REMOVED=0
TOTAL_MACHINES_PROCESSED=0
ERRORS=0

# Process each machine and remove Defender
while IFS='|' read -r machine_name rg os_name extensions; do
    echo "----------------------------------------"
    echo -e "Processing: ${YELLOW}$machine_name${NC} (RG: $rg)"
    
    # Get all extensions on this machine again (fresh data)
    MACHINE_EXTENSIONS=$(az connectedmachine extension list \
        --machine-name "$machine_name" \
        --resource-group "$rg" \
        --query "[].{name:name}" \
        -o json 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}  ✗ Error listing extensions${NC}"
        ((ERRORS++))
        continue
    fi
    
    # Check and remove each Defender extension BY NAME
    REMOVED_COUNT=0
    for DEFENDER_NAME in "${DEFENDER_NAMES[@]}"; do
        EXT_FOUND=$(echo $MACHINE_EXTENSIONS | jq -r --arg name "$DEFENDER_NAME" '
            .[] | 
            select(.name == $name) | 
            .name
        ')
        
        if [ ! -z "$EXT_FOUND" ]; then
            echo -e "  Removing extension: ${YELLOW}$EXT_FOUND${NC}"
            
            az connectedmachine extension delete \
                --machine-name "$machine_name" \
                --resource-group "$rg" \
                --name "$EXT_FOUND" \
                --yes \
                --no-wait 2>/dev/null
            
            if [ $? -eq 0 ]; then
                echo -e "  ${GREEN}✓ Removal initiated${NC}"
                ((TOTAL_EXTENSIONS_REMOVED++))
                ((REMOVED_COUNT++))
            else
                echo -e "  ${RED}✗ Failed to remove extension${NC}"
                ((ERRORS++))
            fi
        fi
    done
    
    if [ $REMOVED_COUNT -eq 0 ]; then
        echo -e "  ${YELLOW}⚠ No Defender extensions found (may have been removed already)${NC}"
    fi
    
    ((TOTAL_MACHINES_PROCESSED++))
    echo ""
    
done < /tmp/defender_machines.txt

# Cleanup temp file
rm -f /tmp/defender_machines.txt

# Final Summary
echo "=========================================="
echo "OPERATION COMPLETE"
echo "=========================================="
echo ""
echo -e "Machines processed:           ${GREEN}$TOTAL_MACHINES_PROCESSED${NC}"
echo -e "Defender extensions removed:  ${GREEN}$TOTAL_EXTENSIONS_REMOVED${NC}"
echo -e "Errors encountered:           ${RED}$ERRORS${NC}"
echo ""
echo -e "${YELLOW}⚠ Note: Extensions are being removed asynchronously (--no-wait)${NC}"
echo -e "${YELLOW}   It may take 5-10 minutes for all removals to complete.${NC}"
echo ""
echo "=========================================="
echo "ESTIMATED MONTHLY SAVINGS"
echo "=========================================="
echo ""
echo -e "Estimated cost reduction: ${GREEN}€$(($TOTAL_MACHINES_PROCESSED * 13))/month${NC}"
echo -e "Annual savings:           ${GREEN}€$(($TOTAL_MACHINES_PROCESSED * 13 * 12))/year${NC}"
echo ""
echo "=========================================="
echo "VERIFICATION COMMANDS"
echo "=========================================="
echo ""
echo "Wait 10 minutes, then verify removal with:"
echo ""
echo "# Check a specific machine:"
echo "az connectedmachine extension list \\"
echo "  --machine-name <machine-name> \\"
echo "  --resource-group <resource-group>"
echo ""
echo "# Or check in Azure Portal:"
echo "Azure Arc → Machines → [Select machine] → Extensions"
echo ""
echo "# Re-run this script to scan again:"
echo "# (Should show 'No Defender extensions found')"
echo ""