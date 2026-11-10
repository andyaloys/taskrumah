@echo off
title Menjalankan TaskRumah...
echo ==========================================
echo        MEMULAI APLIKASI TASKRUMAH
echo ==========================================
echo.

echo [1/3] Memastikan Database Postgres Docker berjalan...
docker start taskrumah_db >nul 2>&1
echo [OK] Database siap.
echo.

echo [2/3] Menjalankan Backend API (.NET Core - Port 5088)...
start "TaskRumah - Backend API" cmd /k "title TaskRumah - Backend API && cd /d C:\TI\NET\taskrumah\backend\TaskRumah.API && dotnet run --urls http://localhost:5088"
echo [OK] Backend dijalankan di jendela terpisah.
echo.

echo [3/3] Menjalankan Frontend (Angular - Port 4200)...
start "TaskRumah - Frontend" cmd /k "title TaskRumah - Frontend && cd /d C:\TI\NET\taskrumah\frontend\taskrumah-web && npm start"
echo [OK] Frontend dijalankan di jendela terpisah.
echo.

echo Menunggu beberapa detik sebelum membuka browser...
timeout /t 5 >nul
start http://localhost:4200

echo.
echo ==========================================
echo   TaskRumah berhasil dijalankan!
echo   Buka: http://localhost:4200
echo   Untuk mematikan: jalankan STOP_APP.bat
echo ==========================================
pause

