###############################################################################
# Deploy-HubSpokeVMs.ps1
#
# Deployer tre Linux VM-er (én per spoke) med nginx-webserver, og konfigurerer
# Azure Firewall med DNAT-regler for HTTP og SSH-tilgang via firewall public IP.
#
# Forutsetninger:
#   - Du er innlogget med Connect-AzAccount mot riktig tenant og subscription
#   - Hub VNET, spoke-VNETs, NSGer og Azure Firewall er allerede opprettet
#   - Az PowerShell-modulen er installert (Install-Module -Name Az)
#
# DNAT-portmapping etter deployment:
#   HTTP:  <fw-public-ip>:8081  ->  Spoke 1 VM port 80
#   HTTP:  <fw-public-ip>:8082  ->  Spoke 2 VM port 80
#   HTTP:  <fw-public-ip>:8083  ->  Spoke 3 VM port 80
#   SSH:   <fw-public-ip>:2221  ->  Spoke 1 VM port 22
#   SSH:   <fw-public-ip>:2222  ->  Spoke 2 VM port 22
#   SSH:   <fw-public-ip>:2223  ->  Spoke 3 VM port 22
###############################################################################


###############################################################################
# VARIABLER — fyll inn dine egne verdier her
###############################################################################

$prefix            = 'eg06'                              # Ditt tildelte prefix
$location          = 'norwayeast'

# Resource groups
$networkingRG      = "$prefix-rg-infraitsec-networking"
$computeRG         = "$prefix-rg-infraitsec-compute"

# Brukernavn og passord for VM-ene (samme for alle tre)
$adminUsername     = 'azureuser'
$adminPassword     = 'InfraIT2025!'                      # Minst 12 tegn, store+små+tall+spesialtegn

# VM-størrelser
$vmSize            = 'Standard_B1s'

# ---------------------------------------------------------------------------
# Spoke 1 — eksisterende n-tier VNET
# ---------------------------------------------------------------------------
$spoke1VnetName    = "$prefix-vnet-infraitsec"
$spoke1SubnetName  = 'subnet-frontend'
$spoke1VmName      = "$prefix-vm-web-spoke1"
$spoke1VmIp        = '10.0.1.10'                         # Statisk privat IP i subnet-frontend
$spoke1NsgName     = "$prefix-nsg-frontend"              # NSG tilknyttet subnet-frontend

# ---------------------------------------------------------------------------
# Spoke 2
# ---------------------------------------------------------------------------
$spoke2VnetName    = "$prefix-vnet-spoke2"
$spoke2SubnetName  = 'subnet-workload'
$spoke2VmName      = "$prefix-vm-web-spoke2"
$spoke2VmIp        = '10.1.0.10'                         # Statisk privat IP i subnet-workload
$spoke2NsgName     = "$prefix-nsg-spoke2"                # NSG tilknyttet subnet-workload (opprett om den ikke finnes)

# ---------------------------------------------------------------------------
# Spoke 3
# ---------------------------------------------------------------------------
$spoke3VnetName    = "$prefix-vnet-spoke3"
$spoke3SubnetName  = 'subnet-workload'
$spoke3VmName      = "$prefix-vm-web-spoke3"
$spoke3VmIp        = '10.2.0.10'                         # Statisk privat IP i subnet-workload
$spoke3NsgName     = "$prefix-nsg-spoke3"                # NSG tilknyttet subnet-workload (opprett om den ikke finnes)

# ---------------------------------------------------------------------------
# Azure Firewall
# ---------------------------------------------------------------------------
$firewallName      = "$prefix-fw-hub"
$firewallPolicyName = "$prefix-fwpolicy-hub"
$firewallSubnetPrefix = '10.100.1.0/26'                  # AzureFirewallSubnet — kilde for DNAT-trafikk mot VM-ene

# ---------------------------------------------------------------------------
# DNAT-porter (endre kun hvis du har konflikter)
# ---------------------------------------------------------------------------
$httpPortSpoke1    = '8081'
$httpPortSpoke2    = '8082'
$httpPortSpoke3    = '8083'
$sshPortSpoke1     = '2221'
$sshPortSpoke2     = '2222'
$sshPortSpoke3     = '2223'


###############################################################################
# CLOUD-INIT — nginx installeres og startes automatisk ved første oppstart
# Hver VM får en unik HTML-side som identifiserer hvilken spoke den tilhører
###############################################################################

