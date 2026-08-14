@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Codex-Launcher.ps1" %*
exit /b %ERRORLEVEL%
