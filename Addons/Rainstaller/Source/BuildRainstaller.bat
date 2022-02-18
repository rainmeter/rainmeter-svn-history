@echo off
cls
"C:\Program Files\NSIS\makensis.exe" ".\Rainstaller.nsi"
move .\Rainstaller.exe ..\Release\Rainstaller.exe
echo.
echo Done...
pause

