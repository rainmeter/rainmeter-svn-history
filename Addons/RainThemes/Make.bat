@echo off
cls
rem Change the path to hhc.exe to where you have HTML Worksthop installed
Echo Compiling RainThemes Help...
"C:\Program Files\HTML Help Workshop\hhc.exe" ".\Help\RainThemes.hhp"
move ".\Help\RainThemes.chm" ".\Source\RainThemes.chm"
Echo.
Echo Compiling RainThemes...
".\AutoIt3\Aut2Exe\Aut2exe.exe" /in ".\Source\RainThemes.au3" /icon ".\Source\RainThemes.ico" /out ".\Release\RainThemes.exe"
Echo.
Echo Build complete
Echo The distribution RainThemes.exe is in .\RainThemes Release

