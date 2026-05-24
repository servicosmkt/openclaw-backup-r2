@echo off
title Backup OpenClaw
echo ============================================
echo   Backup do OpenClaw (config + agentes + R2)
echo ============================================
echo.
powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0backup.ps1"
echo.
echo ============================================
echo   Backup finalizado. Veja o resultado acima.
echo ============================================
pause
