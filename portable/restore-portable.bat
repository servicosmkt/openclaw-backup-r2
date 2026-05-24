@echo off
setlocal
PowerShell -NoProfile -ExecutionPolicy Bypass -File "%~dp0restore-portable.ps1"
endlocal
pause
