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
