@echo off
title Perbaikan Fitur Virtual Machine Platform (VMP) ^& Hypervisor
echo ========================================================================
echo        PERBAIKAN FITUR VIRTUAL MACHINE PLATFORM (VMP) WINDOWS
echo                     Author: Tama-Roosevelt
echo ========================================================================
echo.
echo Script ini memperbaiki kendala:
echo  - Error 14098 / 0x80073712 (Component Store corrupted)
echo  - Pop-up "Virtual Machine Platform is turned on for your PC"
echo  - Hypervisor belum aktif pada memory kernel Windows
echo.
echo [1/3] Menjalankan DISM RestoreHealth untuk memulihkan file sistem Windows...
echo       (Proses ini membutuhkan waktu beberapa menit, mohon tunggu)...
dism.exe /Online /Cleanup-Image /RestoreHealth

echo.
echo [2/3] Mengaktifkan fitur Virtual Machine Platform...
dism.exe /Online /Enable-Feature /FeatureName:VirtualMachinePlatform /All /NoRestart

echo.
echo [3/3] Mengonfigurasi Bootloader Hypervisor ke mode AUTO...
bcdedit /set hypervisorlaunchtype auto

echo.
echo ========================================================================
echo [SELESAI] Konfigurasi VMP dan Hypervisor berhasil diperbarui!
echo.
echo PENTING:
echo Anda HARUS ME-RESTART KOMPUTER sekarang juga agar Hypervisor
echo dimuat ke dalam memori kernel Windows.
echo.
echo Setelah komputer menyala kembali, jalankan "Setup_Otomatis.bat".
echo ========================================================================
echo.
pause
