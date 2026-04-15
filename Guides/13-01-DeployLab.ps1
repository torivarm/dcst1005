# =============================================================================
# Deploy-InfraITsec-SecurityLab.ps1
# DCST1005 — InfraIT.sec sikkerhetsvurderingslab
# =============================================================================
# Setter opp infrastrukturen for sikkerhetsvurderingslabben.
#
# Ressurser som opprettes:
#   - Hub med management-subnet og jumpbox
#   - Frontend-spoke med App Service (kundeportal)
#   - Backend-spoke med Storage, Key Vault, SQL og ACR
#   - VNET-peering mellom alle tre nettverkene
#
# ETTER DETTE SCRIPTET:
#   Kjør Deploy-AppService-Portal.sh i Azure Cloud Shell
#   for å deploye innholdet til kundeportalen.
#
# Scriptet er idempotent og kan kjøres flere ganger uten feil.
# =============================================================================

param(
    [string]$Prefix   = "tim84",
    [string]$TenantId = "ec25d615-a67b-411a-9073-de7880b3b8a3"
)

if (-not $Prefix)   { $Prefix   = Read-Host "Skriv inn prefiks (f.eks. on03)" }
if (-not $TenantId) { $TenantId = Read-Host "Skriv inn Tenant ID" }

$prefix   = $Prefix.ToLower().Trim()
$tenantId = $TenantId.Trim()
$location = "norwayeast"
$sqlAdminUser = "sqladmin"
$sqlAdminPass = "InfraIT2024!"

function Write-Status {
    param([string]$Message, [ValidateSet("Created","Exists","Updated","Error")][string]$Status)
    switch ($Status) {
        "Created" { Write-Host "  [NY]         $Message" -ForegroundColor Green }
        "Exists"  { Write-Host "  [EKSISTERER] $Message" -ForegroundColor Yellow }
        "Updated" { Write-Host "  [OPPDATERT]  $Message" -ForegroundColor Cyan }
        "Error"   { Write-Host "  [FEIL]       $Message" -ForegroundColor Red }
    }
}

function Write-Step {
    param([string]$Step, [string]$Message)
    Write-Host "`n[$Step] $Message" -ForegroundColor Cyan
}

function Set-VnetPeering {
    param($Name, $SourceVnet, $TargetVnet, $SourceRg)
    $existing = Get-AzVirtualNetworkPeering `
        -VirtualNetworkName $SourceVnet.Name `
        -ResourceGroupName $SourceRg `
        -Name $Name -ErrorAction SilentlyContinue
    if ($existing -and $existing.PeeringState -eq "Connected") {
        Write-Status "$Name (Connected)" "Exists"; return
    }
    if ($existing) {
        Remove-AzVirtualNetworkPeering `
            -VirtualNetworkName $SourceVnet.Name `
            -ResourceGroupName $SourceRg `
            -Name $Name -Force | Out-Null
    }
    Add-AzVirtualNetworkPeering `
        -Name $Name -VirtualNetwork $SourceVnet `
        -RemoteVirtualNetworkId $TargetVnet.Id | Out-Null
    Write-Status $Name "Created"
}

# --- Autentiser ---
Write-Step "1/11" "Autentiserer mot Azure"
Connect-AzAccount -Tenant $tenantId
$ctx         = Get-AzContext
$currentUser = $ctx.Account.Id
Write-Host "  Innlogget: $currentUser" -ForegroundColor Gray

# --- Navnekonvensjon ---
$rgHub      = "$prefix-rg-infraitsec-hub"
$rgFrontend = "$prefix-rg-infraitsec-frontend"
$rgBackend  = "$prefix-rg-infraitsec-backend"

$hubVnetName      = "$prefix-vnet-hub"
$frontendVnetName = "$prefix-vnet-frontend"
$backendVnetName  = "$prefix-vnet-backend"

$mgmtSubnetName   = "$prefix-snet-management"
$appSvcSubnetName = "$prefix-snet-appsvc"
$dataSubnetName   = "$prefix-snet-data"

$mgmtNsgName    = "$prefix-nsg-management"
$jumpboxName    = "$prefix-vm-jumpbox"
$jumpboxNicName = "$prefix-nic-jumpbox"
$jumpboxPipName = "$prefix-pip-jumpbox"
$appPlanName    = "$prefix-plan-infraitsec"
$appSvcName     = "$prefix-app-infraitsec"
$acrName        = "${prefix}acrinfraisec"
$storageName    = "${prefix}stginfraisec"
$sqlServerName  = "$prefix-sql-infraitsec"
$sqlDbName      = "infraitsec-employees"
$keyVaultName   = "$prefix-kv-infraitsec"

