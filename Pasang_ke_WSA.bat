@echo off
title Install SPC Smart Living ke Windows Subsystem for Android (WSA)
echo ========================================================================
echo        SPC Smart Living CCTV - Multi-Split Installer for WSA
echo                     Author: Tama-Roosevelt
echo ========================================================================
echo.

set ADB="%~dp0WSA-Pacman\embedded-tools\adb.exe"
if not exist %ADB% (
    set ADB="%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
)
if not exist %ADB% (
    set ADB=adb
)

echo [1/3] Memeriksa status koneksi ke WSA (Port 58526)...
%ADB% start-server >nul 2>&1
%ADB% connect 127.0.0.1:58526

echo.
echo [2/3] Memeriksa paket split APK...
set BASE_APK="%~dp0xapk_splits\base.apk"
if not exist %BASE_APK% set BASE_APK="%~dp0xapk_splits\com.spc.smartliving.apk"

if not exist %BASE_APK% (
    echo [ERROR] File APK utama (base.apk / com.spc.smartliving.apk) tidak ditemukan di folder xapk_splits!
    echo Silakan periksa kembali folder repositori.
    pause
    exit /b 1
)

echo.
echo [3/3] Memasang seluruh split APK secara serentak (ARM64 + Density + Language)...
%ADB% install-multiple -r %BASE_APK% "%~dp0xapk_splits\config.arm64_v8a.apk" "%~dp0xapk_splits\config.mdpi.apk" "%~dp0xapk_splits\config.en.apk"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================================
    echo [BERHASIL] SPC Smart Living telah sukses terpasang di WSA!
    echo Anda dapat langsung membuka aplikasinya melalui Start Menu Windows.
    echo ========================================================================
) else (
    echo.
    echo ========================================================================
    echo [PERINGATAN] Pemasangan belum berhasil.
    echo Pastikan:
    echo  1. WSA sudah dalam kondisi AKTIF (dibuka).
    echo  2. Developer Mode (Mode Pengembang) di Settings WSA sudah diaktifkan (ON).
    echo  3. IP dan Port ADB sesuai (default: 127.0.0.1:58526).
    echo ========================================================================
)

echo.
pause
