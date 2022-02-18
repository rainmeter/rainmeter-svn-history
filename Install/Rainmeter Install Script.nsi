#################################################################
#	 Rainmeter installer script for NSIS
#		      version 1.3
#################################################################

!addincludedir "..\Addons\Rainstaller\Source\Include"
!addplugindir "..\Addons\Rainstaller\Source\Include"
!include "MUI2.nsh"
!include "x64.nsh"
!include "ProcFunc.nsh"
!include "UAC.nsh"

#
# Define variables
#
Name "Rainmeter 1.3"
SetCompressor /SOLID lzma
RequestExecutionLevel user
InstallDirRegKey HKLM "SOFTWARE\Rainmeter" ""
XPStyle on

!ifdef X64

!ifdef BETA
OutFile "Rainmeter-Latest-64bit.exe"
!else
OutFile "Rainmeter-1.3-64bit.exe"
!endif
InstallDir "$PROGRAMFILES64\Rainmeter"

!else

!ifdef BETA
OutFile "Rainmeter-Latest-32bit.exe"
!else
OutFile "Rainmeter-1.3-32bit.exe"
!endif
InstallDir "$PROGRAMFILES\Rainmeter"

!endif

Var sel.Gnometer
Var sel.Enigma
Var sel.Desktop
Var sel.Startup
Var sel.AllUsers

#
# Modern UI Configuration
#
!define MUI_HEADERIMAGE
!define MUI_ABORTWARNING

!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
!define MUI_UICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\orange.bmp"
!define MUI_HEADERIMAGE_UNBITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-uninstall.bmp"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_FUNCTION FinishRun

!insertmacro MUI_PAGE_LICENSE "license.txt"
Page custom PageOptions GetOptions
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

#
# Initialization
#
Function .onInit
!ifdef X64
	${If} ${RunningX64}
		${EnableX64FSRedirection}
	${Else}
		MessageBox MB_OK|MB_ICONSTOP "64-bit Rainmeter is not compatible with 32-bit systems.$\n$\nPlease download the 32-bit version of Rainmeter from www.rainmeter.net"
		Abort
	${EndIf}
!endif

# Request administrative rights
UAC_tryagain:
	!insertmacro UAC_RunElevated
	${Switch} $0
	${Case} 0
		${IfThen} $1 = 1 ${|} Quit ${|}
		${IfThen} $3 <> 0 ${|} ${Break} ${|}
		${If} $1 = 3
			MessageBox MB_ICONEXCLAMATION|MB_TOPMOST|MB_SETFOREGROUND "Administrative rights required to continue, aborting." /SD IDNO IDOK UAC_tryagain IDNO 0
		${EndIf}
	${Case} 1223
		MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Administrative rights required to continue, aborting."
		Quit
	${Case} 1062
		MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Logon service not running, aborting!"
		Quit
	${Default}
		MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to elevate, error $0"
		Quit
	${EndSwitch}
FunctionEnd

#
# Options page
#
Function PageOptions
	!insertmacro MUI_HEADER_TEXT "Install options" "Select any additional options"

	nsDialogs::Create 1018
	Pop $0

	${NSD_CreateLabel} 0 0u 98% 12u "Select default theme:"

	${NSD_CreateRadioButton} 8 13u 15% 12u "Gnometer"
 	Pop $sel.Gnometer
	${NSD_Check} $sel.Gnometer

	${NSD_CreateLabel} 105 14u 3% 12u "by"
 	${NSD_CreateLink} 120 14u 10% 12u "poiru"
	Pop $0
	${NSD_OnClick} $0 OpenPoiru

 	${NSD_CreateLink} 170 14u 15% 12u "[Preview]"
	Pop $0
	${NSD_OnClick} $0 OpenPreview

	${NSD_CreateRadioButton} 8 26u 15% 12u "Enigma"
 	Pop $sel.Enigma

	${NSD_CreateLabel} 105 27u 3% 12u "by"
 	${NSD_CreateLink} 120 27u 10% 12u "Kaelri"
	Pop $0
	${NSD_OnClick} $0 OpenKaelri

 	${NSD_CreateLink} 170 27u 15% 12u "[Preview]"
	Pop $0
	${NSD_OnClick} $0 OpenPreview

	${NSD_CreateCheckbox} 0 55u 80% 12u "Add desktop shortcut"
 	Pop $sel.Desktop

 	${NSD_CreateCheckbox} 0 70u 80% 12u "Install Rainmeter for all users"
 	Pop $sel.AllUsers
	
 	${NSD_CreateCheckbox} 0 85u 80% 12u "Automatically start Rainmeter with Windows"
 	Pop $sel.Startup

	ReadRegStr $0 HKLM "Software\Rainmeter" ""
	StrCmp $0 "" skip 0

	SetShellVarContext all
	Call GetEnvPaths
	StrCpy $R1 $1
	StrCpy $R2 $2
	StrCpy $R3 $3
	SetShellVarContext current
	!insertmacro UAC_AsUser_Call Function GetEnvPaths ${UAC_SYNCREGISTERS}

	${If} ${FileExists} "$R1\Rainmeter\Rainmeter.lnk"
		${NSD_Check} $sel.AllUsers
	${EndIf}
	${If} ${FileExists} "$R2\Rainmeter.lnk"
	${OrIf} ${FileExists} "$2\Rainmeter.lnk"
		${NSD_Check} $sel.Startup
	${EndIf}
	${If} ${FileExists} "$R3\Rainmeter.lnk"
	${OrIf} ${FileExists} "$3\Rainmeter.lnk"
		${NSD_Check} $sel.Desktop
	${EndIf}

	Goto continue

skip:
	${NSD_Check} $sel.Startup
	${NSD_Check} $sel.AllUsers

continue:
	nsDialogs::Show
FunctionEnd

Function OpenPoiru
	ExecShell "open" "http://poiru.deviantart.com"
FunctionEnd

Function OpenKaelri
	ExecShell "open" "http://kaelri.deviantart.com"
FunctionEnd

Function OpenPreview
	ExecShell "open" "http://rainmeter.net/RainCMS/?q=DefaultSkins"
FunctionEnd

Function GetOptions
	${NSD_GetState} $sel.Gnometer $sel.Gnometer
	${NSD_GetState} $sel.Enigma $sel.Enigma
	${NSD_GetState} $sel.Desktop $sel.Desktop
	${NSD_GetState} $sel.Startup $sel.Startup
	${NSD_GetState} $sel.AllUsers $sel.AllUsers
FunctionEnd

#
# Install
#
!macro InstallFiles Folder
	File "..\Distrib\${Folder}\*.*"
	SetOutPath "$INSTDIR\Plugins"
	File /r "..\Distrib\${Folder}\Plugins\*.*"
	SetOutPath "$INSTDIR\Addons"
	File /r "..\Distrib\${Folder}\Addons\*.*"

	${IfNot} ${FileExists} "$FONTS\seguibk.ttf"
	${OrIfNot} ${FileExists} "$FONTS\seguibd.ttf"
	${OrIfNot} ${FileExists} "$FONTS\segoeui.ttf"
	${OrIfNot} ${FileExists} "$FONTS\segoeuib.ttf"
		SetOutPath "$PLUGINSDIR\Fonts"
		File "..\Addons\Rainstaller\Source\Include\*.ttf"
		File "..\Addons\Rainstaller\Source\Include\FontReg.exe"
		ExecWait '"$PLUGINSDIR\Fonts\FontReg.exe" /copy'
		SetOutPath "$INSTDIR"
	${EndIf}

	IfFileExists $INSTDIR\Rainmeter.ini 0 RainmeterIniDoesntExistLabelInstall
	MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to upgrade the default skins and themes as well?$\n$\n(All previous changes will overwritten)" IDNO RainmeterNoSkinInstallation

RainmeterIniDoesntExistLabelInstall:
# Remove the old skins
	RMDir /r "$INSTDIR\Skins\Gnometer"
	RMDir /r "$INSTDIR\Skins\Tranquil"
	RMDir /r "$INSTDIR\Skins\Enigma"
	RMDir /r "$INSTDIR\Skins\Arcs"

	SetOutPath "$INSTDIR\Skins"
	File /r /x *.db "..\Distrib\${Folder}\Skins\*.*"
	SetOutPath "$INSTDIR\Themes"
	File /r "..\Distrib\${Folder}\Themes\*.*"

	${If} $sel.Gnometer == "1"
	      CopyFiles /SILENT "$INSTDIR\Themes\Gnometer\Rainmeter.thm" "$INSTDIR\Default.ini"
	${ElseIf} $sel.Enigma == "1"
	      CopyFiles /SILENT "$INSTDIR\Themes\Enigma\Rainmeter.thm" "$INSTDIR\Default.ini"
	${EndIf}

RainmeterNoSkinInstallation:
	SetOutPath "$INSTDIR"
!macroend

!macro RemoveShortcuts
# $1 = $SMPROGRAMS, $2 = $SMSTARTUP, $3 = $DESKTOP
	Delete "$1\Rainmeter\Rainmeter.lnk"
	Delete "$1\Rainmeter\Rainmeter Help.lnk"
	Delete "$1\Rainmeter\Rainmeter Help.URL"
	Delete "$1\Rainmeter\Remove Rainmeter.lnk"
	Delete "$1\Rainmeter\RainThemes.lnk"
	Delete "$1\Rainmeter\RainThemes Help.lnk"
	Delete "$1\Rainmeter\RainBrowser.lnk"
	Delete "$1\Rainmeter\RainBackup.lnk"
	Delete "$1\Rainmeter\Rainstaller.lnk"
	Delete "$1\Rainmeter\Rainstaller Help.lnk"
	RMDir "$1\Rainmeter"
	Delete "$2\Rainmeter.lnk"
	Delete "$3\Rainmeter.lnk"
!macroend

Section
# Close Rainmeter if running
	FindWindow $0 "RainmeterTrayClass"
	IsWindow $0 0 RainmeterDoesntExist
		Exec '"$INSTDIR\Rainmeter.exe" !RainmeterQuit'
		StrCpy $1 0
		Sleep 500

RainmeterCheckAgain:
	FindWindow $0 "RainmeterTrayClass"
	IsWindow $0 0 RainmeterDoesntExist
		SendMessage $0 ${WM_CLOSE} 0 0
		StrCmp $1 10 0 +3
			MessageBox MB_ICONSTOP|MB_RETRYCANCEL "Failed to close Rainmeter.$\n$\nPlease close Rainmeter manually and try again." IDRETRY RainmeterCheckAgain
			Quit
		IntOp $1 $1 + 1
		Sleep 500
		Goto RainmeterCheckAgain

RainmeterDoesntExist:
	FindWindow $0 "AutoIt v3 GUI" "RainBrowser"
	IsWindow $0 0 RainBrowserDoesntExist
		${TerminateProcess} "RainBrowser.exe" $0
		Sleep 100
		Goto RainmeterDoesntExist

RainBrowserDoesntExist:
	SetOutPath "$INSTDIR"
	SetShellVarContext current

# Check if Rainmeter.ini is located in the installation folder and
# if the installation folder is in Program Files
	IfFileExists $INSTDIR\Rainmeter.ini 0 RainmeterIniDoesntExistLabel
	!ifdef X64
		StrCmp $INSTDIR "$PROGRAMFILES64\Rainmeter" 0 RainmeterIniDoesntExistLabel
	!else
		StrCmp $INSTDIR "$PROGRAMFILES\Rainmeter" 0 RainmeterIniDoesntExistLabel
	!endif

	MessageBox MB_YESNO|MB_ICONEXCLAMATION "It seems that the Rainmeter's settings file (Rainmeter.ini)$\nis located in the installation folder. Keeping it there can$\ncause problems if the application is used by multiple users$\nor anyone with restricted user privileges.$\n$\nDo you want to move the file to the application data folder?" IDNO RainmeterIniDoesntExistLabel
	CreateDirectory $APPDATA\Rainmeter
	Rename $INSTDIR\Rainmeter.ini $APPDATA\Rainmeter\Rainmeter.ini
	IfErrors 0 RainmeterIniDoesntExistLabel
		MessageBox MB_OK|MB_ICONSTOP "Unable to move the file $INSTDIR\Rainmeter.ini to $APPDATA\Rainmeter\Rainmeter.ini"

RainmeterIniDoesntExistLabel:
	Delete "$INSTDIR\Rainmeter.chm"

	!ifdef X64
		!insertmacro InstallFiles "x64"
		ExecWait '"$INSTDIR\vcredist_x64.exe" /q:a /c:"VCREDI~1.EXE /q:a /c:""msiexec /i vcredist.msi /q"" "'
	!else
		!insertmacro InstallFiles "x32"
		ExecWait '"$INSTDIR\vcredist_x86.exe" /q:a /c:"VCREDI~1.EXE /q:a /c:""msiexec /i vcredist.msi /q"" "'
	!endif

# Write registry keys
	WriteRegStr HKLM "SOFTWARE\Rainmeter" "" "$INSTDIR"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "DisplayName" "Rainmeter (remove only)"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter" "UninstallString" '"$INSTDIR\uninst.exe"'
	WriteRegStr HKCR ".rmskin" "" "Rainmeter skin"
	WriteRegStr HKCR "Rainmeter skin" "" "Rainmeter skin file"
	WriteRegStr HKCR "Rainmeter skin\shell" "" "open"
	WriteRegStr HKCR "Rainmeter skin\DefaultIcon" "" "$INSTDIR\Addons\Rainstaller\Rainstaller.exe,0"
	WriteRegStr HKCR "Rainmeter skin\shell\open\command" "" '"$INSTDIR\Addons\Rainstaller\Rainstaller.exe" %1'
	WriteRegStr HKCR "Rainmeter skin\shell\edit" "" "Install Rainmeter skin"
	WriteRegStr HKCR "Rainmeter skin\shell\edit\command" "" '"$INSTDIR\Addons\Rainstaller\Rainstaller.exe" %1'
	System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'
	WriteUninstaller "$INSTDIR\uninst.exe"

# Remove all shortcuts
	${If} $sel.AllUsers == "1"
		SetShellVarContext current
		Call GetEnvPaths
		!insertmacro RemoveShortcuts
		!insertmacro UAC_AsUser_Call Function GetEnvPaths ${UAC_SYNCREGISTERS}
		!insertmacro RemoveShortcuts
		SetShellVarContext all
		Call GetEnvPaths
		!insertmacro RemoveShortcuts
	${Else}
		SetShellVarContext all
		Call GetEnvPaths
		!insertmacro RemoveShortcuts
		SetShellVarContext current
		Call GetEnvPaths
		!insertmacro RemoveShortcuts
		!insertmacro UAC_AsUser_Call Function GetEnvPaths ${UAC_SYNCREGISTERS}
		!insertmacro RemoveShortcuts
	${EndIf}

# Create shortcuts
# $1 = $SMPROGRAMS, $2 = $SMSTARTUP, $3 = $DESKTOP
	CreateDirectory "$1\Rainmeter"
	CreateShortCut "$1\Rainmeter\Rainmeter.lnk" "$INSTDIR\Rainmeter.exe" "" "$INSTDIR\Rainmeter.exe" 0
	!ifdef BETA
		WriteINIStr "$1\Rainmeter\Rainmeter Help.URL" "InternetShortcut" "URL" "http://rainmeter.net/RainCMS/?q=ManualBeta"
	!else
		WriteINIStr "$1\Rainmeter\Rainmeter Help.URL" "InternetShortcut" "URL" "http://rainmeter.net/RainCMS/?q=Manual"
	!endif
	CreateShortCut "$1\Rainmeter\Remove Rainmeter.lnk" "$INSTDIR\uninst.exe" "" "$INSTDIR\uninst.exe" 0

	SetOutPath "$INSTDIR\Addons\RainThemes"
	CreateShortCut "$1\Rainmeter\RainThemes.lnk" "$INSTDIR\Addons\RainThemes\RainThemes.exe" "" "$INSTDIR\Addons\RainThemes\RainThemes.exe" 0

	SetOutPath "$INSTDIR\Addons\RainBrowser"
	CreateShortCut "$1\Rainmeter\RainBrowser.lnk" "$INSTDIR\Addons\RainBrowser\RainBrowser.exe" "" "$INSTDIR\Addons\RainBrowser\RainBrowser.exe" 0

	SetOutPath "$INSTDIR\Addons\RainBackup"
	CreateShortCut "$1\Rainmeter\RainBackup.lnk" "$INSTDIR\Addons\RainBackup\RainBackup.exe" "" "$INSTDIR\Addons\RainBackup\RainBackup.exe" 0

	SetOutPath "$INSTDIR\Addons\Rainstaller"
	CreateShortCut "$1\Rainmeter\Rainstaller.lnk" "$INSTDIR\Addons\Rainstaller\Rainstaller.exe" "" "$INSTDIR\Addons\Rainstaller\Rainstaller.exe" 0
	SetOutPath "$INSTDIR"

	${If} $sel.Startup == "1"
		CreateShortCut  "$2\Rainmeter.lnk" "$INSTDIR\Rainmeter.exe" "" "$INSTDIR\Rainmeter.exe" 0
	${EndIf}

	${If} $sel.Desktop == "1"
		CreateShortCut  "$3\Rainmeter.lnk" "$INSTDIR\Rainmeter.exe" "" "$INSTDIR\Rainmeter.exe" 0
	${EndIf}
SectionEnd

Function GetEnvPaths
	StrCpy $1 $SMPROGRAMS
	StrCpy $2 $SMSTARTUP
	StrCpy $3 $DESKTOP
FunctionEnd

Function FinishRun
	!insertmacro UAC_AsUser_ExecShell "" "$INSTDIR\Rainmeter.exe" "" "" ""
FunctionEnd

#
# Uninstall
#
Function un.onInit
UAC_tryagain:
# Request administrative rights
	!insertmacro UAC_RunElevated
	${Switch} $0
	${Case} 0
		${IfThen} $1 = 1 ${|} Quit ${|}
		${IfThen} $3 <> 0 ${|} ${Break} ${|}
		${If} $1 = 3
			MessageBox MB_ICONEXCLAMATION|MB_TOPMOST|MB_SETFOREGROUND "Administrative rights required to continue, aborting." /SD IDNO IDOK UAC_tryagain IDNO 0
		${EndIf}
	${Case} 1223
		MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Administrative rights required to continue, aborting."
		Quit
	${Case} 1062
		MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Logon service not running, aborting!"
		Quit
	${Default}
		MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to elevate, error $0"
		Quit
	${EndSwitch}
FunctionEnd

!macro UninstallSkin Folder
	RMDir /r "${Folder}\Skins\Gnometer"
	RMDir /r "${Folder}\Skins\Tranquil"
	RMDir /r "${Folder}\Skins\Enigma"
	RMDir /r "${Folder}\Skins\Arcs"
	Delete "${Folder}\Skins\*.txt"
	RMDir "${Folder}\Skins"
!macroend

Section Uninstall
RainmeterCheckAgain2:
	FindWindow $0 "RainmeterTrayClass"
	IsWindow $0 0 RainmeterDoesntExistLabel2
		MessageBox MB_ABORTRETRYIGNORE|MB_ICONSTOP "Rainmeter must be closed in order to continue.$\nPlease close Rainmeter and try again." IDRETRY RainmeterCheckAgain2 IDIGNORE RainmeterDoesntExistLabel2
		Abort

RainmeterDoesntExistLabel2:
	!insertmacro UninstallSkin "$INSTDIR"
	!insertmacro UninstallSkin "$DOCUMENTS\Rainmeter"
	RMDir "$DOCUMENTS\Rainmeter"

	Delete "$INSTDIR\Plugins\*.*"
	RMDir "$INSTDIR\Plugins"
	Delete "$INSTDIR\Addons\RainThemes\*.*"
	RMDir "$INSTDIR\Addons\RainThemes"
	Delete "$INSTDIR\Addons\RainBrowser\*.*"
	RMDir "$INSTDIR\Addons\RainBrowser"
	Delete "$INSTDIR\Addons\RainBackup\*.*"
	RMDir "$INSTDIR\Addons\RainBackup"
	Delete "$INSTDIR\Addons\Rainstaller\*.*"
	RMDir "$INSTDIR\Addons\Rainstaller"
	RMDir "$INSTDIR\Addons"
	RMDir /r "$INSTDIR\Themes"
	Delete "$INSTDIR\*.*"

	DeleteRegKey HKLM "SOFTWARE\Rainmeter"
	DeleteRegKey HKCR ".rmskin"
	DeleteRegKey HKCR "Rainmeter skin"
	DeleteRegKey HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Rainmeter"
	System::Call 'Shell32::SHChangeNotify(i 0x8000000, i 0, i 0, i 0)'

	RMDir "$INSTDIR"
	RMDir /r "$APPDATA\Rainmeter"

	SetShellVarContext current
	Call un.GetEnvPaths
	!insertmacro RemoveShortcuts
	!insertmacro UAC_AsUser_Call Function un.GetEnvPaths ${UAC_SYNCREGISTERS}
	!insertmacro RemoveShortcuts

	SetShellVarContext all
	Call un.GetEnvPaths
	!insertmacro RemoveShortcuts

	IfFileExists "$INSTDIR" 0 +2
		MessageBox MB_OK "Note: $INSTDIR could not be removed!"
SectionEnd

Function un.GetEnvPaths
	StrCpy $1 $SMPROGRAMS
	StrCpy $2 $SMSTARTUP
	StrCpy $3 $DESKTOP
FunctionEnd

; eof