$hubVnetPrefix      = "10.0.0.0/16"
$mgmtSubnetPrefix   = "10.0.1.0/24"
$frontendVnetPrefix = "10.1.0.0/16"
$appSvcSubnetPrefix = "10.1.1.0/24"
$backendVnetPrefix  = "10.2.0.0/16"
$dataSubnetPrefix   = "10.2.1.0/24"

$tags = @{ Environment = "SecurityLab"; Owner = $prefix; Course = "DCST1005" }

# --- Resource Groups ---
Write-Step "2/11" "Oppretter Resource Groups"
foreach ($rg in @($rgHub, $rgFrontend, $rgBackend)) {
    if (Get-AzResourceGroup -Name $rg -ErrorAction SilentlyContinue) {
        Write-Status $rg "Exists"
    } else {
        New-AzResourceGroup -Name $rg -Location $location -Tag $tags -Force | Out-Null
        Write-Status $rg "Created"
    }
}

# --- Hub VNET og NSG ---
Write-Step "3/11" "Oppretter Hub VNET og NSG"

$mgmtNsg = Get-AzNetworkSecurityGroup -Name $mgmtNsgName -ResourceGroupName $rgHub -ErrorAction SilentlyContinue
if (-not $mgmtNsg) {
    $sshRule = New-AzNetworkSecurityRuleConfig `
        -Name "Allow-SSH-Internet" `
        -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
        -SourceAddressPrefix "*" -SourcePortRange "*" `
        -DestinationAddressPrefix "*" -DestinationPortRange "22"
    $httpRule = New-AzNetworkSecurityRuleConfig `
        -Name "Allow-HTTP-Internal" `
        -Access Allow -Protocol Tcp -Direction Inbound -Priority 200 `
        -SourceAddressPrefix "10.0.0.0/8" -SourcePortRange "*" `
        -DestinationAddressPrefix "*" -DestinationPortRange "80"
    $mgmtNsg = New-AzNetworkSecurityGroup `
        -Name $mgmtNsgName -ResourceGroupName $rgHub `
        -Location $location -SecurityRules $sshRule, $httpRule -Tag $tags
    Write-Status $mgmtNsgName "Created"
} else { Write-Status $mgmtNsgName "Exists" }

$hubVnet = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgHub -ErrorAction SilentlyContinue
if (-not $hubVnet) {
    $mgmtSubnetCfg = New-AzVirtualNetworkSubnetConfig `
        -Name $mgmtSubnetName -AddressPrefix $mgmtSubnetPrefix `
        -NetworkSecurityGroup $mgmtNsg
    $hubVnet = New-AzVirtualNetwork `
        -Name $hubVnetName -ResourceGroupName $rgHub `
        -Location $location -AddressPrefix $hubVnetPrefix `
        -Subnet $mgmtSubnetCfg -Tag $tags
    Write-Status "$hubVnetName ($hubVnetPrefix)" "Created"
} else { Write-Status "$hubVnetName ($hubVnetPrefix)" "Exists" }

# --- Jumpbox ---
Write-Step "4/11" "Oppretter Jumpbox VM"

if (-not (Get-AzVM -Name $jumpboxName -ResourceGroupName $rgHub -ErrorAction SilentlyContinue)) {
    $pip = Get-AzPublicIpAddress -Name $jumpboxPipName -ResourceGroupName $rgHub -ErrorAction SilentlyContinue
    if (-not $pip) {
        $pip = New-AzPublicIpAddress `
            -Name $jumpboxPipName -ResourceGroupName $rgHub `
            -Location $location -AllocationMethod Static -Sku Standard -Tag $tags
    }
    $hubVnet    = Get-AzVirtualNetwork -Name $hubVnetName -ResourceGroupName $rgHub
    $mgmtSubnet = $hubVnet.Subnets | Where-Object { $_.Name -eq $mgmtSubnetName }
    $nic = Get-AzNetworkInterface -Name $jumpboxNicName -ResourceGroupName $rgHub -ErrorAction SilentlyContinue
    if (-not $nic) {
        $ipCfg = New-AzNetworkInterfaceIpConfig `
            -Name "ipconfig1" -SubnetId $mgmtSubnet.Id `
            -PublicIpAddressId $pip.Id -Primary
        $nic = New-AzNetworkInterface `
            -Name $jumpboxNicName -ResourceGroupName $rgHub `
            -Location $location -IpConfiguration $ipCfg -Tag $tags
    }
    $cred = New-Object PSCredential("azureuser",
        (ConvertTo-SecureString "InfraIT2024!" -AsPlainText -Force))
    $vmCfg = New-AzVMConfig -VMName $jumpboxName -VMSize "Standard_B1s" |
        Set-AzVMOperatingSystem -Linux -ComputerName $jumpboxName -Credential $cred |
        Set-AzVMSourceImage `
            -PublisherName "Canonical" -Offer "0001-com-ubuntu-server-jammy" `
            -Skus "22_04-lts-gen2" -Version "latest" |
        Add-AzVMNetworkInterface -Id $nic.Id |
        Set-AzVMOSDisk -CreateOption FromImage -DeleteOption Delete
    New-AzVM -ResourceGroupName $rgHub -Location $location -VM $vmCfg -Tag $tags | Out-Null
    Write-Status $jumpboxName "Created"
} else { Write-Status $jumpboxName "Exists" }

