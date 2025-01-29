# Function to get groups and their members from a specific OU
function Get-GroupsAndMembers {
    param (
        [Parameter(Mandatory=$true)]
        [string]$OUPath,
        [Parameter(Mandatory=$true)]
        [string]$GroupType
    )

    Write-Host "`n=== $GroupType Groups in $OUPath ===" -ForegroundColor Cyan

    try {
        # Get all groups in the specified OU
        $groups = Get-ADGroup -Filter * -SearchBase $OUPath -Properties Members, Description
        
        if ($groups) {
            foreach ($group in $groups) {
                Write-Host "`nGroup: $($group.Name)" -ForegroundColor Green
                Write-Host "Description: $($group.Description)"
                Write-Host "Distinguished Name: $($group.DistinguishedName)"
                
                # Get group members
                $members = Get-ADGroupMember -Identity $group.DistinguishedName
                
                if ($members) {
                    Write-Host "Members:" -ForegroundColor Yellow
                    foreach ($member in $members) {
                        # Get additional user/group properties
                        if ($member.objectClass -eq "user") {
                            $details = Get-ADUser -Identity $member.SamAccountName -Properties DisplayName, Title, Department
                            Write-Host "  - $($details.DisplayName) ($($details.SamAccountName))"
                            Write-Host "    Title: $($details.Title)"
                            Write-Host "    Department: $($details.Department)"
                        }
                        else {
                            Write-Host "  - $($member.Name) (Group)"
                        }
                    }
                }
                else {
                    Write-Host "No members found in this group." -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Host "No groups found in this OU." -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error accessing OU $OUPath : $_" -ForegroundColor Red
    }
}

# Function to export results to CSV
function Export-GroupMembership {
    param (
        [Parameter(Mandatory=$true)]
        [string]$OUPath,
        [Parameter(Mandatory=$true)]
        [string]$OutputFile
    )

    try {
        $results = @()
        $groups = Get-ADGroup -Filter * -SearchBase $OUPath -Properties Members, Description

        foreach ($group in $groups) {
            $members = Get-ADGroupMember -Identity $group.DistinguishedName
            
            foreach ($member in $members) {
                $memberDetails = @{
                    'GroupName' = $group.Name
                    'GroupDescription' = $group.Description
                    'MemberName' = $member.Name
                    'MemberType' = $member.objectClass
                    'MemberSAM' = $member.SamAccountName
                }

                if ($member.objectClass -eq "user") {
                    $userDetails = Get-ADUser -Identity $member.SamAccountName -Properties DisplayName, Title, Department
                    $memberDetails['MemberTitle'] = $userDetails.Title
                    $memberDetails['MemberDepartment'] = $userDetails.Department
                }

                $results += New-Object PSObject -Property $memberDetails
            }
        }

        $results | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-Host "Results exported to $OutputFile" -ForegroundColor Green
    }
    catch {
        Write-Host "Error exporting results: $_" -ForegroundColor Red
    }
}

# Main script !!! Make sure to edit the path to match your AD Infrastructure
# Correct path is found with this command: Get-ADOrganizationalUnit -filter * | ft
$globalGroupsOU = "OU=Global,OU=InfraIT_Groups,DC=InfraIT,DC=sec"  # Add your Global Groups OU path here
$localGroupsOU = "OU=Local,OU=InfraIT_Groups,DC=InfraIT,DC=sec"   # Add your Local Groups OU path here

# Verify both global and local groups
Get-GroupsAndMembers -OUPath $globalGroupsOU -GroupType "Global"
Get-GroupsAndMembers -OUPath $localGroupsOU -GroupType "Local"

# Export results to CSV
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
#Export-GroupMembership -OUPath $globalGroupsOU -OutputFile "GlobalGroups_$timestamp.csv"
#Export-GroupMembership -OUPath $localGroupsOU -OutputFile "LocalGroups_$timestamp.csv"