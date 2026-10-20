@echo off
title Krishi Kotha - User Web App (Port 3000)
echo ==========================================================
echo   Krishi Kotha - User Web App Launcher
echo   Port: 3000
echo ==========================================================
powershell -ExecutionPolicy Bypass -File "%~dp0run_user_web.ps1" -Port 3000
pause
