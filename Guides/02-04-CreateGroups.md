# Managing Active Directory Groups with PowerShell

## Basic Group Creation and Deletion

Let's start with the basic commands to create and delete Active Directory groups.

### Creating a Basic Security Group
```powershell
# Create a new security group
New-ADGroup -Name "IT Support" `
    -GroupScope Global `
    -GroupCategory Security `
    -Path "OU=Groups,DC=contoso,DC=com"
```

### Deleting a Group
```powershell
# Remove a group
Remove-ADGroup -Identity "IT Support" -Confirm:$false
```

## Creating Multiple Groups Using an Array

Here's how to create multiple groups using an array structure.

```powershell
# Define your groups with their properties
$groups = @(
    @{
        Name = "IT Support"
        Path = "OU=IT,OU=Groups,DC=contoso,DC=com"
        Scope = "Global"
        Category = "Security"
    },
    @{
        Name = "HR Team"
        Path = "OU=HR,OU=Groups,DC=contoso,DC=com"
        Scope = "Global"
        Category = "Security"
    },
    @{
        Name = "Finance Users"
        Path = "OU=Finance,OU=Groups,DC=contoso,DC=com"
        Scope = "Global"
        Category = "Security"
    }
)

# Create each group
foreach ($group in $groups) {
    New-ADGroup -Name $group.Name `
        -GroupScope $group.Scope `
        -GroupCategory $group.Category `
        -Path $group.Path
}
```

## Advanced Group Management with Error Handling

Here's a more robust script that includes existence checking and error handling.

```powershell
function New-CustomADGroup {
    param (
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Path,
        [ValidateSet("Global", "Universal", "DomainLocal")]
        [string]$Scope = "Global",
        [ValidateSet("Security", "Distribution")]
        [string]$Category = "Security",
        [string]$Description
    )
    
    try {
        # Check if group exists
        $existingGroup = Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($null -eq $existingGroup) {
            # Create new group
            $params = @{
                Name = $Name
                GroupScope = $Scope
                GroupCategory = $Category
                Path = $Path
            }
            
            if ($Description) {
                $params.Add("Description", $Description)
            }
            
            New-ADGroup @params
            Write-Host "Successfully created group: $Name" -ForegroundColor Green
            return $true
        } else {
            Write-Host "Group already exists: $Name" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "Failed to create group: $Name" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        return $false
    }
}
```

## Managing Group Membership

Here's how to manage group members, including both users and groups.

### Adding Members to a Group

```powershell
function Add-CustomADGroupMember {
    param (
        [Parameter(Mandatory)]
        [string]$GroupName,
        [Parameter(Mandatory)]
        [string[]]$Members
    )
    
    try {
        # Check if group exists
        $group = Get-ADGroup -Identity $GroupName -ErrorAction Stop
        
        foreach ($member in $Members) {
            try {
                # Try to get member (could be user or group)
                $adObject = Get-ADObject -Filter {(objectClass -eq "user") -or (objectClass -eq "group")} -Properties ObjectClass |
                    Where-Object {$_.Name -eq $member}
                
                if ($null -ne $adObject) {
                    # Check if already a member
                    $isMember = Get-ADGroupMember -Identity $GroupName | Where-Object {$_.Name -eq $member}
                    
                    if ($null -eq $isMember) {
                        Add-ADGroupMember -Identity $GroupName -Members $adObject
                        Write-Host "Successfully added $member to $GroupName" -ForegroundColor Green
                    } else {
                        Write-Host "$member is already a member of $GroupName" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "Member not found: $member" -ForegroundColor Red
                }
            } catch {
                Write-Host "Failed to add member $member to $GroupName" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "Group not found: $GroupName" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
```

### Removing Members from a Group

```powershell
function Remove-CustomADGroupMember {
    param (
        [Parameter(Mandatory)]
        [string]$GroupName,
        [Parameter(Mandatory)]
        [string[]]$Members
    )
    
    try {
        # Check if group exists
        $group = Get-ADGroup -Identity $GroupName -ErrorAction Stop
        
        foreach ($member in $Members) {
            try {
                # Check if member exists in group
                $isMember = Get-ADGroupMember -Identity $GroupName | Where-Object {$_.Name -eq $member}
                
                if ($null -ne $isMember) {
                    Remove-ADGroupMember -Identity $GroupName -Members $member -Confirm:$false
                    Write-Host "Successfully removed $member from $GroupName" -ForegroundColor Green
                } else {
                    Write-Host "$member is not a member of $GroupName" -ForegroundColor Yellow
                }
            } catch {
                Write-Host "Failed to remove member $member from $GroupName" -ForegroundColor Red
                Write-Host "Error: $_" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "Group not found: $GroupName" -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
```

## Complete Example with All Features

Here's a complete example that puts it all together:

```powershell
# Define groups to create
$groups = @(
    @{
        Name = "IT Support"
        Path = "OU=IT,OU=Groups,DC=contoso,DC=com"
        Scope = "Global"
        Category = "Security"
        Members = @("John.Doe", "Jane.Smith", "Help Desk")
    },
    @{
        Name = "HR Team"
        Path = "OU=HR,OU=Groups,DC=contoso,DC=com"
        Scope = "Global"
        Category = "Security"
        Members = @("Sarah.Johnson", "HR Managers")
    }
)

# Create groups and add members
foreach ($group in $groups) {
    if (New-CustomADGroup -Name $group.Name -Path $group.Path -Scope $group.Scope -Category $group.Category) {
        if ($group.Members) {
            Add-CustomADGroupMember -GroupName $group.Name -Members $group.Members
        }
    }
}

# Example of removing members
Remove-CustomADGroupMember -GroupName "IT Support" -Members @("John.Doe")

# Example of adding new members
Add-CustomADGroupMember -GroupName "HR Team" -Members @("New.Employee")
```

This script demonstrates:
1. Creating groups with error handling
2. Checking for existing groups
3. Adding both users and groups as members
4. Removing members
5. Handling errors at each step
6. Providing clear feedback for all operations

Remember to replace "DC=contoso,DC=com" and the OU paths with your actual domain structure. Also ensure that the users and groups you're referencing actually exist in your Active Directory environment.