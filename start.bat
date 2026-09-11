@echo off
title Mantra MFS100 Web Bridge (Port 8004)
echo ==========================================================
echo Starting Mantra MFS100 Chrome Web Bridge on Port 8004...
echo ==========================================================
cd /d "%~dp0"
"C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe" -ExecutionPolicy Bypass -File "%~dp0run_mfs100.ps1"
pause