$cloudInitSpoke1 = @"
#cloud-config
package_update: true
packages:
  - nginx
write_files:
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html>
        <head><title>Spoke 1</title></head>
        <body style="font-family:sans-serif; padding:2em; background:#e8f4f8;">
          <h1>&#x2705; Spoke 1 &mdash; Frontend</h1>
          <p><strong>InfraIT.sec Hub-Spoke Demo</strong></p>
          <p>VM: $spoke1VmName</p>
          <p>Privat IP: $spoke1VmIp</p>
          <p>Nettverk: $spoke1VnetName</p>
        </body>
      </html>
runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
"@

$cloudInitSpoke2 = @"
#cloud-config
package_update: true
packages:
  - nginx
write_files:
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html>
        <head><title>Spoke 2</title></head>
        <body style="font-family:sans-serif; padding:2em; background:#e8f8e8;">
          <h1>&#x2705; Spoke 2 &mdash; Workload</h1>
          <p><strong>InfraIT.sec Hub-Spoke Demo</strong></p>
          <p>VM: $spoke2VmName</p>
          <p>Privat IP: $spoke2VmIp</p>
          <p>Nettverk: $spoke2VnetName</p>
        </body>
      </html>
runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
"@

$cloudInitSpoke3 = @"
#cloud-config
package_update: true
packages:
  - nginx
write_files:
  - path: /var/www/html/index.html
    content: |
      <!DOCTYPE html>
      <html>
        <head><title>Spoke 3</title></head>
        <body style="font-family:sans-serif; padding:2em; background:#f8f0e8;">
          <h1>&#x2705; Spoke 3 &mdash; Workload</h1>
          <p><strong>InfraIT.sec Hub-Spoke Demo</strong></p>
          <p>VM: $spoke3VmName</p>
          <p>Privat IP: $spoke3VmIp</p>
          <p>Nettverk: $spoke3VnetName</p>
        </body>
      </html>
runcmd:
  - systemctl enable nginx
  - systemctl restart nginx
"@


###############################################################################
# FUNKSJON: Deploy-SpokeVM
# Oppretter NIC (uten public IP) og VM med cloud-init i angitt subnet
###############################################################################

