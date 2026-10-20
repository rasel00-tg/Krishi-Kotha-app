@echo off
title Krishi Kotha - Admin Control (Port 5000)
echo ==========================================================
echo   Krishi Kotha - Admin Control Panel Launcher
echo   Port: 5000
echo ==========================================================
powershell -ExecutionPolicy Bypass -File "%~dp0run_admin_web.ps1" -Port 5000
pause
