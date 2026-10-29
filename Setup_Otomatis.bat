@echo off
title Setup Otomatis WSA & SPC Smart Living
echo ========================================================================
echo     Menjalankan Setup Otomatis WSA & SPC Smart Living (Administrator)
echo ========================================================================
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install_WSA_Otomatis.ps1"

pause

