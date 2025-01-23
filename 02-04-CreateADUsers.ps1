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