# --- Frontend-spoke og App Service ---
Write-Step "5/11" "Oppretter Frontend-spoke VNET"

$frontendVnet = Get-AzVirtualNetwork -Name $frontendVnetName -ResourceGroupName $rgFrontend -ErrorAction SilentlyContinue
if (-not $frontendVnet) {
    $appSvcSubnetCfg = New-AzVirtualNetworkSubnetConfig `
        -Name $appSvcSubnetName -AddressPrefix $appSvcSubnetPrefix `
        -Delegation (New-AzDelegation -Name "appservice" -ServiceName "Microsoft.Web/serverFarms")
    $frontendVnet = New-AzVirtualNetwork `
        -Name $frontendVnetName -ResourceGroupName $rgFrontend `
        -Location $location -AddressPrefix $frontendVnetPrefix `
        -Subnet $appSvcSubnetCfg -Tag $tags
    Write-Status "$frontendVnetName ($frontendVnetPrefix)" "Created"
} else { Write-Status "$frontendVnetName ($frontendVnetPrefix)" "Exists" }

Write-Step "6/11" "Oppretter App Service"

if (-not (Get-AzWebApp -Name $appSvcName -ResourceGroupName $rgFrontend -ErrorAction SilentlyContinue)) {
    # Bruker az CLI for korrekt Python 3.11 runtime
    az appservice plan create `
        --name $appPlanName `
        --resource-group $rgFrontend `
        --location $location `
        --sku B1 `
        --is-linux | Out-Null
    Write-Status $appPlanName "Created"

    az webapp create `
        --name $appSvcName `
        --resource-group $rgFrontend `
        --plan $appPlanName `
        --runtime "PYTHON:3.11" | Out-Null

    az webapp update `
        --name $appSvcName `
        --resource-group $rgFrontend `
        --tags "Environment=SecurityLab" "Owner=$prefix" "Course=DCST1005" | Out-Null

    Write-Status "$appSvcName" "Created"
    Write-Host "    URL: https://$appSvcName.azurewebsites.net" -ForegroundColor Gray
    Write-Host "    NESTE STEG: Kjør Deploy-AppService-Portal.sh i Cloud Shell" -ForegroundColor Yellow
} else { Write-Status $appSvcName "Exists" }

# --- Backend-spoke ---
Write-Step "7/11" "Oppretter Backend-spoke VNET"

$backendVnet = Get-AzVirtualNetwork -Name $backendVnetName -ResourceGroupName $rgBackend -ErrorAction SilentlyContinue
if (-not $backendVnet) {
    $dataSubnetCfg = New-AzVirtualNetworkSubnetConfig `
        -Name $dataSubnetName -AddressPrefix $dataSubnetPrefix
    $backendVnet = New-AzVirtualNetwork `
        -Name $backendVnetName -ResourceGroupName $rgBackend `
        -Location $location -AddressPrefix $backendVnetPrefix `
        -Subnet $dataSubnetCfg -Tag $tags
    Write-Status "$backendVnetName ($backendVnetPrefix)" "Created"
} else { Write-Status "$backendVnetName ($backendVnetPrefix)" "Exists" }

# --- Storage ---
Write-Step "8/11" "Oppretter Storage Account"

$storage = Get-AzStorageAccount -Name $storageName -ResourceGroupName $rgBackend -ErrorAction SilentlyContinue
if (-not $storage) {
    $storage = New-AzStorageAccount `
        -Name $storageName -ResourceGroupName $rgBackend `
        -Location $location -SkuName Standard_LRS -Kind StorageV2 `
        -AllowBlobPublicAccess $true -AllowSharedKeyAccess $true -Tag $tags
    Write-Status $storageName "Created"

    $ctx = $storage.Context
    New-AzStorageContainer -Name "interne-dokumenter" -Context $ctx -Permission Blob | Out-Null

    $tmpPath = [System.IO.Path]::GetTempPath()
    $blobs = @{
        "ansattliste-2024.txt" = "KONFIDENSIELT — InfraIT.sec AS — Ansattliste 2024`n==================================================`nKari Nordmann      | IT Manager           | kari.nordmann@infraitsec.no    | 110 000 kr`nOle Hansen         | Systems Engineer     | ole.hansen@infraitsec.no       |  95 000 kr`nIngrid Berg        | HR Director          | ingrid.berg@infraitsec.no      | 105 000 kr`nLars Dahl          | Financial Analyst    | lars.dahl@infraitsec.no        |  85 000 kr`nMarte Lie          | Senior Consultant    | marte.lie@infraitsec.no        |  98 000 kr`nErik Johansen      | Cloud Architect      | erik.johansen@infraitsec.no    | 115 000 kr`nSofie Andersen     | Security Analyst     | sofie.andersen@infraitsec.no   | 102 000 kr"
        "systemkonfigurasjon.txt" = "INTERN — InfraIT.sec systemkonfigurasjon`n=========================================`nSQL-server:   $sqlServerName.database.windows.net`nDatabase:     $sqlDbName`nBlob storage: $storageName.blob.core.windows.net/interne-dokumenter`nKey Vault:    https://$keyVaultName.vault.azure.net"
        "kundeoversikt-2024.txt" = "KONFIDENSIELT — InfraIT.sec kundeoversikt`n==========================================`nBergvik AS          | Azure-migrering    | Kontrakt: 850 000 kr  | Status: Pagaende`nFjord Consulting    | Sikkerhetsreview   | Kontrakt: 120 000 kr  | Status: Fullfort`nNordic Tech AS      | Driftsavtale       | Kontrakt: 480 000 kr  | Status: Aktiv`nVestland Energi     | IT-outsourcing     | Kontrakt: 1 200 000 kr | Status: Aktiv"
    }
    foreach ($fname in $blobs.Keys) {
        $fp = Join-Path $tmpPath $fname
        $blobs[$fname] | Out-File -FilePath $fp -Encoding UTF8
        Set-AzStorageBlobContent -File $fp -Container "interne-dokumenter" -Blob $fname -Context $ctx -Force | Out-Null
        Remove-Item $fp
    }
} else { Write-Status $storageName "Exists" }

