:: ################################################################
:: ##               Central de Manutenção Windows                ##
:: ################################################################
:: # Author:  https://github.com/Rc692
:: # Repo:    https://github.com/Rc692/Network-Tools
:: # SPDX-License-Identifier: MIT
:: ################################################################

@echo off
title Route Checker

cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Route-Checker.ps1"

echo.
echo ================================================
echo Programa finalizado.
echo ================================================
pause
