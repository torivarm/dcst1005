# Active Directory User Management with PowerShell - A Comprehensive Guide

## Table of Contents
- [Active Directory User Management with PowerShell - A Comprehensive Guide](#active-directory-user-management-with-powershell---a-comprehensive-guide)
  - [Table of Contents](#table-of-contents)
  - [Basic User Creation](#basic-user-creation)
  - [Advanced User Creation](#advanced-user-creation)
  - [User Existence Check](#user-existence-check)
  - [Password Generation](#password-generation)
  - [Username Generation](#username-generation)
  - [Bulk User Creation from CSV](#bulk-user-creation-from-csv)
  - [Updating User Properties](#updating-user-properties)
  - [OU Path Management](#ou-path-management)
  - [Cleanup Script](#cleanup-script)

## Basic User Creation

Related documentation:
- [New-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/new-aduser)
- [ConvertTo-SecureString](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/convertto-securestring)

Let's start with the simplest form of creating a new user in Active Directory using PowerShell. The minimum required properties are:
- SamAccountName
- UserPrincipalName
- Name
- GivenName
- Surname
- AccountPassword

```powershell
# Basic user creation
New-ADUser `
    -SamAccountName "john.doe" `
    -UserPrincipalName "john.doe@domain.com" `
    -Name "John Doe" `
    -GivenName "John" `
    -Surname "Doe" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
    -Enabled $true
```

## Advanced User Creation

Now let's add more properties and organize the code better:

```powershell
# Advanced user creation with additional properties
$userProperties = @{
    SamAccountName       = "john.doe"
    UserPrincipalName   = "john.doe@domain.com"
    Name                = "John Doe"
    GivenName           = "John"
    Surname            = "Doe"
    DisplayName        = "John Doe"
    Description        = "Sales Department"
    Office             = "New York"
    Company            = "Contoso Ltd"
    Department         = "Sales"
    Title              = "Sales Representative"
    City               = "New York"
    Country            = "US"
    AccountPassword    = (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force)
    Enabled            = $true
    ChangePasswordAtLogon = $true
}

New-ADUser @userProperties
```

## User Existence Check

Related documentation:
- [Get-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-aduser)

Before creating a user, it's good practice to check if they already exist:

```powershell
function Test-ADUserExists {
    param(
        [Parameter(Mandatory)]
        [string]$SamAccountName
    )
    
    try {
        $user = Get-ADUser -Identity $SamAccountName
        return $true
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        return $false
    }
    catch {
        Write-Error "Error checking user existence: $_"
        return $false
    }
}

# Usage example with try-catch
$samAccountName = "john.doe"

try {
    if (Test-ADUserExists -SamAccountName $samAccountName) {
        Write-Warning "User $samAccountName already exists!"
    }
    else {
        New-ADUser @userProperties
        Write-Host "User $samAccountName created successfully!" -ForegroundColor Green
    }
}
catch {
    Write-Error "Error creating user: $_"
}
```

## Password Generation

Here's a function to generate random, complex passwords:

```powershell
function New-RandomPassword {
    param(
        [int]$Length = 12,
        [int]$SpecialChars = 2,
        [int]$Numbers = 2
    )
    
    # Character sets
    $lowercase = 'abcdefghijklmnopqrstuvwxyz'
    $uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    $numbers = '0123456789'
    $special = '!@#$%^&*()_+-=[]{}|;:,.<>?'
    
    # Initialize password
    $password = @()
    
    # Add required special characters
    for ($i = 0; $i -lt $SpecialChars; $i++) {
        $password += $special[(Get-Random -Maximum $special.Length)]
    }
    
    # Add required numbers
    for ($i = 0; $i -lt $Numbers; $i++) {
        $password += $numbers[(Get-Random -Maximum $numbers.Length)]
    }
    
    # Fill the rest with letters
    $lettersNeeded = $Length - $SpecialChars - $Numbers
    for ($i = 0; $i -lt $lettersNeeded; $i++) {
        if ((Get-Random -Maximum 2) -eq 0) {
            $password += $lowercase[(Get-Random -Maximum $lowercase.Length)]
        }
        else {
            $password += $uppercase[(Get-Random -Maximum $uppercase.Length)]
        }
    }
    
    # Shuffle the password
    $password = ($password | Get-Random -Count $password.Count)
    
    return -join $password
}
```

## Username Generation

Function to generate standardized usernames:

```powershell
function New-StandardUsername {
    param(
        [Parameter(Mandatory)]
        [string]$GivenName,
        [string]$MiddleName = '',
        [Parameter(Mandatory)]
        [string]$Surname,
        [Parameter(Mandatory)]
        [string]$Domain
    )
    
    # Function to normalize special characters
    function Convert-SpecialCharacters {
        param([string]$InputString)
        
        $replacements = @{
            'ø' = 'o'
            'æ' = 'ae'
            'å' = 'a'
            'é' = 'e'
            'è' = 'e'
            'ê' = 'e'
            'ë' = 'e'
            'à' = 'a'
            'á' = 'a'
            'â' = 'a'
            'ä' = 'a'
            'ì' = 'i'
            'í' = 'i'
            'î' = 'i'
            'ï' = 'i'
            'ò' = 'o'
            'ó' = 'o'
            'ô' = 'o'
            'ö' = 'o'
            'ù' = 'u'
            'ú' = 'u'
            'û' = 'u'
            'ü' = 'u'
            'ý' = 'y'
            'ÿ' = 'y'
            'ñ' = 'n'
        }
        
        $normalizedString = $InputString.ToLower()
        foreach ($key in $replacements.Keys) {
            $normalizedString = $normalizedString.Replace($key, $replacements[$key])
        }
        
        return $normalizedString
    }
    
    # Clean and normalize input
    $GivenName = Convert-SpecialCharacters -InputString $GivenName.Trim()
    $MiddleName = Convert-SpecialCharacters -InputString $MiddleName.Trim()
    $Surname = Convert-SpecialCharacters -InputString $Surname.Trim()
    
    # Generate username (givenName.middleInitial.surname@domain.com)
    $middleInitial = if ($MiddleName) { ".$($MiddleName.Substring(0,1))." } else { "." }
    $username = "$GivenName$middleInitial$Surname@$Domain"
    
    # Remove any special characters and replace spaces
    $username = $username -replace '[^a-zA-Z0-9@._-]', ''
    
    # Ensure the local part (before @) is not longer than 20 characters
    $parts = $username -split '@'
    if ($parts[0].Length -gt 20) {
        $parts[0] = $parts[0].Substring(0, 20)
        $username = "$($parts[0])@$($parts[1])"
    }
    
    return $username
}
```

## Bulk User Creation from CSV

Related documentation:
- [Import-Csv](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/import-csv)
- [Out-File](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/out-file)

Example CSV format:
```
GivenName,MiddleName,Surname,Department,Title,Office
John,Robert,Doe,Sales,Sales Rep,New York
Jane,Marie,Smith,Marketing,Marketing Manager,Chicago
```

Script to process the CSV:

```powershell
function New-BulkADUsers {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,
        [Parameter(Mandatory)]
        [string]$Domain,
        [Parameter(Mandatory)]
        [string]$BasePath,  # Example: "OU=Users,DC=domain,DC=com"
        [string]$LogPath = "user_creation_log.txt"
    )
    
    # Import CSV
    $users = Import-Csv -Path $CsvPath
    
    # Initialize log
    $log = @()
    
    foreach ($user in $users) {
        try {
            # Generate username
            $upn = New-StandardUsername -GivenName $user.GivenName `
                                      -MiddleName $user.MiddleName `
                                      -Surname $user.Surname `
                                      -Domain $Domain
            
            $samAccountName = ($upn -split '@')[0]
            
            # Check if user exists
            if (Test-ADUserExists -SamAccountName $samAccountName) {
                $log += "SKIP: User $samAccountName already exists"
                continue
            }
            
            # Generate random password
            $password = New-RandomPassword
            
            # Prepare user properties
            $userProperties = @{
                SamAccountName       = $samAccountName
                UserPrincipalName   = $upn
                Name                = "$($user.GivenName) $($user.Surname)"
                GivenName           = $user.GivenName
                Surname            = $user.Surname
                DisplayName        = "$($user.GivenName) $($user.Surname)"
                Department         = $user.Department
                Title              = $user.Title
                Office             = $user.Office
                AccountPassword    = (ConvertTo-SecureString $password -AsPlainText -Force)
                Enabled            = $true
                ChangePasswordAtLogon = $true
            }
            
            # Get appropriate OU path
            $ouPath = Get-DepartmentOUPath -Department $user.Department `
                                         -BasePath $BasePath `
                                         -CreateIfNotExist
            
            # Add OU path to user properties
            $userProperties['Path'] = $ouPath
            
            # Create user
            New-ADUser @userProperties
            $log += "SUCCESS: Created user $samAccountName in OU $ouPath with password: $password"
        }
        catch {
            $log += "ERROR: Failed to create user from record: $($user.GivenName) $($user.Surname). Error: $_"
        }
    }
    
    # Save log
    $log | Out-File -FilePath $LogPath
}

# Usage example
$basePath = "OU=Users,DC=domain,DC=com"
New-BulkADUsers -CsvPath "users.csv" -Domain "domain.com" -BasePath $basePath
```

## Updating User Properties

Related documentation:
- [Set-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser)

Here's how to update existing user properties using Set-ADUser:

```powershell
# Basic property update
Set-ADUser -Identity "john.doe" -Office "London" -Title "Senior Sales Representative"

# Multiple properties update using a hash table
$updateProperties = @{
    Office      = "London"
    Title       = "Senior Sales Representative"
    Department  = "Global Sales"
    Description = "Updated role 2024"
}

Set-ADUser -Identity "john.doe" @updateProperties

# Update user's manager
Set-ADUser -Identity "john.doe" -Manager "jane.smith"

# Enable or disable account
Set-ADUser -Identity "john.doe" -Enabled $false

# Force password change at next logon
Set-ADUser -Identity "john.doe" -ChangePasswordAtLogon $true
```

## OU Path Management

Related documentation:
- [Get-ADOrganizationalUnit](https://learn.microsoft.com/en-us/powershell/module/activedirectory/get-adorganizationalunit)

Here's a function to get or create the correct OU path based on department:

```powershell
function Get-DepartmentOUPath {
    param(
        [Parameter(Mandatory)]
        [string]$Department,
        [Parameter(Mandatory)]
        [string]$BasePath,  # Example: "OU=Users,DC=domain,DC=com"
        [switch]$CreateIfNotExist
    )
    
    try {
        # Clean department name
        $departmentOU = $Department.Trim()
        
        # Construct full OU path
        $ouPath = "OU=$departmentOU,$BasePath"
        
        # Try to get the OU
        try {
            $null = Get-ADOrganizationalUnit -Identity $ouPath
            Write-Verbose "Found existing OU: $ouPath"
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            if ($CreateIfNotExist) {
                # Create new OU if it doesn't exist
                New-ADOrganizationalUnit -Name $departmentOU -Path $BasePath
                Write-Verbose "Created new OU: $ouPath"
            }
            else {
                Write-Warning "OU does not exist: $ouPath"
                return $BasePath
            }
        }
        
        return $ouPath
    }
    catch {
        Write-Error "Error processing OU path: $_"
        return $BasePath
    }
}

# Usage example:
$basePath = "OU=Users,DC=domain,DC=com"
$ouPath = Get-DepartmentOUPath -Department "IT" -BasePath $basePath -CreateIfNotExist
```

## Cleanup Script

Related documentation:
- [Remove-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/remove-aduser)

Use this script to remove users created from the CSV file:

```powershell
function Remove-BulkADUsers {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,
        [Parameter(Mandatory)]
        [string]$Domain,
        [string]$LogPath = "user_removal_log.txt"
    )
    
    # Import CSV
    $users = Import-Csv -Path $CsvPath
    $log = @()
    
    foreach ($user in $users) {
        try {
            # Generate the same username as creation
            $upn = New-StandardUsername -GivenName $user.GivenName `
                                      -MiddleName $user.MiddleName `
                                      -Surname $user.Surname `
                                      -Domain $Domain
            
            $samAccountName = ($upn -split '@')[0]
            
            # Check if user exists
            if (Test-ADUserExists -SamAccountName $samAccountName) {
                Remove-ADUser -Identity $samAccountName -Confirm:$false
                $log += "SUCCESS: Removed user $samAccountName"
            }
            else {
                $log += "SKIP: User $samAccountName does not exist"
            }
        }
        catch {
            $log += "ERROR: Failed to remove user $samAccountName. Error: $_"
        }
    }
    
    # Save log
    $log | Out-File -FilePath $LogPath
}

# Usage example
Remove-BulkADUsers -CsvPath "users.csv" -Domain "domain.com"
```

This script will remove all users that were created using the same CSV file, making it easy to clean up after testing or training sessions.

Remember to always test these scripts in a non-production environment first!