function Deploy-SpokeVM {
    param (
        [string]$VmName,
        [string]$VnetName,
        [string]$SubnetName,
        [string]$PrivateIpAddress,
        [string]$CloudInitContent,
        [string]$ResourceGroup,
        [string]$Location,
        [string]$AdminUsername,
        [string]$AdminPassword,
        [string]$VmSize,
        [string]$NetworkingRG
    )

    Write-Host "`n  Henter subnet '$SubnetName' fra '$VnetName'..." -ForegroundColor Gray
    $vnet   = Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $NetworkingRG
    $subnet = Get-AzVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $vnet

    Write-Host "  Oppretter NIC for $VmName..." -ForegroundColor Gray
    $ipConfig = New-AzNetworkInterfaceIpConfig `
        -Name 'ipconfig1' `
        -SubnetId $subnet.Id `
        -PrivateIpAddress $PrivateIpAddress `
        -PrivateIpAddressVersion IPv4 `
        -Primary

    $nic = New-AzNetworkInterface `
        -Name "$VmName-nic" `
        -ResourceGroupName $ResourceGroup `
        -Location $Location `
        -IpConfiguration $ipConfig `
        -Tag @{ Owner = $VmName; Environment = 'Lab'; Course = 'InfraIT-Cyber' }

    Write-Host "  Konfigurerer VM-objekt for $VmName..." -ForegroundColor Gray
    $credential = [PSCredential]::new(
        $AdminUsername,
        (ConvertTo-SecureString $AdminPassword -AsPlainText -Force)
    )

    $vmConfig = New-AzVMConfig -VMName $VmName -VMSize $VmSize |
        Set-AzVMOperatingSystem `
            -Linux `
            -ComputerName $VmName `
            -Credential $credential `
            -CustomData $CloudInitContent |
        Set-AzVMSourceImage `
            -PublisherName 'Canonical' `
            -Offer 'ubuntu-24_04-lts' `
            -Skus 'server' `
            -Version 'latest' |
        Add-AzVMNetworkInterface -Id $nic.Id |
        Set-AzVMOSDisk `
            -Name "$VmName-osdisk" `
            -CreateOption FromImage `
            -StorageAccountType Standard_LRS |
        Set-AzVMBootDiagnostic -Disable

    Write-Host "  Deployer $VmName (dette tar 1-2 minutter)..." -ForegroundColor Gray
    New-AzVM `
        -ResourceGroupName $ResourceGroup `
        -Location $Location `
        -VM $vmConfig `
        -Tag @{ Owner = $VmName; Environment = 'Lab'; Course = 'InfraIT-Cyber' } | Out-Null

    Write-Host "  $VmName opprettet." -ForegroundColor Green
}


###############################################################################
# STEG 1: Opprett compute resource group hvis den ikke finnes
###############################################################################

Write-Host "`n[1/5] Sjekker compute resource group..." -ForegroundColor Cyan

$rg = Get-AzResourceGroup -Name $computeRG -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "  Oppretter $computeRG..." -ForegroundColor Gray
    New-AzResourceGroup -Name $computeRG -Location $location `
        -Tag @{ Environment = 'Lab'; Course = 'InfraIT-Cyber' } | Out-Null
    Write-Host "  $computeRG opprettet." -ForegroundColor Green
} else {
    Write-Host "  $computeRG finnes allerede." -ForegroundColor Green
}


###############################################################################
# STEG 2: Deploy VM-er i alle tre spokes
###############################################################################

Write-Host "`n[2/5] Deployer VM-er i spoke 1, 2 og 3..." -ForegroundColor Cyan

Write-Host "`nSpoke 1:" -ForegroundColor White
Deploy-SpokeVM `
    -VmName          $spoke1VmName `
    -VnetName        $spoke1VnetName `
    -SubnetName      $spoke1SubnetName `
    -PrivateIpAddress $spoke1VmIp `
    -CloudInitContent $cloudInitSpoke1 `
    -ResourceGroup   $computeRG `
    -Location        $location `
    -AdminUsername   $adminUsername `
    -AdminPassword   $adminPassword `
    -VmSize          $vmSize `
    -NetworkingRG    $networkingRG

Write-Host "`nSpoke 2:" -ForegroundColor White
Deploy-SpokeVM `
    -VmName          $spoke2VmName `
    -VnetName        $spoke2VnetName `
    -SubnetName      $spoke2SubnetName `
    -PrivateIpAddress $spoke2VmIp `
    -CloudInitContent $cloudInitSpoke2 `
    -ResourceGroup   $computeRG `
    -Location        $location `
    -AdminUsername   $adminUsername `
    -AdminPassword   $adminPassword `
    -VmSize          $vmSize `
    -NetworkingRG    $networkingRG

Write-Host "`nSpoke 3:" -ForegroundColor White
Deploy-SpokeVM `
    -VmName          $spoke3VmName `
    -VnetName        $spoke3VnetName `
    -SubnetName      $spoke3SubnetName `
    -PrivateIpAddress $spoke3VmIp `
    -CloudInitContent $cloudInitSpoke3 `
    -ResourceGroup   $computeRG `
    -Location        $location `
    -AdminUsername   $adminUsername `
    -AdminPassword   $adminPassword `
    -VmSize          $vmSize `
    -NetworkingRG    $networkingRG


###############################################################################
# STEG 3: Legg til NSG-regler for HTTP og SSH fra AzureFirewallSubnet
#
# VM-ene har ikke public IP — all innkommende trafikk kommer fra firewallen.
# Firewallen SNAT-er trafikken slik at VM-ene ser firewall private IP som kilde.
# NSG-reglene må derfor tillate inbound fra AzureFirewallSubnet, ikke fra Any.
###############################################################################

Write-Host "`n[3/5] Oppdaterer NSG-regler..." -ForegroundColor Cyan

function Add-FirewallInboundRules {
    param (
        [string]$NsgName,
        [string]$ResourceGroup,
        [string]$FirewallSubnetPrefix,
        [int]$HttpPriority = 1100,
        [int]$SshPriority  = 1110
    )

    $nsg = Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $ResourceGroup `
           -ErrorAction SilentlyContinue

    if (-not $nsg) {
        Write-Host "  ADVARSEL: NSG '$NsgName' ble ikke funnet i '$ResourceGroup'. Hopper over." `
                   -ForegroundColor Yellow
        return
    }

    # Sjekk om reglene allerede finnes
    $existingHttp = $nsg.SecurityRules | Where-Object { $_.Name -eq 'allow-http-from-firewall' }
    $existingSsh  = $nsg.SecurityRules | Where-Object { $_.Name -eq 'allow-ssh-from-firewall' }

    if (-not $existingHttp) {
        $nsg | Add-AzNetworkSecurityRuleConfig `
            -Name                     'allow-http-from-firewall' `
            -Description              'Tillater HTTP fra AzureFirewallSubnet (DNAT)' `
            -Protocol                 'Tcp' `
            -SourceAddressPrefix      $FirewallSubnetPrefix `
            -SourcePortRange          '*' `
            -DestinationAddressPrefix '*' `
            -DestinationPortRange     '80' `
            -Access                   'Allow' `
            -Priority                 $HttpPriority `
            -Direction                'Inbound' | Out-Null
        Write-Host "  HTTP-regel lagt til i $NsgName." -ForegroundColor Green
    } else {
        Write-Host "  HTTP-regel finnes allerede i $NsgName." -ForegroundColor Gray
    }

    if (-not $existingSsh) {
        $nsg | Add-AzNetworkSecurityRuleConfig `
            -Name                     'allow-ssh-from-firewall' `
            -Description              'Tillater SSH fra AzureFirewallSubnet (DNAT)' `
            -Protocol                 'Tcp' `
            -SourceAddressPrefix      $FirewallSubnetPrefix `
            -SourcePortRange          '*' `
            -DestinationAddressPrefix '*' `
            -DestinationPortRange     '22' `
            -Access                   'Allow' `
            -Priority                 $SshPriority `
            -Direction                'Inbound' | Out-Null
        Write-Host "  SSH-regel lagt til i $NsgName." -ForegroundColor Green
    } else {
        Write-Host "  SSH-regel finnes allerede i $NsgName." -ForegroundColor Gray
    }

    $nsg | Set-AzNetworkSecurityGroup | Out-Null
}

