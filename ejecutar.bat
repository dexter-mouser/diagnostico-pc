@echo off
rem Abre el diagnóstico como administrador (necesario para leer los datos SMART de los discos)
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%~dp0diagnostico.ps1\"'"
