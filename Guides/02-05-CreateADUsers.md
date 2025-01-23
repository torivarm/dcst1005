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
  - [Cleanup Script](#cleanup-script)
  - [OU Path Management](#ou-path-management)
  - [Bulk User Creation from CSV WITH OU PATH](#bulk-user-creation-from-csv-with-ou-path)

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
    -SamAccountName "melling" `
    -UserPrincipalName "tor.i.melling@infrait.sec" `
    -Name "Tor Ivar Melling" `
    -GivenName "Tor" `
    -Surname "Ivar" `
    -AccountPassword (ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force) `
    -Enabled $true
```

## Advanced User Creation

Now let's add more properties and organize the code better:

```powershell
# Advanced user creation with additional properties
$userProperties = @{
    SamAccountName       = "melling"
    UserPrincipalName   = "tor.i.melling@infrait.sec"
    Name                = "Tor Ivar Melling"
    GivenName           = "Tor Ivar"
    Surname            = "Melling"
    DisplayName        = "Tor Ivar Melling"
    Description        = "IT department"
    Office             = "Trondheim"
    Company            = "InfraIT Sec"
    Department         = "IT"
    Title              = "IT admin"
    City               = "Trondheim"
    Country            = "NO"
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
$samAccountName = "melling"

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
    # Character sets
    $lowerCase = "abcdefghijklmnopqrstuvwxyz"
    $upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $numbers = "0123456789"
    # Safe special characters based on common practices
    $specialChars = "!@#$%^&*()-_=+[]{}|;:,.<>?"

    # Combined character set
    $allChars = $lowerCase + $upperCase + $numbers + $specialChars

    # Random password length between 13 and 17
    $passwordLength = Get-Random -Minimum 13 -Maximum 18

    # Creating an array to hold password characters
    $passwordChars = @()

    # Ensuring at least one character from each set
    $passwordChars += $lowerCase.ToCharArray()[(Get-Random -Maximum $lowerCase.Length)]
    $passwordChars += $upperCase.ToCharArray()[(Get-Random -Maximum $upperCase.Length)]
    $passwordChars += $numbers.ToCharArray()[(Get-Random -Maximum $numbers.Length)]
    $passwordChars += $specialChars.ToCharArray()[(Get-Random -Maximum $specialChars.Length)]

    # Filling the rest of the password
    for ($i = $passwordChars.Count; $i -lt $passwordLength; $i++) {
        $passwordChars += $allChars.ToCharArray()[(Get-Random -Maximum $allChars.Length)]
    }

    # Shuffle the characters to remove predictable patterns
    $password = -join ($passwordChars | Get-Random -Count $passwordChars.Count)

    # Convert to SecureString
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

    return $securePassword
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
            
            # Create user
            New-ADUser @userProperties
            $log += "SUCCESS: Created user $samAccountName with password: $password"
        }
        catch {
            $log += "ERROR: Failed to create user from record: $($user.GivenName) $($user.Surname). Error: $_"
        }
    }
    
    # Save log
    $log | Out-File -FilePath $LogPath
}

# Usage example
New-BulkADUsers -CsvPath "users.csv" -Domain "domain.com"
```

## Updating User Properties

Related documentation:
- [Set-ADUser](https://learn.microsoft.com/en-us/powershell/module/activedirectory/set-aduser)

Here's how to update existing user properties using Set-ADUser:

```powershell
# Basic property update
Set-ADUser -Identity "melling" -Office "London" -Title "Senior IT Consultant"

# Multiple properties update using a hash table
$updateProperties = @{
    Office      = "London"
    Title       = "Senior IT Consultant"
    Department  = "IT"
    Description = "Updated role 2024"
}

Set-ADUser -Identity "melling" @updateProperties

# Update user's manager
Set-ADUser -Identity "melling" -Manager "Kari Nordmann"

# Enable or disable account
Set-ADUser -Identity "melling" -Enabled $false

# Force password change at next logon
Set-ADUser -Identity "melling" -ChangePasswordAtLogon $true
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

## Bulk User Creation from CSV WITH OU PATH

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