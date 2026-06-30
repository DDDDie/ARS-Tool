@echo off
cd /d "%~dp0\.."

if not exist "release\index.html" (
  echo release\index.html not found. Building the app first...
  if not exist "node_modules" (
    call npm install
    if errorlevel 1 pause & exit /b 1
  )
  call npm run build
  if errorlevel 1 pause & exit /b 1
)

echo Starting Lenovo Spec Server...
start "" "%~dp0..\release\index.html"
cd /d "%~dp0\..\src\server"
python lenovo_spec_server.py
pause
