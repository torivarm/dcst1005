# Root folder for the project
$rootFolder = "C:\git-projects\dcst1005\dcst1005\"
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
# CSV-file with users
$users = Import-Csv -Path "$rootFolder\02-03-tmp_csv-users-example.csv" -Delimiter ","

foreach ($user in $users) {
    # Retrieve the user's department
    $department = $user.Department

    $newNames = Convert-SpecialCharacters -givenName $user.givenName -surName $user.surName
    $newusername = New-Username -givenName $newNames.ConvertedGivenName -surName $newNames.ConvertedSurName




    # Determine the AD group based on the department
    # This is an example. Modify it according to your group naming convention and departments
    $groupName = "g_" + $department

    try {
        # Get the AD user object
        $ADuser = Get-ADUser -filter * -Properties samAccountName, department | Where-Object {$_.samaccountname -eq $newusername}
        $groupname = "g_" + $ADuser.Department

        # Add the user to the group
        Add-ADGroupMember -Identity $groupName -Members $adUser.SamAccountName -ErrorAction Stop

        Write-Host "Added user $($adUser.Name) to group $groupName." -ForegroundColor Green
    } catch {
        Write-Host "Error adding user $($ADuser.Name) to group $groupName." -ForegroundColor red
    }
}

Write-Host "Process completed."