# --- Key Vault ---
Write-Step "9/11" "Oppretter Key Vault"

$kv = Get-AzKeyVault -VaultName $keyVaultName -ResourceGroupName $rgBackend -ErrorAction SilentlyContinue
if (-not $kv) {
    # Sjekk om Key Vault ligger i soft-deleted tilstand fra en tidligere kjøring.
    # Azure beholder slettede Key Vaults i 90 dager og blokkerer ny opprettelse
    # med samme navn inntil det er permanent slettet (purged).
    $deletedKv = Get-AzKeyVault `
        -VaultName $keyVaultName `
        -Location $location `
        -InRemovedState `
        -ErrorAction SilentlyContinue
    if ($deletedKv) {
        Write-Host "  Key Vault '$keyVaultName' er i deleted state — fjerner permanent..." -ForegroundColor Yellow
        Remove-AzKeyVault `
            -VaultName $keyVaultName `
            -Location $location `
            -InRemovedState `
            -Force
        Write-Status "$keyVaultName (purged fra deleted state)" "Updated"
    }

    $kv = New-AzKeyVault `
        -Name $keyVaultName -ResourceGroupName $rgBackend `
        -Location $location -Tag $tags

    $deployerOid = (Get-AzADUser -UserPrincipalName $currentUser -ErrorAction SilentlyContinue)?.Id
    if ($deployerOid) {
        Set-AzKeyVaultAccessPolicy `
            -VaultName $keyVaultName -ObjectId $deployerOid `
            -PermissionsToSecrets get,list,set,delete | Out-Null
    }

    $storageKey = (Get-AzStorageAccountKey -ResourceGroupName $rgBackend -Name $storageName)[0].Value
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "StorageAccountKey" `
        -SecretValue (ConvertTo-SecureString $storageKey -AsPlainText -Force) | Out-Null
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "SqlAdminPassword" `
        -SecretValue (ConvertTo-SecureString $sqlAdminPass -AsPlainText -Force) | Out-Null
    Set-AzKeyVaultSecret -VaultName $keyVaultName -Name "AppServiceApiKey" `
        -SecretValue (ConvertTo-SecureString "appsvc-demo-key-infraitsec-2024" -AsPlainText -Force) | Out-Null
    Write-Status $keyVaultName "Created"
} else { Write-Status $keyVaultName "Exists" }

# --- Azure SQL ---
Write-Step "10/11" "Oppretter Azure SQL"

if (-not (Get-AzSqlServer -ServerName $sqlServerName -ResourceGroupName $rgBackend -ErrorAction SilentlyContinue)) {
    $sqlCred = New-Object PSCredential($sqlAdminUser,
        (ConvertTo-SecureString $sqlAdminPass -AsPlainText -Force))
    New-AzSqlServer `
        -ResourceGroupName $rgBackend -ServerName $sqlServerName `
        -Location $location -SqlAdministratorCredentials $sqlCred -Tags $tags | Out-Null
    New-AzSqlServerFirewallRule `
        -ResourceGroupName $rgBackend -ServerName $sqlServerName `
        -FirewallRuleName "AllowAllAzureServices" `
        -StartIpAddress "0.0.0.0" -EndIpAddress "0.0.0.0" | Out-Null
    New-AzSqlServerFirewallRule `
        -ResourceGroupName $rgBackend -ServerName $sqlServerName `
        -FirewallRuleName "AllowAll" `
        -StartIpAddress "0.0.0.0" -EndIpAddress "255.255.255.255" | Out-Null
    New-AzSqlDatabase `
        -ResourceGroupName $rgBackend -ServerName $sqlServerName `
        -DatabaseName $sqlDbName -Edition "Basic" `
        -RequestedServiceObjectiveName "Basic" -Tags $tags | Out-Null
    Write-Status $sqlServerName "Created"
} else { Write-Status $sqlServerName "Exists" }

