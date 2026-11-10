@echo off
title Menghentikan TaskRumah...
echo ==========================================
echo       MENGHENTIKAN APLIKASI TASKRUMAH
echo ==========================================
echo.
echo Menghentikan Backend dan Frontend...
taskkill /FI "WINDOWTITLE eq TaskRumah - Backend API*" /T /F >nul 2>&1
taskkill /FI "WINDOWTITLE eq TaskRumah - Frontend*" /T /F >nul 2>&1
taskkill /IM dotnet.exe /F >nul 2>&1
taskkill /IM node.exe /F >nul 2>&1
echo [OK] Backend dan Frontend telah dihentikan.
echo.
pause

