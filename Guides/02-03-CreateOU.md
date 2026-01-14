# Managing Active Directory OUs with PowerShell

## Basic OU Creation and Deletion

Let's start with the simplest way to create and delete an Organizational Unit (OU) in Active Directory using PowerShell.

### Creating a Basic OU
```powershell
New-ADOrganizationalUnit -Name "TestOU" -Path "DC=infrait,DC=sec"
```

### Deleting the OU
There are two approaches to delete an OU:

#### Option 1: Disable Protection and Delete
```powershell
# First, disable the protection
Set-ADOrganizationalUnit -Identity "OU=TestOU,DC=infrait,DC=sec" -ProtectedFromAccidentalDeletion $false

# Then delete the OU
Remove-ADOrganizationalUnit -Identity "OU=TestOU,DC=infrait,DC=sec" -Confirm:$false
```

#### Option 2: Create OU Without Protection
When creating new OUs, you can disable the protection from the start:
```powershell
# Create OU with protection disabled
New-ADOrganizationalUnit -Name "TestOU" -Path "DC=infrait,DC=sec" -ProtectedFromAccidentalDeletion $false

# Now you can delete it without first disabling protection
Remove-ADOrganizationalUnit -Identity "OU=TestOU,DC=infrait,DC=sec" -Confirm:$false
```

## Checking OU Existence Before Creation

Now, let's make our script more robust by checking if the OU exists before trying to create it.

### Checking and Creating an OU
```powershell
# First command: Check if OU exists
if (-not(Get-ADOrganizationalUnit -Filter "Name -eq 'TestOU'" -SearchBase "DC=infrait,DC=sec")) {
    New-ADOrganizationalUnit -Name "TestOU" -Path "DC=infrait,DC=sec" -ProtectedFromAccidentalDeletion $false
}
```

### Deleting with Verification
```powershell
# Second command: Check if OU exists before deleting
if (Get-ADOrganizationalUnit -Filter "Name -eq 'TestOU'" -SearchBase "DC=infrait,DC=sec") {
    Remove-ADOrganizationalUnit -Identity "OU=TestOU,DC=infrait,DC=sec" -Recursive -Confirm:$false
}
```

## Advanced Error Handling with Try-Catch

Let's enhance our script with proper error handling using try-catch blocks.
NOTE: $_ is not “the error message”, but a rich error object of type

```powershell
# Define the OU details
$ouName = "TestOU"
$domainPath = "DC=infrait,DC=sec"
$ouPath = "OU=$ouName,$domainPath"

# Try to create the OU with error handling
try {
    # Check if OU exists
    if (-not(Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $domainPath)) {
        New-ADOrganizationalUnit -Name $ouName -Path $domainPath -ProtectedFromAccidentalDeletion $false
        Write-Host "Successfully created OU: $ouName" -ForegroundColor Green
    } else {
        Write-Host "OU already exists: $ouName" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Failed to create OU: $ouName" -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
}
```

## Creating Nested OUs

When working with nested OUs, it's important to understand the correct path structure and how to create OUs within other OUs.

### Finding the Correct Path
To find the path of an existing OU:
```powershell
# Get the Distinguished Name of an existing OU
Get-ADOrganizationalUnit -Filter "Name -eq 'ParentOU'" -SearchBase "DC=infrait,DC=sec" | 
    Select-Object -ExpandProperty DistinguishedName
```

### Creating an OU Inside Another OU
```powershell
# First, create the parent OU
New-ADOrganizationalUnit -Name "ParentOU" -Path "DC=infrait,DC=sec" -ProtectedFromAccidentalDeletion $false

# Then create a child OU inside the parent OU
New-ADOrganizationalUnit -Name "ChildOU" -Path "OU=ParentOU,DC=infrait,DC=sec" -ProtectedFromAccidentalDeletion $false
```

### Complete Example with Nested OUs and Error Handling
```powershell
# Define the OU structure
$parentOUName = "ParentOU"
$childOUName = "ChildOU"
$domainPath = "DC=infrait,DC=sec"

# Function to create an OU with error handling
function Create-ADOU {
    param (
        [string]$Name,
        [string]$Path
    )
    
    try {
        if (-not(Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path)) {
            New-ADOrganizationalUnit -Name $Name -Path $Path -ProtectedFromAccidentalDeletion $false
            Write-Host "Successfully created OU: $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "OU already exists: $Name" -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Host "Failed to create OU: $Name" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Create parent OU
$parentCreated = Create-ADOU -Name $parentOUName -Path $domainPath

# If parent was created successfully, create child OU
if ($parentCreated) {
    $parentPath = "OU=$parentOUName,$domainPath"
    Create-ADOU -Name $childOUName -Path $parentPath
}
```
This final example shows how to:
1. Create a reusable function for OU creation
2. Handle errors appropriately
3. Create nested OUs
4. Verify success at each step
5. Provide clear feedback to the user

