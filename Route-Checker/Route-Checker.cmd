@echo off
title Route Checker

cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Route-Checker.ps1"

echo.
echo ================================================
echo Programa finalizado.
echo ================================================
pause