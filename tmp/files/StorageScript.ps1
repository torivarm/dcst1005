#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disk space analysis - finds large folders and files on C:\
.DESCRIPTION
    Reports top space consumers: folders, files, and known Windows cleanup candidates.
    Run as Administrator for full access (especially WinSxS and Windows Update folders).
.NOTES
    Estimated runtime on 40 GB drive: 1-3 minutes (SSD faster, HDD slower)
#>

param(
    [string]$Drive       = "C:\",
    [int]$TopFolders     = 20,
    [int]$TopFiles       = 20,
    [long]$MinFileSizeMB = 100    # Only report files larger than this (MB)
)

function Format-Size {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    if ($Bytes -ge 1MB) { return "{0:N1} MB" -f ($Bytes / 1MB) }
    return "{0:N0} KB" -f ($Bytes / 1KB)
}

# ─────────────────────────────────────────────
# 0. Drive summary
# ─────────────────────────────────────────────
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  DISK SPACE REPORT  |  $(Get-Date -Format 'yyyy-MM-dd HH:mm')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$disk = Get-PSDrive C
$totalGB  = [math]::Round(($disk.Used + $disk.Free) / 1GB, 1)
$usedGB   = [math]::Round($disk.Used  / 1GB, 1)
$freeGB   = [math]::Round($disk.Free  / 1GB, 1)
$freePct  = [math]::Round(($disk.Free / ($disk.Used + $disk.Free)) * 100, 1)

Write-Host "Drive C:\" -ForegroundColor Yellow
Write-Host "  Total : $totalGB GB"
Write-Host "  Used  : $usedGB GB"
Write-Host "  Free  : $freeGB GB  ($freePct %)"

# ─────────────────────────────────────────────
# 1. Known Windows cleanup candidates (quick checks, no full scan needed)
# ─────────────────────────────────────────────
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "  KNOWN WINDOWS SPACE CONSUMERS" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

$candidates = @(
    @{ Label = "Windows Update cache (DataStore)";  Path = "C:\Windows\SoftwareDistribution\DataStore" },
    @{ Label = "Windows Update downloads";           Path = "C:\Windows\SoftwareDistribution\Download" },
    @{ Label = "WinSxS (component store)";           Path = "C:\Windows\WinSxS" },
    @{ Label = "Windows Temp";                       Path = "C:\Windows\Temp" },
    @{ Label = "User Temp (%TEMP%)";                 Path = $env:TEMP },
    @{ Label = "Recycle Bin (C:\)";                  Path = "C:\`$Recycle.Bin" },
    @{ Label = "Windows old installation";           Path = "C:\Windows.old" },
    @{ Label = "Hibernation file";                   Path = "C:\hiberfil.sys" },
    @{ Label = "Page file";                          Path = "C:\pagefile.sys" },
    @{ Label = "IIS logs";                           Path = "C:\inetpub\logs" },
    @{ Label = "CBS logs (Windows servicing)";       Path = "C:\Windows\Logs\CBS" }
)

foreach ($item in $candidates) {
    if (Test-Path $item.Path) {
        try {
            $size = (Get-ChildItem $item.Path -Recurse -Force -ErrorAction SilentlyContinue |
                     Measure-Object -Property Length -Sum).Sum
            if ($null -eq $size) { $size = (Get-Item $item.Path -Force).Length }
            $sizeStr = Format-Size $size
            $color = if ($size -gt 1GB) { "Red" } elseif ($size -gt 200MB) { "Yellow" } else { "Green" }
            Write-Host ("  {0,-45} {1}" -f $item.Label, $sizeStr) -ForegroundColor $color
        } catch {
            Write-Host ("  {0,-45} (access denied)" -f $item.Label) -ForegroundColor DarkGray
        }
    } else {
        Write-Host ("  {0,-45} not present" -f $item.Label) -ForegroundColor DarkGray
    }
}

# ─────────────────────────────────────────────
# 2. Top N largest TOP-LEVEL folders under C:\
#    (avoids full recursive scan of every subfolder at start)
# ─────────────────────────────────────────────
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "  TOP $TopFolders LARGEST FOLDERS (first-level, then drill down)" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

Write-Host "Scanning first-level folders... (this may take 1-3 minutes)`n" -ForegroundColor DarkGray

$firstLevel = Get-ChildItem -Path $Drive -Directory -Force -ErrorAction SilentlyContinue

$folderSizes = foreach ($folder in $firstLevel) {
    try {
        $size = (Get-ChildItem $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Path      = $folder.FullName
            SizeBytes = if ($null -eq $size) { 0 } else { $size }
            SizeStr   = Format-Size (if ($null -eq $size) { 0 } else { $size })
        }
    } catch {
        [PSCustomObject]@{ Path = $folder.FullName; SizeBytes = 0; SizeStr = "N/A" }
    }
}

$folderSizes | Sort-Object SizeBytes -Descending | Select-Object -First $TopFolders |
    ForEach-Object {
        $color = if ($_.SizeBytes -gt 5GB) { "Red" } elseif ($_.SizeBytes -gt 1GB) { "Yellow" } else { "White" }
        Write-Host ("  {0,-55} {1}" -f $_.Path, $_.SizeStr) -ForegroundColor $color
    }

# ─────────────────────────────────────────────
# 3. Top N largest FILES on entire drive
# ─────────────────────────────────────────────
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "  TOP $TopFiles LARGEST FILES (>= $MinFileSizeMB MB)" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

Write-Host "Scanning for large files..." -ForegroundColor DarkGray

$largeFiles = Get-ChildItem -Path $Drive -Recurse -Force -ErrorAction SilentlyContinue |
    Where-Object { -not $_.PSIsContainer -and $_.Length -ge ($MinFileSizeMB * 1MB) } |
    Sort-Object Length -Descending |
    Select-Object -First $TopFiles

if ($largeFiles) {
    foreach ($file in $largeFiles) {
        $color = if ($file.Length -gt 2GB) { "Red" } elseif ($file.Length -gt 500MB) { "Yellow" } else { "White" }
        Write-Host ("  {0,-65} {1}" -f $file.FullName, (Format-Size $file.Length)) -ForegroundColor $color
    }
} else {
    Write-Host "  No files larger than $MinFileSizeMB MB found." -ForegroundColor DarkGray
}

# ─────────────────────────────────────────────
# 4. Cleanup suggestions
# ─────────────────────────────────────────────
Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "  CLEANUP COMMANDS (run manually if needed)" -ForegroundColor Cyan
Write-Host "----------------------------------------`n" -ForegroundColor Cyan

Write-Host "  # Clear Windows Update download cache (safe to delete):" -ForegroundColor DarkGray
Write-Host "  Stop-Service wuauserv -Force" -ForegroundColor White
Write-Host "  Remove-Item C:\Windows\SoftwareDistribution\Download\* -Recurse -Force" -ForegroundColor White
Write-Host "  Start-Service wuauserv`n" -ForegroundColor White

Write-Host "  # Disk Cleanup with all options (includes WinSxS cleanup):" -ForegroundColor DarkGray
Write-Host "  cleanmgr /sageset:1   # configure what to clean" -ForegroundColor White
Write-Host "  cleanmgr /sagerun:1   # run the cleanup`n" -ForegroundColor White

Write-Host "  # DISM: clean up superseded Windows components in WinSxS:" -ForegroundColor DarkGray
Write-Host "  DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase`n" -ForegroundColor White

Write-Host "  # Check hibernate status (hiberfil.sys):" -ForegroundColor DarkGray
Write-Host "  powercfg /hibernate off   # removes hiberfil.sys if not needed`n" -ForegroundColor White

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Report complete" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan