@echo off
Powershell.exe -noprofile -executionpolicy bypass -file "_make_air_file.ps1"
Powershell.exe -noprofile -executionpolicy bypass -file "_make_exe_file.ps1"