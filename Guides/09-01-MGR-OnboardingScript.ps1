#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Azure Arc Onboarding Script - Må kjøres som Administrator
.DESCRIPTION
    Dette scriptet installerer og konfigurerer Azure Connected Machine Agent.
    VIKTIG: Kjør dette scriptet fra et elevated PowerShell-vindu (Run as Administrator)
.NOTES
    Domene: InfraIT.sec
    Ressurs: mgr-tim84
#>

try {
    Write-Host "`n=== Azure Arc Onboarding ===" -ForegroundColor Cyan
    Write-Host "Ressursnavn: mgr-tim84`n" -ForegroundColor Cyan
    
    # Azure Arc konfigurasjonsvariabler
    $subscriptionId = "65ca203a-2678-4881-b207-60ace77cc450"
    $resourceGroup = "rg-infraitsec-arc-melling"
    $tenantId = "ec25d615-a67b-411a-9073-de7880b3b8a3"
    $location = "northeurope"
    $cloud = "AzureCloud"
    $correlationId = "f73ab9b9-1278-422a-a59a-114d7d1d3f5c"
    
    # Maskin-spesifikk konfigurasjon
    $resourceName = "mgr-tim84"
    $tags = "Datacenter=NTNU,City=Gjøvik,CountryOrRegion=Norway,Owner=tor.i.melling@ntnu.no,Project=infrait-lab,CostCenter=lab,Comments=Testing of Azure Arc, will be deleted after testing"
    
    # Sett miljøvariabler for logging
    $env:SUBSCRIPTION_ID = $subscriptionId
    $env:RESOURCE_GROUP = $resourceGroup
    $env:TENANT_ID = $tenantId
    $env:LOCATION = $location
    $env:AUTH_TYPE = "token"
    $env:CORRELATION_ID = $correlationId
    $env:CLOUD = $cloud
    
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
    
    # Opprett mapper for Azure Connected Machine Agent
    $azcmagentPath = Join-Path $env:SystemRoot "AzureConnectedMachineAgent"
    if (-Not (Test-Path -Path $azcmagentPath)) {
        New-Item -Path $azcmagentPath -ItemType Directory | Out-Null
        Write-Host "[OK] Opprettet mappe: $azcmagentPath" -ForegroundColor Green
    }
    
    $tempPath = Join-Path $azcmagentPath "temp"
    if (-Not (Test-Path -Path $tempPath)) {
        New-Item -Path $tempPath -ItemType Directory | Out-Null
        Write-Host "[OK] Opprettet mappe: $tempPath" -ForegroundColor Green
    }
    
    # Last ned og installer Azure Connected Machine Agent
    Write-Host "`n[INFO] Laster ned Azure Connected Machine Agent..." -ForegroundColor Yellow
    $installScriptPath = Join-Path $tempPath "install_windows_azcmagent.ps1"
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/azcmagent-windows" -TimeoutSec 30 -OutFile "$installScriptPath"
    
    Write-Host "[INFO] Installerer Azure Connected Machine Agent..." -ForegroundColor Yellow
    & "$installScriptPath"
    if ($LASTEXITCODE -ne 0) { 
        Write-Host "[FEIL] Installasjon feilet med exit code: $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "[OK] Agent installert" -ForegroundColor Green
    Start-Sleep -Seconds 5
    
    # Bygg kommando-string eksplisitt (LØSNINGEN!)
    Write-Host "`n[INFO] Kobler til Azure Arc..." -ForegroundColor Yellow
    Write-Host "Ressursnavn som brukes: $resourceName" -ForegroundColor Cyan
    
    $azcmagentExe = "$env:ProgramW6432\AzureConnectedMachineAgent\azcmagent.exe"
    
    # Bygg argument-string med Start-Process for bedre kontroll
    $argumentList = "connect " +
                   "--resource-group `"$resourceGroup`" " +
                   "--tenant-id `"$tenantId`" " +
                   "--location `"$location`" " +
                   "--resource-name `"$resourceName`" " +
                   "--subscription-id `"$subscriptionId`" " +
                   "--cloud `"$cloud`" " +
                   "--tags `"$tags`" " +
                   "--correlation-id `"$correlationId`""
    
    Write-Host "`nKommando som kjøres:" -ForegroundColor Gray
    Write-Host "$azcmagentExe $argumentList`n" -ForegroundColor Gray
    
    # Kjør med Start-Process for full kontroll over argumenter
    $process = Start-Process -FilePath $azcmagentExe `
                            -ArgumentList $argumentList `
                            -Wait `
                            -NoNewWindow `
                            -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host "`n[OK] Azure Arc onboarding fullført!" -ForegroundColor Green
        Write-Host "Ressursnavn: $resourceName" -ForegroundColor Green
        Write-Host "`nVerifiser i Azure Portal:" -ForegroundColor Cyan
        Write-Host "Resource Group: $resourceGroup" -ForegroundColor White
        Write-Host "Resource Name: $resourceName" -ForegroundColor White
    } elseif ($process.ExitCode -eq 67) {
        Write-Host "`n[ADVARSEL] Maskinen er allerede koblet til Azure Arc" -ForegroundColor Yellow
        Write-Host "For å koble til på nytt med nytt navn, kjør følgende kommandoer:" -ForegroundColor Cyan
        Write-Host "& '$azcmagentExe' disconnect" -ForegroundColor White
        Write-Host "net stop himds" -ForegroundColor White
        Write-Host "net start himds" -ForegroundColor White
        Write-Host "Deretter kjør dette scriptet på nytt." -ForegroundColor Cyan
    } else {
        Write-Host "`n[FEIL] Azure Arc onboarding feilet med exit code: $($process.ExitCode)" -ForegroundColor Red
    }
}
catch {
    $logBody = @{
        subscriptionId = $subscriptionId
        resourceGroup = $resourceGroup
        tenantId = $tenantId
        location = $location
        correlationId = $correlationId
        authType = "token"
        operation = "onboarding"
        messageType = $_.FullyQualifiedErrorId
        message = "$_"
    }
    Invoke-WebRequest -UseBasicParsing -Uri "https://gbl.his.arc.azure.com/log" -Method "PUT" -Body ($logBody | ConvertTo-Json) | Out-Null
    Write-Host "`n[FEIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}