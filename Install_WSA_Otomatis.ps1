# ========================================================================
#   Setup Otomatis WSA & SPC Smart Living CCTV untuk Windows 10 & 11
#   Author: Tama-Roosevelt
#   Repository: https://github.com/Tama-Roosevelt/SPC-Smart-Living-CCTV-Support-for-WSA
# ========================================================================

param (
    [switch]$SkipDownload
)

$ErrorActionPreference = "Stop"

Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host "   OTOMATISASI INSTALASI WINDOWS SUBSYSTEM FOR ANDROID (WSA) & CCTV SPC" -ForegroundColor Cyan
Write-Host "                         Author: Tama-Roosevelt" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Periksa Hak Akses Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[INFO] Meminta hak akses Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Periksa Fitur Virtual Machine Platform
Write-Host "[1/6] Memeriksa Fitur Virtual Machine Platform (VMP)..." -ForegroundColor Green
try {
    $vmp = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
    if ($null -ne $vmp -and $vmp.State -ne "Enabled") {
        Write-Host "      Mengaktifkan Virtual Machine Platform..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -All -NoRestart | Out-Null
        Write-Host "      [OK] Virtual Machine Platform diaktifkan." -ForegroundColor Green
    } else {
        Write-Host "      [OK] Virtual Machine Platform sudah aktif." -ForegroundColor Green
    }
} catch {
    Write-Host "      [WARNING] Gagal memeriksa status VMP: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# 3. Periksa Pemasangan WSA (Windows Subsystem for Android)
Write-Host ""
Write-Host "[2/6] Memeriksa Windows Subsystem for Android (WSA)..." -ForegroundColor Green
$wsaPkg = Get-AppxPackage -Name "*WindowsSubsystemForAndroid*" -ErrorAction SilentlyContinue

$wsaTargetDir = "C:\WSA"

if ($null -eq $wsaPkg) {
    Write-Host "      WSA belum terpasang di sistem ini." -ForegroundColor Yellow
    
    # Periksa apakah folder C:\WSA sudah ada isinya
    if (-not (Test-Path "$wsaTargetDir\AppxManifest.xml")) {
        Write-Host "      Mencari arsip WSA.7z lokal..." -ForegroundColor Cyan
        
        $localWsaArchive = $null
        $possibleArchives = @(
            "$PSScriptRoot\WSA.7z",
            "$PSScriptRoot\WSA_*.7z",
            "C:\WSA.7z"
        )
        foreach ($pat in $possibleArchives) {
            $found = Get-Item $pat -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($null -ne $found) {
                $localWsaArchive = $found.FullName
                break
            }
        }
        
        if ($null -eq $localWsaArchive -and -not $SkipDownload) {
            Write-Host "      Mengunduh paket resmi WSA (WSA 2407 x64 Nightly NoGApps)..." -ForegroundColor Yellow
            $wsaUrl = "https://github.com/MustardChef/WSABuilds/releases/download/Windows_11_2407.40000.4.0/WSA_2407.40000.4.0_x64_Release-Nightly-NoGApps-NoAmazon.7z"
            $localWsaArchive = "$PSScriptRoot\WSA.7z"
            Write-Host "      Mengunduh dari: $wsaUrl" -ForegroundColor Gray
            Invoke-WebRequest -Uri $wsaUrl -OutFile $localWsaArchive -UseBasicParsing
        }

        if (Test-Path $localWsaArchive) {
            Write-Host "      Mengekstrak WSA ke $wsaTargetDir..." -ForegroundColor Cyan
            New-Item -ItemType Directory -Force -Path $wsaTargetDir | Out-Null
            
            # Gunakan 7-Zip jika tersedia, atau tar
            $sevenZip = "C:\Program Files\7-Zip\7z.exe"
            if (-not (Test-Path $sevenZip)) {
                $sevenZip = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source
            }
            if (Test-Path $sevenZip) {
                & $sevenZip x "$localWsaArchive" "-o$wsaTargetDir" -y | Out-Null
            } else {
                # Alternatif pakai tar
                tar -xf "$localWsaArchive" -C "$wsaTargetDir"
            }
        } else {
            Write-Host "      [ERROR] Arsip WSA tidak ditemukan dan tidak dapat diunduh." -ForegroundColor Red
            Write-Host "      Silakan salin WSA.7z ke folder repositori atau unduh dari GitHub WSABuilds." -ForegroundColor Yellow
            pause
            exit 1
        }
    }
    
    # Daftarkan paket WSA
    if (Test-Path "$wsaTargetDir\AppxManifest.xml") {
        Write-Host "      Mendaftarkan paket WSA ke Windows..." -ForegroundColor Cyan
        Add-AppxPackage -ForceApplicationShutdown -Register "$wsaTargetDir\AppxManifest.xml"
        Write-Host "      [OK] WSA berhasil didaftarkan!" -ForegroundColor Green
    }
} else {
    Write-Host "      [OK] WSA sudah terpasang: $($wsaPkg.PackageFullName)" -ForegroundColor Green
}

# 4. Pasang WSA-Pacman (Opsional / GUI Manager)
Write-Host ""
Write-Host "[3/6] Memeriksa WSA-Pacman..." -ForegroundColor Green
$pacmanInstaller = "$PSScriptRoot\WSA-pacman-v1.5.0-installer.exe"
if (Test-Path $pacmanInstaller) {
    $pacmanInstalled = Test-Path "C:\Program Files\WSA-pacman\WSA-pacman.exe"
    if (-not $pacmanInstalled) {
        Write-Host "      Memasang WSA-Pacman secara silent..." -ForegroundColor Cyan
        Start-Process $pacmanInstaller -ArgumentList "/VERYSILENT /NORESTART" -Wait
        Write-Host "      [OK] WSA-Pacman terpasang." -ForegroundColor Green
    } else {
        Write-Host "      [OK] WSA-Pacman sudah terpasang." -ForegroundColor Green
    }
}

# 5. Bangunkan WSA dan Siapkan Koneksi ADB
Write-Host ""
Write-Host "[4/6] Membangunkan subsistem Android WSA..." -ForegroundColor Green

# Cari tool ADB
$adbPath = "$PSScriptRoot\WSA-Pacman\embedded-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = "C:\Program Files\WSA-pacman\embedded-tools\adb.exe"
}
if (-not (Test-Path $adbPath)) {
    $adbCmd = Get-Command adb.exe -ErrorAction SilentlyContinue
    if ($null -ne $adbCmd) { $adbPath = $adbCmd.Source }
}