Add-FirewallInboundRules -NsgName $spoke1NsgName -ResourceGroup $networkingRG `
    -FirewallSubnetPrefix $firewallSubnetPrefix -HttpPriority 1100 -SshPriority 1110

Add-FirewallInboundRules -NsgName $spoke2NsgName -ResourceGroup $networkingRG `
    -FirewallSubnetPrefix $firewallSubnetPrefix -HttpPriority 1100 -SshPriority 1110

Add-FirewallInboundRules -NsgName $spoke3NsgName -ResourceGroup $networkingRG `
    -FirewallSubnetPrefix $firewallSubnetPrefix -HttpPriority 1100 -SshPriority 1110


###############################################################################
# STEG 4: Konfigurer Azure Firewall DNAT-regler
###############################################################################

Write-Host "`n[4/5] Konfigurerer DNAT-regler i Firewall Policy..." -ForegroundColor Cyan

# Hent firewall public IP
$firewall    = Get-AzFirewall -Name $firewallName -ResourceGroupName $networkingRG
$fwPublicIp  = $firewall.IpConfigurations[0].PublicIPAddress
$fwPipObj    = Get-AzPublicIpAddress -ResourceGroupName $networkingRG |
                   Where-Object { $_.Id -eq $fwPublicIp.Id }
$fwPublicIpAddress = $fwPipObj.IpAddress

Write-Host "  Firewall public IP: $fwPublicIpAddress" -ForegroundColor Gray

# Hent Firewall Policy
$fwPolicy = Get-AzFirewallPolicy -Name $firewallPolicyName -ResourceGroupName $networkingRG

# Bygg DNAT-regler for HTTP
$dnatHttpSpoke1 = New-AzFirewallPolicyNatRule `
    -Name              'dnat-http-spoke1' `
    -Protocol          'TCP' `
    -SourceAddress     '*' `
    -DestinationAddress $fwPublicIpAddress `
    -DestinationPort   $httpPortSpoke1 `
    -TranslatedAddress $spoke1VmIp `
    -TranslatedPort    '80'

$dnatHttpSpoke2 = New-AzFirewallPolicyNatRule `
    -Name              'dnat-http-spoke2' `
    -Protocol          'TCP' `
    -SourceAddress     '*' `
    -DestinationAddress $fwPublicIpAddress `
    -DestinationPort   $httpPortSpoke2 `
    -TranslatedAddress $spoke2VmIp `
    -TranslatedPort    '80'

