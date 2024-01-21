# Functions: Convert-SpecialCharacters, New-Username, New-UserPrincipalName, New-Password, Get-UserOU
function Convert-SpecialCharacters {
    param(
        [string]$givenName,
        [string]$surName
    )

    # Function to replace special characters in a string
    function New-Characters {
        param(
            [string]$inputString
        )

        # Define replacements
        $replacements = @{
            'ø' = 'o';
            'å' = 'a';
            'æ' = 'ae';
            'é' = 'e'
        }

        # Perform replacements
        foreach ($key in $replacements.Keys) {
            $inputString = $inputString.Replace($key, $replacements[$key])
        }

        return $inputString
    }

    # Apply replacements to givenName and surName
    $convertedGivenName = New-Characters -inputString $givenName.ToLower()
    $convertedSurName = New-Characters -inputString $surName.ToLower()

    # Return the converted names
    return @{
        ConvertedGivenName = $convertedGivenName;
        ConvertedSurName = $convertedSurName
    }
}
function New-Username {
    param(
        [string]$givenName,
        [string]$surName
    )

    # Ensure that the names are trimmed to remove any extra whitespace
    $givenName = $givenName.Trim()
    $surName = $surName.Trim()

    # Initialize variables to hold the parts of the username
    $givenNamePart = ""
    $surNamePart = ""

    # Determine the givenName part
    if ($givenName.Length -lt 3) {
        $givenNamePart = $givenName
    } else {
        $givenNamePart = $givenName.Substring(0, 3)
        $givenNamePart = $givenNamePart.Trim()
    }

    # Determine the surName part
    if ($surName.Length -lt 3) {
        $surNamePart = $surName
    } else {
        $surNamePart = $surName.Substring(0, 3)
        $surNamePart = $surNamePart.Trim()
    }

    # Combine to form the username
    $userName = $givenNamePart + $surNamePart

    return $userName.ToLower() # Converting to lower case for standardization

    return $userName
}
function New-UserPrincipalName {
    param (
        [Parameter(Mandatory=$true)][string] $givenName,
        [Parameter(Mandatory=$true)][string] $surName
    )

    if ($givenName -match $([char]32)) {
        $splitted = $givenName.Split($([char]32))
        $givenName = $splitted[0]

        for ( $index = 1 ; $index -lt $splitted.Length ; $index ++ ) {
            $givenName += ".$($splitted[$index][0])"
        }
    }

    $UserPrincipalName = $("$($givenName).$($surName)").ToLower()

    Return $UserPrincipalName

}
function New-Password {
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
function Get-UserOU {
    param(
        [string]$department,
        [string]$rootOUusers

    )

    [string] $searchdn = "OU=$department,OU=$rootOUusers,*"
    $ouPath = Get-ADOrganizationalUnit -Filter * | Where-Object {($_.name -eq $department) -and ($_.DistinguishedName -like $searchdn)} 
    
    return $ouPath
}

$rootFolder = "/Users/melling/git-projects/dcst1005/"

# CSV-file with users
$Users = Import-Csv -Path "$rootFolder/tmp_csv-users-example.csv" -Delimiter ","

# Initialize arrays to store the results
$usersCreated = @()
$usersNotCreated = @()

foreach ($user in $users) {
    $newNames = Convert-SpecialCharacters -givenName $user.givenName -surName $user.surName
    Write-Host $newNames.ConvertedGivenName -ForegroundColor Green
    Write-Host $newNames.ConvertedSurName -ForegroundColor Green

    $newusername = New-Username -givenName $newNames.ConvertedGivenName -surName $newNames.ConvertedSurName
    Write-Host $newusername -ForegroundColor Cyan

    $upn = New-UserPrincipalName -givenName $newNames.ConvertedGivenName -surName $newNames.ConvertedSurName
    Write-Host $upn -ForegroundColor DarkYellow

    $password = New-Password
    Write-Host $password -ForegroundColor DarkGreen

    # Only works if the OU already exists and names in CSV-file are correct / matching AD structure
    $ou = Get-UserOU -department $user.Department -rootOUusers "InfraIT_Users"
    Write-Host $ou -ForegroundColor DarkMagenta

    # Check if a user with this samAccountName or UserPrincipalName already exists in AD
    $existingUser = Get-ADUser -Filter "samAccountName -eq '$newusername' -or UserPrincipalName -eq '$upn'" -ErrorAction SilentlyContinue

    if ($existingUser) {
        Write-Host "User $newusername already exists" -ForegroundColor Red
        $usersNotCreated += $user
        } 
        else {
            try {
                # Attempt to create the new user
                Write-Host "Creating user $newusername" -ForegroundColor Green
                New-ADUser -SamAccountName $newusername `
                            -UserPrincipalName $upn `
                            -Name "$($user.givenName) $($user.surName)" `
                            -GivenName $user.givenName `
                            -Surname $user.surName `
                            -Enabled $true `
                            -DisplayName "$($user.givenName) $($user.surName)" `
                            -Department $user.Department `
                            -Path $ou.DistinguishedName `
                            -AccountPassword $password
                $usersCreated += $user
                }
                catch {
                    Write-Host "Failed to create user $newusername" -ForegroundColor Red
                    $usersNotCreated += $user
                }
        }       
}

# Export the results to CSV files
$usersCreated | Export-Csv "$rootFolder/users_created.csv" -NoTypeInformation -Encoding UTF8
$usersNotCreated | Export-Csv "$rootFolder/users_not_created.csv" -NoTypeInformation -Encoding utf8

Write-Host "Export complete. Users created: $($usersCreated.Count). Users not created: $($usersNotCreated.Count)."


