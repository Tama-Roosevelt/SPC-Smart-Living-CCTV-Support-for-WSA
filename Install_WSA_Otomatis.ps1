# ========================================================================
#   Setup Otomatis WSA & SPC Smart Living CCTV untuk Windows 10 & 11
#   Author: Tama-Roosevelt
#   Repository: https://github.com/Tama-Roosevelt/SPC-Smart-Living-CCTV-Support-for-WSA
# ========================================================================

param (
    [switch]$SkipDownload
)

$ErrorActionPreference = "Continue"

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

# 2. Aktifkan Mode Pengembang & Sideloading di Registry Windows (Mencegah HRESULT 0x80073CFF)
Write-Host "[1/7] Mengonfigurasi Registry Sideloading & Mode Pengembang Windows..." -ForegroundColor Green
try {
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx"
    )
    foreach ($p in $regPaths) {
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        Set-ItemProperty -Path $p -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $p -Name "AllowAllTrustedApps" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-Host "      [OK] Kebijakan Sideloading AppX diaktifkan." -ForegroundColor Green
} catch {
    Write-Host "      [WARNING] Gagal mengatur registry sideloading: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# 3. Periksa Fitur Virtual Machine Platform & Hypervisor
Write-Host ""
Write-Host "[2/7] Memeriksa Fitur Virtual Machine Platform (VMP) & Hypervisor..." -ForegroundColor Green
$vmpChanged = $false
try {
    $vmp = Get-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -ErrorAction SilentlyContinue
    if ($null -ne $vmp -and $vmp.State -ne "Enabled") {
        Write-Host "      Mengaktifkan Virtual Machine Platform..." -ForegroundColor Yellow
        Enable-WindowsOptionalFeature -Online -FeatureName "VirtualMachinePlatform" -All -NoRestart | Out-Null
        $vmpChanged = $true
        Write-Host "      [OK] Virtual Machine Platform diaktifkan." -ForegroundColor Green
    } else {
        Write-Host "      [OK] Virtual Machine Platform sudah aktif." -ForegroundColor Green
    }
    
    # Konfigurasi bootloader hypervisor ke mode AUTO
    & bcdedit /set hypervisorlaunchtype auto | Out-Null
    Write-Host "      [OK] Bootloader Hypervisor disetel ke AUTO." -ForegroundColor Green
} catch {
    Write-Host "      [WARNING] Gagal mengonfigurasi VMP: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# 4. Periksa Pemasangan WSA (Windows Subsystem for Android)
Write-Host ""
Write-Host "[3/7] Memeriksa Windows Subsystem for Android (WSA)..." -ForegroundColor Green
$wsaPkg = Get-AppxPackage -Name "*WindowsSubsystemForAndroid*" -ErrorAction SilentlyContinue
$wsaTargetDir = "C:\WSA"

if ($null -eq $wsaPkg) {
    Write-Host "      WSA belum terpasang di sistem ini." -ForegroundColor Yellow
    
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
            Write-Host "      Mengunduh paket resmi WSA (WSA 2407 x64 Nightly LTS)..." -ForegroundColor Yellow
            $wsaUrl = "https://github.com/MustardChef/WSABuilds/releases/download/Windows_11_2407.40000.4.0_LTS_8/WSA_2407.40000.4.0_x64_Release-Nightly-NoGApps-NoAmazon.7z"
            $localWsaArchive = "$PSScriptRoot\WSA.7z"
            Write-Host "      URL: $wsaUrl" -ForegroundColor Gray
            
            # Gunakan curl.exe jika tersedia (lebih cepat dan handal)
            $curlCmd = Get-Command curl.exe -ErrorAction SilentlyContinue
            if ($null -ne $curlCmd) {
                & curl.exe -L --retry 3 --connect-timeout 30 -o "$localWsaArchive" "$wsaUrl"
            } else {
                Invoke-WebRequest -Uri $wsaUrl -OutFile $localWsaArchive -UseBasicParsing
            }
        }

        if (Test-Path $localWsaArchive) {
            Write-Host "      Mengekstrak WSA ke $wsaTargetDir..." -ForegroundColor Cyan
            New-Item -ItemType Directory -Force -Path $wsaTargetDir | Out-Null
            
            $sevenZip = "C:\Program Files\7-Zip\7z.exe"
            if (-not (Test-Path $sevenZip)) {
                $sevenZip = (Get-Command 7z.exe -ErrorAction SilentlyContinue).Source
            }
            if ($sevenZip -and (Test-Path $sevenZip)) {
                & $sevenZip x "$localWsaArchive" "-o$wsaTargetDir" -y | Out-Null
            } else {
                tar -xf "$localWsaArchive" -C "$wsaTargetDir"
            }
        } else {
            Write-Host "      [ERROR] Arsip WSA tidak ditemukan dan unduhan gagal." -ForegroundColor Red
            Write-Host "      Silakan salin berkas WSA.7z ke folder repositori atau gunakan Perbaiki_VMP.bat." -ForegroundColor Yellow
            pause
            exit 1
        }
    }
    
    # Salin seluruh runtime DLL ke subfolder WsaClient untuk mencegah error gfxstream_backend.dll
    if (Test-Path "$wsaTargetDir\WsaClient") {
        Write-Host "      Menyelaraskan runtime DLL ke folder WsaClient..." -ForegroundColor Cyan
        Copy-Item -Path "$wsaTargetDir\*.dll" -Destination "$wsaTargetDir\WsaClient" -Force -ErrorAction SilentlyContinue
    }

    # Daftarkan paket WSA
    if (Test-Path "$wsaTargetDir\AppxManifest.xml") {
        Write-Host "      Mendaftarkan paket WSA ke Windows (Add-AppxPackage)..." -ForegroundColor Cyan
        try {
            Add-AppxPackage -ForceApplicationShutdown -Register "$wsaTargetDir\AppxManifest.xml" -ErrorAction Stop
            Write-Host "      [OK] WSA berhasil didaftarkan!" -ForegroundColor Green
        } catch {
            Write-Host "      [ERROR] Gagal mendaftarkan WSA: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "      [OK] WSA sudah terpasang: $($wsaPkg.PackageFullName)" -ForegroundColor Green
    # Tetap pastikan DLL di WsaClient lengkap jika ada folder C:\WSA\WsaClient
    if (Test-Path "$wsaTargetDir\WsaClient") {
        Copy-Item -Path "$wsaTargetDir\*.dll" -Destination "$wsaTargetDir\WsaClient" -Force -ErrorAction SilentlyContinue
    }
}

# 5. Pasang WSA-Pacman (GUI Manager)
Write-Host ""
Write-Host "[4/7] Memeriksa WSA-Pacman..." -ForegroundColor Green
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

# 6. Bangunkan WSA dan Siapkan Koneksi ADB
Write-Host ""
Write-Host "[5/7] Membangunkan subsistem Android WSA & Memulai ADB..." -ForegroundColor Green

$adbPath = "$PSScriptRoot\WSA-Pacman\embedded-tools\adb.exe"
if (-not (Test-Path $adbPath)) {
    $adbPath = "C:\Program Files\WSA-pacman\embedded-tools\adb.exe"
}
if (-not (Test-Path $adbPath)) {
    $adbCmd = Get-Command adb.exe -ErrorAction SilentlyContinue
    if ($null -ne $adbCmd) { $adbPath = $adbCmd.Source }
}

# Jalankan adb start-server secara hening untuk mencegah NativeCommandError
if (Test-Path $adbPath) {
    & $adbPath start-server *>$null
}

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
    Write-Host "      [CATATAN] Belum terhubung otomatis ke ADB." -ForegroundColor Yellow
    Write-Host "      Buka jendela Pengaturan WSA, lalu aktifkan 'Developer Mode' (Mode Pengembang)." -ForegroundColor Yellow
}

# 7. Pasang Split APK SPC Smart Living
Write-Host ""
Write-Host "[6/7] Memasang Aplikasi SPC Smart Living (Multi-Split)..." -ForegroundColor Green

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

# 8. Ringkasan & Panduan Restart jika VMP baru diaktifkan
Write-Host ""
Write-Host "[7/7] Verifikasi Status Akhir..." -ForegroundColor Green
if ($vmpChanged) {
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor Yellow
    Write-Host " [PENTING] Fitur Virtual Machine Platform baru saja diaktifkan." -ForegroundColor Yellow
    Write-Host " Anda SANGAT DISARANKAN untuk ME-RESTART KOMPUTER agar Hypervisor aktif" -ForegroundColor Yellow
    Write-Host " secara penuh pada memori kernel Windows." -ForegroundColor Yellow
    Write-Host " Setelah restart, buka 'SPC Smart Living' dari Start Menu." -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor Yellow
} else {
    Write-Host "========================================================================" -ForegroundColor Cyan
    Write-Host " [SELESAI] Setup Otomatis Berhasil!" -ForegroundColor Green
    Write-Host " Buka aplikasi 'SPC Smart Living' dari Start Menu Windows." -ForegroundColor Cyan
    Write-Host "========================================================================" -ForegroundColor Cyan
}

Write-Host ""
pause
