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
    New-ADOrganizationalUnit -Name "TestOU" -Path "DC=infrait,DC=sec"
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

```powershell
# Define the OU details
$ouName = "TestOU"
$domainPath = "DC=infrait,DC=sec"
$ouPath = "OU=$ouName,$domainPath"

# Try to create the OU with error handling
try {
    # Check if OU exists
    if (-not(Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -SearchBase $domainPath)) {
        New-ADOrganizationalUnit -Name $ouName -Path $domainPath
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
New-ADOrganizationalUnit -Name "ParentOU" -Path "DC=infrait,DC=sec"

# Then create a child OU inside the parent OU
New-ADOrganizationalUnit -Name "ChildOU" -Path "OU=ParentOU,DC=infrait,DC=sec"
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
            New-ADOrganizationalUnit -Name $Name -Path $Path
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

Remember to replace "DC=infrait,DC=sec" with your actual domain path in all examples.