### Complete Example with Multiple Nested OUs
```powershell
# Define the OU structure using a hashtable
$ouStructure = @{
    "IT" = @(
        "Hardware",
        "Software",
        "Network",
        "Support"
    )
    "HR" = @(
        "Recruitment",
        "Training",
        "Benefits",
        "Employee Records"
    )
    "Finance" = @(
        "Accounting",
        "Payroll",
        "Budgeting",
        "Reporting"
    )
}

$domainPath = "DC=InfraIT,DC=sec"

# Function to create an OU with error handling
function New-CustomADOU {
    param (
        [string]$Name,
        [string]$Path,
        [switch]$DisableProtection
    )
    
    try {
        # Check if OU exists - we need to handle the case where the search base doesn't exist
        try {
            $existingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -ErrorAction Stop
        } catch {
            # If SearchBase doesn't exist, we know the OU doesn't exist
            $existingOU = $null
        }
        
        if (-not $existingOU) {
            # Create new OU
            $params = @{
                Name = $Name
                Path = $Path
                ProtectedFromAccidentalDeletion = -not $DisableProtection
            }
            
            New-ADOrganizationalUnit @params
            Write-Host "Successfully created OU: $Name in $Path" -ForegroundColor Green
            return $true
        } else {
            Write-Host "OU already exists: $Name in $Path" -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Host "Failed to create OU: $Name" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Function to remove an OU with error handling
function Remove-CustomADOU {
    param (
        [string]$Identity
    )
    
    try {
        # Check if OU exists
        $ou = Get-ADOrganizationalUnit -Identity $Identity -ErrorAction SilentlyContinue
        
        if ($ou) {
            # Disable protection
            Set-ADOrganizationalUnit -Identity $Identity -ProtectedFromAccidentalDeletion $false
            
            # Remove OU
            Remove-ADOrganizationalUnit -Identity $Identity -Confirm:$false
            Write-Host "Successfully removed OU: $Identity" -ForegroundColor Green
            return $true
        } else {
            Write-Host "OU does not exist: $Identity" -ForegroundColor Yellow
            return $true
        }
    } catch {
        Write-Host "Failed to remove OU: $Identity" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}

# Create all OUs
foreach ($parentOU in $ouStructure.Keys) {
    # Create parent OU
    $parentPath = $domainPath
    Write-Host "`nCreating parent OU: $parentOU" -ForegroundColor Cyan
    $parentCreated = New-CustomADOU -Name $parentOU -Path $parentPath
    
    if ($parentCreated) {
        # Verify parent OU exists before creating children
        $parentFullPath = "OU=$parentOU,$domainPath"
        $verifyParent = Get-ADOrganizationalUnit -Identity $parentFullPath -ErrorAction SilentlyContinue
        
        if ($verifyParent) {
            Write-Host "Verified parent OU exists, creating children..." -ForegroundColor Cyan
            # Create child OUs
            foreach ($childOU in $ouStructure[$parentOU]) {
                $childPath = $parentFullPath
                New-CustomADOU -Name $childOU -Path $childPath
            }
        } else {
            Write-Host "Parent OU verification failed for: $parentOU" -ForegroundColor Red
            Write-Host "Cannot create child OUs" -ForegroundColor Red
        }
    }
}

# Example of how to remove the entire structure
function Remove-OUStructure {
    param (
        [hashtable]$Structure,
        [string]$DomainPath
    )
    
    # Remove child OUs first
    foreach ($parentOU in $Structure.Keys) {
        foreach ($childOU in $Structure[$parentOU]) {
            $childPath = "OU=$childOU,OU=$parentOU,$DomainPath"
            Remove-CustomADOU -Identity $childPath
        }
        
        # Then remove parent OU
        $parentPath = "OU=$parentOU,$DomainPath"
        Remove-CustomADOU -Identity $parentPath
    }
}

# Example usage to remove the structure:
# Remove-OUStructure -Structure $ouStructure -DomainPath $domainPath
```

This example demonstrates:
1. Creating a complex OU structure using a hashtable
2. Reusable functions for creating and removing OUs
3. Proper error handling and protection management
4. Clear feedback for each operation
5. Hierarchical creation (parents before children)
6. Safe removal process (children before parents)
7. Status checking before each operation

Remember to replace "DC=InfraIT,DC=Sec" with your actual domain path in all examples.