$acr = Get-AzContainerRegistry -Name $acrName -ResourceGroupName $rgBackend -ErrorAction SilentlyContinue
if (-not $acr) {
    New-AzContainerRegistry `
        -Name $acrName -ResourceGroupName $rgBackend `
        -Location $location -Sku Basic -EnableAdminUser -Tag $tags | Out-Null
    Write-Status $acrName "Created"
} else { Write-Status $acrName "Exists" }

# --- VNET Peering ---
Write-Step "11/11" "Konfigurerer VNET Peering"

$hubVnet      = Get-AzVirtualNetwork -Name $hubVnetName      -ResourceGroupName $rgHub
$frontendVnet = Get-AzVirtualNetwork -Name $frontendVnetName -ResourceGroupName $rgFrontend
$backendVnet  = Get-AzVirtualNetwork -Name $backendVnetName  -ResourceGroupName $rgBackend

Set-VnetPeering "$prefix-peer-hub-to-frontend"   $hubVnet      $frontendVnet $rgHub
Set-VnetPeering "$prefix-peer-frontend-to-hub"   $frontendVnet $hubVnet      $rgFrontend
Set-VnetPeering "$prefix-peer-hub-to-backend"    $hubVnet      $backendVnet  $rgHub
Set-VnetPeering "$prefix-peer-backend-to-hub"    $backendVnet  $hubVnet      $rgBackend

# --- Oppsummering ---
$pipAddr = (Get-AzPublicIpAddress -Name $jumpboxPipName -ResourceGroupName $rgHub -ErrorAction SilentlyContinue)?.IpAddress

Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " DEPLOYMENT FULLFORT — $prefix" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " Hub:" -ForegroundColor White
Write-Host "   $hubVnetName (10.0.0.0/16)" -ForegroundColor Gray
Write-Host "   $jumpboxName — Public IP: $pipAddr" -ForegroundColor Gray
Write-Host " Frontend:" -ForegroundColor White
Write-Host "   $frontendVnetName (10.1.0.0/16)" -ForegroundColor Gray
Write-Host "   https://$appSvcName.azurewebsites.net" -ForegroundColor Gray
Write-Host " Backend:" -ForegroundColor White
Write-Host "   $backendVnetName (10.2.0.0/16)" -ForegroundColor Gray
Write-Host "   $storageName | $keyVaultName | $sqlServerName" -ForegroundColor Gray
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host " NESTE STEG:" -ForegroundColor Yellow
Write-Host "   Kjør Deploy-AppService-Portal.sh i Azure Cloud Shell" -ForegroundColor Yellow
Write-Host "   for aa deploye innholdet til kundeportalen." -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan