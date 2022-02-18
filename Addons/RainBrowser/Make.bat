@echo off
cls
rem Change the path to hhc.exe to where you have HTML Worksthop installed
rem Echo Compiling RainThemes Help...
rem "C:\Program Files\HTML Help Workshop\hhc.exe" ".\Help\RainThemes.hhp"
rem move ".\Help\RainThemes.chm" ".\Source\RainThemes.chm"
rem Echo.
Echo Compiling RainBrowser...
".\AutoIt3\Aut2Exe\Aut2exe.exe" /in ".\Source\RainBrowser.au3" /icon ".\Source\RainBrowser.ico" /out ".\Release\RainBrowser.exe"
Echo.
Echo Build complete
Echo The distribution RainBrowser.exe is in .\RainBrowser Release

