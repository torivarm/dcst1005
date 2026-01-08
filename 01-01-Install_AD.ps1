# Install Active Directory Domain Services (AD DS)
# Needs to be run as Administrator

# Install AD DS and DNS with error handling
try {

    Write-Host "Installerer AD DS og DNS..." -ForegroundColor Cyan
    Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools -ErrorAction Stop
    Write-Host "Installasjon fullført!" -ForegroundColor Green

}

catch {

    Write-Error "Feil under installasjon av AD DS: $_"
    exit 1

}

# Function to validate password complexity
function Test-PasswordComplexity {
    param(
        [string]$Password
    )
    
    $hasMinLength = $Password.Length -ge 12
    $hasUpperCase = $Password -cmatch '[A-Z]'
    $hasLowerCase = $Password -cmatch '[a-z]'
    $hasNumber = $Password -match '[0-9]'
    $hasSpecialChar = $Password -match '[^a-zA-Z0-9]'
    
    $isValid = $hasMinLength -and $hasUpperCase -and $hasLowerCase -and $hasNumber -and $hasSpecialChar
    
    if (-not $isValid) {

        Write-Host "`nPassordet oppfyller ikke kravene:" -ForegroundColor Red
        if (-not $hasMinLength) { Write-Host "  - Må være minst 12 tegn" -ForegroundColor Yellow }
        if (-not $hasUpperCase) { Write-Host "  - Må inneholde store bokstaver (A-Z)" -ForegroundColor Yellow }
        if (-not $hasLowerCase) { Write-Host "  - Må inneholde små bokstaver (a-z)" -ForegroundColor Yellow }
        if (-not $hasNumber) { Write-Host "  - Må inneholde tall (0-9)" -ForegroundColor Yellow }
        if (-not $hasSpecialChar) { Write-Host "  - Må inneholde spesialtegn (!@#$%^&* etc.)" -ForegroundColor Yellow }
    
    }
    
    return $isValid

}

# Get DSRM password with complexity validation
Write-Host "`nPassordkrav:" -ForegroundColor Cyan
Write-Host "  - Minst 12 tegn" -ForegroundColor White
Write-Host "  - Store bokstaver (A-Z)" -ForegroundColor White
Write-Host "  - Små bokstaver (a-z)" -ForegroundColor White
Write-Host "  - Tall (0-9)" -ForegroundColor White
Write-Host "  - Spesialtegn (!@#$%^&* etc.)" -ForegroundColor White
Write-Host ""

do {
    
    $Password = Read-Host -Prompt 'Oppgi DSRM-passord' -AsSecureString
    
    # Convert to plain text for validation (will be cleared after)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $PasswordPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    $isValid = Test-PasswordComplexity -Password $PasswordPlain
    
    # Clear plain text password from memory immediately
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    $PasswordPlain = $null
    
    if (-not $isValid) {
        Write-Host "`nVennligst prøv igjen.`n" -ForegroundColor Red
    }
} while (-not $isValid)

Write-Host "`nPassord godkjent!" -ForegroundColor Green

# Define parameters using splatting
$Params = @{
    DomainMode = 'Win2025'
    DomainName = 'InfraIT.sec'
    DomainNetbiosName = 'InfraIT'
    ForestMode = 'Win2025'
    InstallDns = $true
    NoRebootOnCompletion = $true
    SafeModeAdministratorPassword = $Password
    Force = $true
}

try {
    Write-Host "`nSetter oppgitt passord på lokal Administrator-bruker..." -ForegroundColor Cyan
    Set-LocalUser -Password $Password Administrator
    Write-Host "`nPassord satt på lokal Administrator-bruker..." -ForegroundColor Cyan
}
catch {
    Write-Error "Feil ved passordkonfigurasjon på lokal Administrator-bruke"
    exit 1
}

# Install AD DS with error handling
try {
    Write-Host "`nPromoverer server til Domain Controller..." -ForegroundColor Cyan
    Write-Host "Dette kan ta 5-10 minutter..." -ForegroundColor Yellow

    Install-ADDSForest @Params -ErrorAction Stop

    Write-Host "`nDomain Controller-promovering fullført!" -ForegroundColor Green
    Write-Host "Serveren restarter om 10 sekunder..." -ForegroundColor Yellow
    Write-Host "`nETTER RESTART:" -ForegroundColor Cyan
    Write-Host "  Logg inn med: InfraIT\Administrator" -ForegroundColor White
    Write-Host "  Bruk passordet du nettopp oppga" -ForegroundColor White

    Start-Sleep -Seconds 10

    Restart-Computer -Force
}
catch {
    Write-Error "Feil under promovering til Domain Controller: $_"
    exit 1
}