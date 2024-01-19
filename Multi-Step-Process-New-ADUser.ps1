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
    $convertedGivenName = New-Characters -inputString $givenName
    $convertedSurName = New-Characters -inputString $surName

    # Return the converted names
    return @{
        ConvertedGivenName = $convertedGivenName;
        ConvertedSurName = $convertedSurName
    }
}
function Get-Username {
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
    #$UserPrincipalName = $UserPrincipalName.Replace('æ','e')
    #$UserPrincipalName = $UserPrincipalName.Replace('ø','o')
    #$UserPrincipalName = $UserPrincipalName.Replace('å','a')
    #$UserPrincipalName = $UserPrincipalName.Replace('é','e')

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



# Example usage
# $names = Convert-SpecialCharacters -givenName "Per Jørgen" -surName "Bråten"
# Write-Host "Converted Given Name: $($names.ConvertedGivenName), Converted Sur Name: $($names.ConvertedSurName)"

# Example usage
# $username = Get-Username -givenName $names.ConvertedGivenName -surName $names.ConvertedSurName
# Write-Host "Generated username: $username"

# Example usage
# $upn = New-UserPrincipalName -givenName $names.ConvertedGivenName -surName $names.ConvertedSurName
# Write-Host "Generated UPN: $upn"

# Example usage
# $securePassword = New-Password
# Write-Host "Generated password is a SecureString"


$Users = Import-Csv -Path "/Users/melling/git-projects/dcst1005/tmp_csv-users-example.csv" -Header "FirstName","LastName","Department","phone" -Delimiter ","


$username
$upn
$securePassword



