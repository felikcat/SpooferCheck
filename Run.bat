@echo off
cd %~dp0

.\Third-party\NanaRun\MinSudo.exe --NoLogo --Privileged powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process powershell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "".\src\main.ps1""' -Verb RunAs}"