$dnatHttpSpoke3 = New-AzFirewallPolicyNatRule `
    -Name              'dnat-http-spoke3' `
    -Protocol          'TCP' `
    -SourceAddress     '*' `
    -DestinationAddress $fwPublicIpAddress `
    -DestinationPort   $httpPortSpoke3 `
    -TranslatedAddress $spoke3VmIp `
    -TranslatedPort    '80'

# Bygg DNAT-regler for SSH
$dnatSshSpoke1 = New-AzFirewallPolicyNatRule `
    -Name              'dnat-ssh-spoke1' `
    -Protocol          'TCP' `
    -SourceAddress     '*' `
    -DestinationAddress $fwPublicIpAddress `
    -DestinationPort   $sshPortSpoke1 `
    -TranslatedAddress $spoke1VmIp `
    -TranslatedPort    '22'

$dnatSshSpoke2 = New-AzFirewallPolicyNatRule `
    -Name              'dnat-ssh-spoke2' `
    -Protocol          'TCP' `
    -SourceAddress     '*' `
    -DestinationAddress $fwPublicIpAddress `
    -DestinationPort   $sshPortSpoke2 `
    -TranslatedAddress $spoke2VmIp `
    -TranslatedPort    '22'

$dnatSshSpoke3 = New-AzFirewallPolicyNatRule `
    -Name              'dnat-ssh-spoke3' `
    -Protocol          'TCP' `
    -SourceAddress     '*' `
    -DestinationAddress $fwPublicIpAddress `
    -DestinationPort   $sshPortSpoke3 `
    -TranslatedAddress $spoke3VmIp `
    -TranslatedPort    '22'

# Samle alle DNAT-regler i én rule collection
$dnatRuleCollection = New-AzFirewallPolicyNatRuleCollection `
    -Name       'dnat-spoke-vms' `
    -Priority   100 `
    -Rule       @(
                    $dnatHttpSpoke1, $dnatHttpSpoke2, $dnatHttpSpoke3,
                    $dnatSshSpoke1,  $dnatSshSpoke2,  $dnatSshSpoke3
                ) `
    -ActionType 'Dnat'

# Opprett ny rule collection group for DNAT-regler
Write-Host "  Oppretter DNAT rule collection group..." -ForegroundColor Gray
New-AzFirewallPolicyRuleCollectionGroup `
    -Name                'DnatRuleCollectionGroup' `
    -Priority            100 `
    -RuleCollection      $dnatRuleCollection `
    -FirewallPolicyObject $fwPolicy | Out-Null

Write-Host "  DNAT-regler konfigurert." -ForegroundColor Green


###############################################################################
# STEG 5: Oppsummering
###############################################################################

Write-Host "`n[5/5] Deployment fullfort!" -ForegroundColor Cyan
Write-Host "`n==============================================" -ForegroundColor White
Write-Host " Tilgangsoversikt" -ForegroundColor White
Write-Host "==============================================" -ForegroundColor White
Write-Host " Firewall public IP : $fwPublicIpAddress" -ForegroundColor White
Write-Host "" 
Write-Host " HTTP-tilgang (aapnes i nettleser):" -ForegroundColor White
Write-Host "   Spoke 1:  http://$($fwPublicIpAddress):$httpPortSpoke1" -ForegroundColor Yellow
Write-Host "   Spoke 2:  http://$($fwPublicIpAddress):$httpPortSpoke2" -ForegroundColor Yellow
Write-Host "   Spoke 3:  http://$($fwPublicIpAddress):$httpPortSpoke3" -ForegroundColor Yellow
Write-Host ""
Write-Host " SSH-tilgang:" -ForegroundColor White
Write-Host "   Spoke 1:  ssh $adminUsername@$fwPublicIpAddress -p $sshPortSpoke1" -ForegroundColor Yellow
Write-Host "   Spoke 2:  ssh $adminUsername@$fwPublicIpAddress -p $sshPortSpoke2" -ForegroundColor Yellow
Write-Host "   Spoke 3:  ssh $adminUsername@$fwPublicIpAddress -p $sshPortSpoke3" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor White
Write-Host ""
Write-Host " NB: Cloud-init installerer nginx etter oppstart." -ForegroundColor Gray
Write-Host " Vent 2-3 minutter etter deployment foer HTTP-tilgang fungerer." -ForegroundColor Gray
Write-Host ""