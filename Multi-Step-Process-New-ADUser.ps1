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
    if ($givenName.Length -lt 4) {
        $givenNamePart = $givenName
    } else {
        $givenNamePart = $givenName.Substring(0, 4)
    }

    # Determine the surName part
    if ($surName.Length -lt 4) {
        $surNamePart = $surName
    } else {
        $surNamePart = $surName.Substring(0, 4)
    }

    # Combine to form the username
    $userName = $givenNamePart + $surNamePart

    return $userName.ToLower() # Converting to lower case for standardization

    return $userName
}
function Get-UserPrincipalName {
    param(
        [string]$givenName,
        [string]$surName,
        [string]$domainName
    )

    # Remove extra whitespace and split the givenName into parts
    $givenNameParts = $givenName.Trim().Split(' ')

    # Initialize the UPN with the first part of the givenName
    $upn = $givenNameParts[0].ToLower()

    # Process middle names, if any
    if ($givenNameParts.Length -gt 1) {
        for ($i = 1; $i -lt $givenNameParts.Length; $i++) {
            $middleNameInitial = $givenNameParts[$i].Substring(0, 1).ToLower()
            $upn += ".$middleNameInitial"
        }
    }

    # Add the surName and the domain name
    $upn += ".$surName@$domainName".ToLower()

    return $upn
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
# $securePassword = New-Password
# Write-Host "Generated password is a SecureString"

# Example usage
# $upn = Get-UserPrincipalName -givenName "Tor Ivar" -surName "melling" -domainName "infrait.sec"
# Write-Host "Generated UPN: $upn"

# Example usage
# $username = Get-Username -givenName "Tor Ivar" -surName "Melling"
# Write-Host "Generated username: $username"


$username
$upn
$securePassword