# Jalankan WsaClient untuk memicu startup
try {
    Start-Process "wsa://com.android.settings" -ErrorAction SilentlyContinue
} catch {}

Write-Host "      Menunggu WSA aktif (port 58526)..." -ForegroundColor Cyan
$connected = $false
for ($i = 1; $i -le 10; $i++) {
    Start-Sleep -Seconds 3
    if (Test-Path $adbPath) {
        $res = & $adbPath connect 127.0.0.1:58526 2>&1
        if ($res -like "*connected to*" -or $res -like "*already connected*") {
            $connected = $true
            Write-Host "      [OK] Terhubung ke WSA via ADB!" -ForegroundColor Green
            break
        }
    }
    Write-Host "      Mencoba menghubungkan ($i/10)..." -ForegroundColor Gray
}

if (-not $connected) {
    Write-Host ""
    Write-Host "      [PERHATIAN] Belum bisa otomatis terhubung ke ADB." -ForegroundColor Yellow
    Write-Host "      Pastikan Pengaturan WSA sudah dibuka, dan 'Developer Mode' diaktifkan (ON)." -ForegroundColor Yellow
}

# 6. Pasang Split APK SPC Smart Living
Write-Host ""
Write-Host "[5/6] Memasang Aplikasi SPC Smart Living (Multi-Split)..." -ForegroundColor Green

$splitsDir = "$PSScriptRoot\xapk_splits"
$baseApk = "$splitsDir\base.apk"
if (-not (Test-Path $baseApk)) {
    $baseApk = "$splitsDir\com.spc.smartliving.apk"
}
$armApk  = "$splitsDir\config.arm64_v8a.apk"
$mdpiApk = "$splitsDir\config.mdpi.apk"
$enApk   = "$splitsDir\config.en.apk"

if ((Test-Path $baseApk) -and (Test-Path $armApk)) {
    if (Test-Path $adbPath) {
        Write-Host "      Menjalankan adb install-multiple..." -ForegroundColor Cyan
        $installOut = & $adbPath install-multiple -r "$baseApk" "$armApk" "$mdpiApk" "$enApk" 2>&1
        if ($installOut -like "*Success*") {
            Write-Host "      [BERHASIL] SPC Smart Living terpasang sempurna!" -ForegroundColor Green
        } else {
            Write-Host "      Hasil: $installOut" -ForegroundColor Yellow
        }
    } else {
        Write-Host "      [ERROR] ADB tidak ditemukan untuk instalasi APK." -ForegroundColor Red
    }
} else {
    Write-Host "      [WARNING] Berkas split APK tidak lengkap di $splitsDir." -ForegroundColor Yellow
}

# 7. Selesai
Write-Host ""
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " [SELESAI] Proses Setup Otomatis Telah Berakhir!" -ForegroundColor Green
Write-Host " Anda dapat membuka 'SPC Smart Living' langsung dari Start Menu Windows." -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host ""
pause

