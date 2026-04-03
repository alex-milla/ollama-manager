@echo off
chcp 65001 >nul
title Ollama Manager
color 0F

:: Verificar si PowerShell está disponible
powershell -Command "Get-Host" >nul 2>&1
if errorlevel 1 (
    echo Error: PowerShell no está disponible en este sistema.
    pause
    exit /b 1
)

:: Ejecutar el script de PowerShell
powershell -ExecutionPolicy Bypass -File "%~dp0ollama-manager.ps1"

exit /b %errorlevel%
