# Rainstaller, © 2010 poiru
# Distributed under the 'Creative Commons Attribution-Non-Commercial-Share Alike 3.0' license
#	UAC plugin: http://nsis.sourceforge.net/UAC_plug-in
#	nsisunz: http://nsis.sourceforge.net/Nsisunz_plug-in
#	FontReg: http://code.kliu.org/misc/fontreg
# =====================================================================================================

!addincludedir "Include"
!addplugindir "Include"
!include "nsDialogs.nsh"
!include "FileFunc.nsh"
!include "TextFunc.nsh"
!include "WordFunc.nsh"
!include "ProcFunc.nsh"
!include "UAC.nsh"
!include "RainstallerFunc.nsh"
!define VERSION "2.1.0.0"

VIAddVersionKey "ProductName" "Rainstaller"
VIAddVersionKey "Comments" "Rainstaller"
VIAddVersionKey "CompanyName" "poiru"
VIAddVersionKey "LegalCopyright" "© poiru"
VIAddVersionKey "FileDescription" "Rainstaller"
VIAddVersionKey "FileVersion" "1.0.0"
VIProductVersion "${VERSION}"

Name "Rainstaller"
Caption "Rainstaller"
OutFile "..\Release\Rainstaller.exe"
Icon "Include\InstIcon.ico"
ChangeUI all "Include\UI.exe"
CRCCheck force
XPStyle on
RequestExecutionLevel user

Var Name
Var Author
Var Version
Var CompatibleWithBit
Var LaunchType
Var LaunchCommand
Var KeepVar
Var RainmeterFonts
Var MinRainmeterVer
Var Merge

Var var
Var Date
Var Root
Var FontBold
Var Font
Var Footnote
Var SkinList
Var SkinListF
Var ThemeList
Var ThemeListF
Var AddonList
Var AddonListF
Var PluginList
Var PluginListF
Var FontList
Var FontListF
Var selLaunch
Var selApply
Var btnInstall
Var SKINSPATH
Var SETTINGSPATH

Page custom Rainstaller

Function .onInit
# Detect file parameter
# ==============================================================
	${GetParameters} $R0

	StrCpy $0 $R0 3 1
	StrCmp $0 "UAC" UACskip 0

# Check if Rainmeter.exe exists
# ==============================================================
	IfFileExists "$EXEDIR\..\..\Rainmeter.exe" +3 0
		MessageBox MB_OK|MB_ICONSTOP "Error: Rainmeter.exe not found.$\nMake sure that you have downloaded and installed the latest version of Rainmeter from www.rainmeter.net."
		Call QuitCleanup

# Quit if another instance of Rainstaller is already running
# ==============================================================
	System::Call "kernel32::CreateMutexA(i 0, i 0, t '$(^Name)') i .r0 ?e"
	Pop $0
	StrCmp $0 0 continue
	StrLen $0 "$(^Name)"
	IntOp $0 $0 + 1
loop:
	FindWindow $1 '#32770' '' 0 $1
	IntCmp $1 0 +4
	System::Call "user32::GetWindowText(i r1, t .r2, i r0) i."
	StrCmp $2 "$(^Name)" 0 loop
	System::Call "user32::SetForegroundWindow(i r1) i."
	Abort
continue:

# Prompt to browse for .rmskin if file parameter not specfied
# ==============================================================
	${If} $R0 == ""
		nsDialogs::SelectFileDialog /NOUNLOAD "open" "$DESKTOP" "Rainmeter skin file (.rmskin)|*.rmskin"
		Pop $R0

		StrCmp $R0 "" 0 +2
		Call QuitCleanup
	${EndIf}

	StrCpy $0 $R0 1 ""

	${If} $0 == '"'
		StrLen $1 $R0
		IntOp $1 $1 - 2
		StrCpy $R0 $R0 $1 1
	${EndIf}

	${GetFileExt} "$R0" $0

	${If} $0 == "rmskin"
	${ElseIf} $0 == "zip"
	${Else}
		MessageBox MB_OK|MB_ICONSTOP "Error: Invalid filetype."
		Call QuitCleanup
	${EndIf}

# Get location of Skins folder and Rainmeter.ini
# ==============================================================
	StrCpy $SETTINGSPATH "$EXEDIR\..\.."
	ReadINIStr $0 "$SETTINGSPATH\Rainmeter.ini" Rainmeter SkinPath
	StrCmp $0 "" 0 +3
	StrCpy $SETTINGSPATH "$APPDATA\Rainmeter"
	ReadINIStr $0 "$SETTINGSPATH\Rainmeter.ini" Rainmeter SkinPath

	${If} $0 == ""
		MessageBox MB_OK|MB_ICONSTOP "Error: SkinPath not found in Rainmeter.ini.$\nMake sure that Rainmeter has been run at least once."
		Call QuitCleanup
	${EndIf}

	StrLen $1 $0
	IntOp $1 $1 - 1
	StrCpy $SKINSPATH $0 $1 0

# Unzip specified rmskin
# ==============================================================
	SetShellVarContext all
	RMDir /r "$APPDATA\Rainstaller"
	Banner::show "Extracting, please wait..."
	Sleep 500
	CreateDirectory "$APPDATA\Rainstaller"
	SetOutPath "$APPDATA\Rainstaller"
	File "Include\Rainstaller.bmp"
	nsisunz::Unzip $R0 "$APPDATA\Rainstaller"
	SetOutPath "$PLUGINSDIR"
	Banner::destroy

	WriteINIStr "$APPDATA\Rainstaller\temp" Temp SETTINGSPATH $SETTINGSPATH
	WriteINIStr "$APPDATA\Rainstaller\temp" Temp SKINSPATH $SKINSPATH
	CreateDirectory "$SETTINGSPATH\Themes"
	CreateDirectory "$SKINSPATH"

UACskip:
# Read settings from Rainstaller.cfg
# ==============================================================
	SetShellVarContext all
	CreateDirectory "$APPDATA\Rainstaller"
	${Locate} "$APPDATA\Rainstaller" "/L=F /M=Rainstaller.cfg" "FindRoot"

	ReadINIStr $Name "$Root\Rainstaller.cfg" Rainstaller Name
	ReadINIStr $Author "$Root\Rainstaller.cfg" Rainstaller Author
	ReadINIStr $Version "$Root\Rainstaller.cfg" Rainstaller Version
	ReadINIStr $CompatibleWithBit "$Root\Rainstaller.cfg" Rainstaller CompatibleWithBit
	ReadINIStr $LaunchType "$Root\Rainstaller.cfg" Rainstaller LaunchType
	ReadINIStr $LaunchCommand "$Root\Rainstaller.cfg" Rainstaller LaunchCommand
	ReadINIStr $KeepVar "$Root\Rainstaller.cfg" Rainstaller KeepVar
	ReadINIStr $RainmeterFonts "$Root\Rainstaller.cfg" Rainstaller RainmeterFonts
	ReadINIStr $MinRainmeterVer "$Root\Rainstaller.cfg" Rainstaller MinRainmeterVer
	ReadINIStr $Merge "$Root\Rainstaller.cfg" Rainstaller Merge

	${If} $Name == ""
		MessageBox MB_OK|MB_ICONSTOP "Error: Invalid file."
		Call QuitCleanup
 	${EndIf}
	${If} $CompatibleWithBit == "64"
	${OrIf} $CompatibleWithBit == "64bit"
		!ifdef x32
		MessageBox MB_OK|MB_ICONSTOP "Error: This Rainmeter skin package is not compatible with 32bit versions of Rainmeter."
		Call QuitCleanup
		!endif
	${ElseIf} $CompatibleWithBit == "32"
	${OrIf} $CompatibleWithBit == "32bit"
		!ifdef x64
		MessageBox MB_OK|MB_ICONSTOP "Error: This Rainmeter skin package is not compatible with 64bit versions of Rainmeter."
		Call QuitCleanup
		!endif
	${EndIf}
	${If} $Merge == "1"
		${Locate} "$Root\Skins" "/L=D /G=0" "MergeCheck"
	${EndIf}

	${If} ${FileExists} "$Root\Plugins\*.*"
		Delete "$Root\Plugins\AdvancedCPU.dll"
		Delete "$Root\Plugins\ExamplePlugin.dll"
		Delete "$Root\Plugins\iTunesPlugin.dll"
		Delete "$Root\Plugins\MBM5Plugin.dll"
		Delete "$Root\Plugins\MediaKey.dll"
		Delete "$Root\Plugins\PerfMon.dll"
		Delete "$Root\Plugins\PingPlugin.dll"
		Delete "$Root\Plugins\PowerPlugin.dll"
		Delete "$Root\Plugins\QuotePlugin.dll"
		Delete "$Root\Plugins\RecycleManager.dll"
		Delete "$Root\Plugins\ResMon.dll"
		Delete "$Root\Plugins\SpeedFanPlugin.dll"
		Delete "$Root\Plugins\SysInfo.dll"
		Delete "$Root\Plugins\VirtualDesktops.dll"
		Delete "$Root\Plugins\WebParser.dll"
		Delete "$Root\Plugins\WifiStatus.dll"
		Delete "$Root\Plugins\Win7AudioPlugin.dll"
		Delete "$Root\Plugins\WindowMessagePlugin.dll"
		Delete "$Root\Plugins\WirelessInfo.dll"
	${EndIf}
	${If} ${FileExists} "$Root\Addons\*.*"
		RMDir /r "$Root\Addons\RainBackup"
		RMDir /r "$Root\Addons\RainBrowser"
		RMDir /r "$Root\Addons\Rainstaller"
		RMDir /r "$Root\Addons\RainThemes"
	${EndIf}

# Check if required Rainmeter version is installed
# ==============================================================
	${If} $MinRainmeterVer != ""
		GetDLLVersion "$EXEDIR\..\..\Rainmeter.exe" $R0 $R1
		IntOp $R2 $R0 / 0x00010000
		IntOp $R3 $R0 & 0x0000FFFF
		IntOp $R4 $R1 / 0x00010000
		IntOp $R5 $R1 & 0x0000FFFF
		StrCpy $0 "$R2.$R3.$R4.$R5"
		${VersionCompare} "$0" "$MinRainmeterVer" $R0

		${If} $R0 == "2"
			MessageBox MB_OK|MB_ICONSTOP "Error: Rainmeter $MinRainmeterVer or higher is required to continue.$\nDownload and install the latest Rainmeter version from www.rainmeter.net and try again."
			Call QuitCleanup
		${EndIf}
	${EndIf}

# Request administrative rights
# ==============================================================
	${If} ${FileExists} "$Root\Addons\*.*"
	${OrIf} ${FileExists} "$Root\Plugins\*.dll"
	${OrIf} ${FileExists} "$Root\Fonts\*.ttf"
UAC_tryagain:
		!insertmacro UAC_RunElevated
		${Switch} $0
		${Case} 0
			${IfThen} $1 = 1 ${|} Quit ${|}
			${IfThen} $3 <> 0 ${|} ${Break} ${|}
			${If} $1 = 3
				MessageBox MB_ICONEXCLAMATION|MB_TOPMOST|MB_SETFOREGROUND "The skin you're trying to install requires administrative rights." /SD IDNO IDOK UAC_tryagain IDNO 0
			${EndIf}
		${Case} 1223
			MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "The skin you're trying to install requires administrative rights."
			Call QuitCleanup
		${Case} 1062
			MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Logon service not running, aborting!"
			Call QuitCleanup
		${Default}
			MessageBox MB_ICONSTOP|MB_TOPMOST|MB_SETFOREGROUND "Unable to elevate, error $0"
			Call QuitCleanup
		${EndSwitch}
	${EndIf}

	ReadINIStr $SETTINGSPATH "$APPDATA\Rainstaller\temp" Temp SETTINGSPATH
	ReadINIStr $SKINSPATH "$APPDATA\Rainstaller\temp" Temp SKINSPATH

	Call GetBackupList

	CreateFont $Font "Segoe UI" "8" "0"
	CreateFont $FontBold "Segoe UI" "8" "700"
FunctionEnd

Function FindRoot
	StrCpy $Root $R8

	Push "StopLocate"
FunctionEnd

Function MergeCheck
	IfFileExists "$SKINSPATH\$R7\*.*" +3 0
		MessageBox MB_OK|MB_ICONSTOP "'$R7' must be installed in order to continue."
		Call QuitCleanup

	Push $var
FunctionEnd

Function Rainstaller
	StrCpy $0 $HWNDPARENT
	System::Call "user32::SetWindowPos(i r0, i -1, i 0, i 0, i 0, i 0, i 3)"
	nsDialogs::Create /NOUNLOAD 1018
	System::Call "user32::SetWindowPos(i r0, i -2, i 0, i 0, i 0, i 0, i 3)"

	StrCpy $1 "$APPDATA\Rainstaller\Rainstaller.bmp"
	IfFileExists "$Root\Rainstaller.bmp" 0 +2
	StrCpy $1 "$Root\Rainstaller.bmp"
	GetDlgItem $0 $HWNDPARENT 102
	${NSD_SetImage} $0 "$1" $0

	${NSD_CreateGroupBox} 8 0u 96% 44u ""

	${NSD_CreateLabel} 18 8u 30% 11u "Name:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0

	${NSD_CreateLabel} 18 19u 30% 11u "Author:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0
	
	${NSD_CreateLabel} 18 30u 30% 11u "Version:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0

	${NSD_CreateLabel} 78 8u 75% 11u "$Name"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0

	${NSD_CreateLabel} 78 19u 75% 11u "$Author"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0
	
	${NSD_CreateLabel} 78 30u 75% 11u "$Version"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0

	${NSD_CreateGroupBox} 8 44u 96% 96u ""

	${NSD_CreateLabel} 18 52u 15% 11u "Skins:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0

	IfFileExists "$Root\Skins\*.*" +2 0
		EnableWindow $0 0

	${NSD_CreateLabel} 18 63u 15% 11u "Themes:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0
	IfFileExists "$Root\Themes\*.*" +2 0
		EnableWindow $0 0

	${NSD_CreateLabel} 18 74u 15% 11u "Addons:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0
	IfFileExists "$Root\Addons\*.*" +2 0
		EnableWindow $0 0

	${NSD_CreateLabel} 18 85u 15% 11u "Plugins:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0
	IfFileExists "$Root\Plugins\*.dll" +2 0
		EnableWindow $0 0

	${NSD_CreateLabel} 18 96u 15% 11u "Fonts:"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $FontBold 0
	StrCmp $FontList "" 0 +2
	EnableWindow $0 0

	${NSD_CreateLabel} 78 52u 75% 11u "$SkinList"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0

	${NSD_CreateLabel} 78 63u 75% 11u "$ThemeList"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0

	${NSD_CreateLabel} 78 74u 75% 11u "$AddonList"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0

	${NSD_CreateLabel} 78 85u 75% 11u "$PluginList"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0

	${NSD_CreateLabel} 78 96u 75% 11u "$FontList"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0

	${NSD_CreateLink} 335 107u 13% 11u "$ShowAll"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0
	${NSD_OnClick} $0 ShowAll

	${NSD_CreateCheckBox} 18 113u 75% 11u "Apply '$LaunchCommand' theme"
	Pop $selApply
	SendMessage $selApply ${WM_SETFONT} $Font 0
	${NSD_Check} $selApply
	
	${If} $LaunchType == "Theme"
		ShowWindow $selApply ${SW_SHOW}
	${Else}
		ShowWindow $selApply ${SW_HIDE}
	${EndIf}

	${NSD_CreateCheckBox} 18 124u 75% 11u "Launch Rainmeter automatically after install"
	Pop $selLaunch
	SendMessage $selLaunch ${WM_SETFONT} $Font 0
	${NSD_Check} $selLaunch

	${NSD_CreateLabel} 8 147u 70% 11u "$Footnote"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0
	SetCtlColors $0 0x4C4C4C transparent
	
	${NSD_CreateLabel} 8 159u 70% 11u "Rainstaller by poiru"
	Pop $0
	SendMessage $0 ${WM_SETFONT} $Font 0
	EnableWindow $0 0

	${NSD_CreateButton} 302 147u 60u 22u "Install"
	Pop $btnInstall
	SendMessage $btnInstall ${WM_SETFONT} $Font 0
	SendMessage $HWNDPARENT ${WM_NEXTDLGCTL} $btnInstall 1
	${NSD_OnClick} $btnInstall Install

	nsDialogs::Show
FunctionEnd

Function GetBackupList
	${GetTime} "" "L" $1 $2 $3 $0 $4 $5 $0
	StrCpy $Date " ($3.$2.$1 $4.$5)"

	${Locate} "$Root\Skins" "/L=D /G=0" "GetSkinList"
	${Locate} "$Root\Themes" "/L=D /G=0" "GetThemeList"
	${Locate} "$Root\Addons" "/L=D /G=0" "GetAddonList"
	${Locate} "$Root\Plugins" "/L=F /G=0 /M=*.dll" "GetPluginList"
	${Locate} "$Root\Fonts" "/L=F /G=0 /M=*.ttf" "GetFontList"
	
	StrCpy $SkinListF $SkinListF "" 2
	StrCpy $ThemeListF $ThemeListF "" 2
	StrCpy $AddonListF $AddonListF "" 2
	StrCpy $PluginListF $PluginListF "" 2
	StrCpy $FontListF $FontListF "" 2

	${TrimText} "$SkinListF" 60 "," $SkinList
	${TrimText} "$ThemeListF" 60 "," $ThemeList
	${TrimText} "$AddonListF" 60 "," $AddonList
	${TrimText} "$PluginListF" 60 "," $PluginList
	${TrimText} "$FontListF" 60 "," $FontList
FunctionEnd

Function GetSkinList
	StrCpy $SkinListF "$SkinListF, $R7"
	IfFileExists "$SKINSPATH\$R7\*.*" 0 +3
	StrCpy $SkinListF "$SkinListF*"
	StrCpy $Footnote "* component will be backed up and replaced"

	Push $var
FunctionEnd

Function GetThemeList
	StrCpy $ThemeListF "$ThemeListF, $R7"
	IfFileExists "$SETTINGSPATH\Themes\$R7\*.*" 0 +3
	StrCpy $ThemeListF "$ThemeListF*"
	StrCpy $Footnote "* component will be backed up and replaced"

	Push $var
FunctionEnd

Function GetAddonList
	StrCpy $AddonListF "$AddonListF, $R7"
	IfFileExists "$EXEDIR\..\..\Addons\$R7\*.*" 0 +3
	StrCpy $AddonListF "$AddonListF*"
	StrCpy $Footnote "* component will be backed up and replaced"

	Push $var
FunctionEnd

Function GetPluginList
	StrCpy $PluginListF "$PluginListF, $R7"
	IfFileExists "$EXEDIR\..\..\Plugins\$R7" 0 +3
	StrCpy $PluginListF "$PluginListF*"
	StrCpy $Footnote "* component will be backed up and replaced"
	
	Push $var
FunctionEnd

Function GetFontList
	System::Call "gdi32::AddFontResource(t '$Root\Fonts\$R7')"
	Push "$Root\Fonts\$R7"
	Call GetFontName
	Pop $R0
	System::Call "gdi32::RemoveFontResource(t '$Root\Fonts\$R7')"

	${If} $R0 != "error"
		StrCpy $FontListF "$FontListF, $R0"
	${EndIf}

	IfFileExists "$FONTS\$R7" 0 +2
		Delete "$Root\Fonts\$R7"

	Push $var
FunctionEnd

Function ShowAll
	MessageBox MB_OK|MB_TOPMOST "Skins: $SkinListF$\n$\nThemes: $ThemeListF$\n$\nAddons: $AddonListF$\n$\nPlugins: $PluginListF$\n$\nFonts: $FontListF"
FunctionEnd

Function Install
	Call RainmeterClose
	Banner::show "Installing, please wait..."
	EnableWindow $selApply 0
	EnableWindow $selLaunch 0
	EnableWindow $btnInstall 0

	${If} ${FileExists} "$Root\Skins\*.*"
		${Locate} "$Root\Skins" "/L=D /G=0" "InstallSkins"
		RMDir /r "$Root\Skins"
	${EndIf}
	
	${If} ${FileExists} "$Root\Themes\*.*"
		CopyFiles /SILENT "$Root\Themes\*.*" "$SETTINGSPATH\Themes"
		RMDir /r "$Root\Themes"
	${EndIf}
	
	${If} ${FileExists} "$Root\Addons\*.*"
		${Locate} "$Root\Addons" "/L=D /G=0" "InstallAddons"
		RMDir /r "$Root\Addons"
	${EndIf}

	${If} ${FileExists} "$Root\Plugins\*.dll"
		${Locate} "$Root\Plugins" "/L=F /G=0 /M=*.dll" "InstallPlugins"
		RMDir /r "$Root\Plugins"
	${EndIf}

	${If} ${FileExists} "$Root\Fonts\*.ttf"
		${If} $RainmeterFonts == "1"
			CopyFiles /SILENT "$Root\Fonts\*.ttf" "$EXEDIR\..\..\Fonts"
		${Else}
			SetOutPath "$Root\Fonts"
			File "Include\FontReg.exe"
			ExecWait '"$Root\Fonts\FontReg.exe" /copy'
			SetOutPath "$EXEDIR"
		${EndIf}
		RMDir /r "$Root\Fonts"
	${EndIf}

	${NSD_GetState} $selLaunch $selLaunch
	${NSD_GetState} $selApply $selApply

	StrCpy $0 $LaunchType
	StrCmp $selLaunch "1" 0 skiprainmeter
	StrCmp $selApply "1" +2 0
	StrCpy $0 ""
	SetOutPath "$PLUGINSDIR"
	SetShellVarContext all
	!insertmacro UAC_AsUser_Call Function ExecRainmeter ${UAC_SYNCREGISTERS}

skiprainmeter:
	Banner::destroy
	SendMessage $HWNDPARENT "0x408" "1" ""
FunctionEnd

Function InstallSkins
	IfFileExists "$SKINSPATH\$R7\*.*" 0 copy

	CreateDirectory "$SKINSPATH\Backup\Rainstaller Backup\$R7$Date"
	CopyFiles /SILENT "$SKINSPATH\$R7\*.*" "$SKINSPATH\Backup\Rainstaller Backup\$R7$Date"
	StrCmp $Merge "1" copy
	StrCmp "$KeepVar" "" remove 0

loop:
	Push "|"
	Push "$KeepVar"
	Call SplitFirstStrPart
	Pop $1
	Pop $KeepVar
	Push $1
	Call Trim
	Pop $1

	${If} ${FileExists} "$SKINSPATH\$1"
		Push "$Root\Skins\$1"
		Push "$SKINSPATH\$1"
		Call ReadINIFileKeys
	${EndIf}

	StrCmp $KeepVar "" 0 loop

remove:
	RMDir /r "$SKINSPATH\$R7"
	IfFileExists "$SKINSPATH\$R7\*.*" 0 copy
	MessageBox MB_RETRYCANCEL|MB_ICONSTOP "Error: Failed to remove in \Skins\$R7.$\nMake sure that related files are not in use and try again.$\n$\nShould you want to restore, a backup was saved at:$\n\Skins\Backup\Rainstaller Backup\$R7$Date" IDRETRY remove
	Abort

copy:
	CopyFiles /SILENT "$Root\Skins\$R7" "$SKINSPATH"

	Push $var
FunctionEnd

Function InstallAddons
	IfFileExists "$EXEDIR\..\..\Addons\$R7\*.*" 0 copy

	CreateDirectory "$EXEDIR\..\..\Addons\Rainstaller Backup\$R7$Date"
	CopyFiles /SILENT "$EXEDIR\..\..\Addons\$R7\*.*" "$EXEDIR\..\..\Addons\Rainstaller Backup\$R7$Date"

remove:
	RMDir /r "$EXEDIR\..\..\Addons\$R7"
	IfFileExists "$EXEDIR\..\..\Addons\$R7\*.*" 0 copy
	MessageBox MB_RETRYCANCEL|MB_ICONSTOP "Error: Failed to remove in \Addons\$R7.$\nMake sure that related files are not in use and try again.$\n$\nShould you want to restore, a backup was saved at:$\n\Addons\Rainstaller Backup\$R7$Date" IDRETRY remove
	Abort

copy:
	CopyFiles /SILENT "$Root\Addons\$R7" "$EXEDIR\..\..\Addons"

	Push $var
FunctionEnd

Function InstallPlugins
	IfFileExists "$EXEDIR\..\..\Plugins\$R7" 0 copy

	CreateDirectory "$EXEDIR\..\..\Plugins\Rainstaller Backup"
	CopyFiles /SILENT "$EXEDIR\..\..\Plugins\$R7" "$EXEDIR\..\..\Plugins\Rainstaller Backup\$R7$Date.dll"

copy:
	CopyFiles /SILENT "$Root\Plugins\$R7" "$EXEDIR\..\..\Plugins"

	Push $var
FunctionEnd

Function ExecRainmeter
	SetShellVarContext all
	CreateDirectory "$SETTINGSPATH\Themes\Rainstaller Backup"
	CopyFiles /SILENT "$SETTINGSPATH\Rainmeter.ini" "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm"

	${If} $0 == "Bang"
		Exec "$EXEDIR\..\..\Rainmeter.exe"
		Call RainmeterCheck
		Exec '"$EXEDIR\..\..\Rainmeter.exe" $LaunchCommand'
	${ElseIf} $0 == "Load"
		Exec "$EXEDIR\..\..\Rainmeter.exe"
		Call RainmeterCheck

loop:
		Push "|"
		Push "$LaunchCommand"
		Call SplitFirstStrPart
		Pop $1
		Pop $LaunchCommand
		${GetParent} "$1" $R1
		${GetFileName} "$1" $R2
		Push $R1
		Call Trim
		Pop $R1
 		Push $R2
		Call Trim
		Pop $R2
		Sleep 50
		Exec '"$EXEDIR\..\..\Rainmeter.exe" !RainmeterActivateConfig "$R1" "$R2"'
		StrCmp $LaunchCommand "" 0 loop
	${ElseIf} $0 == "Theme"
		CopyFiles /SILENT "$SETTINGSPATH\Themes\$LaunchCommand\Rainmeter.thm" "$SETTINGSPATH\Rainmeter.ini"
		DeleteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "SkinPath"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "SkinPath"
		StrCmp "$1" "" +2 0
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "SkinPath" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "ConfigEditor"
		StrCmp "$1" "" +2 0
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "ConfigEditor" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "TrayExecuteL"
		ReadINIStr $R1 "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteL"
		StrCmp "$1" "" +3 0
		StrCmp "$R1" "" 0 +2
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteL" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "TrayExecuteM"
		ReadINIStr $R1 "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteM"
		StrCmp "$1" "" +3 0
		StrCmp "$R1" "" 0 +2
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteM" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "TrayExecuteR"
		ReadINIStr $R1 "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteR"
		StrCmp "$1" "" +3 0
		StrCmp "$R1" "" 0 +2
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteR" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "TrayExecuteDL"
		ReadINIStr $R1 "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteDL"
		StrCmp "$1" "" +3 0
		StrCmp "$R1" "" 0 +2
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteDL" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "TrayExecuteDM"
		ReadINIStr $R1 "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteDM"
		StrCmp "$1" "" +3 0
		StrCmp "$R1" "" 0 +2
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteDM" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "TrayExecuteDR"
		ReadINIStr $R1 "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteDR"
		StrCmp "$1" "" +3 0
		StrCmp "$R1" "" 0 +2
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "TrayExecuteDR" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "DisableVersionCheck"
		StrCmp "$1" "" +2 0
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "DisableVersionCheck" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Rainmeter" "Logging"
		StrCmp "$1" "" +2 0
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Rainmeter" "Logging" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Arcs" "Version"
		StrCmp "$1" "" +2 0
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Arcs" "Version" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Enigma" "Version"
		StrCmp "$1" "" +2 0
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Enigma" "Version" "$1"

		ReadINIStr $1 "$SETTINGSPATH\Themes\Rainstaller Backup\Rainmeter.thm" "Gnometer" "Version"
		StrCmp "$1" "" +2 0
			WriteINIStr "$SETTINGSPATH\Rainmeter.ini" "Gnometer" "Version" "$1"

		Exec "$EXEDIR\..\..\Rainmeter.exe"
	${Else}
		Exec "$EXEDIR\..\..\Rainmeter.exe"
	${EndIf}
FunctionEnd

Function RainmeterClose
	FindWindow $0 "RainmeterTrayClass"
	IsWindow $0 0 rainbrowsercheck
		StrCpy $1 0
		Exec '"$EXEDIR\..\..\Rainmeter.exe" !RainmeterQuit'

rainmetercheck:
	FindWindow $0 "RainmeterTrayClass"
	IsWindow $0 0 rainbrowsercheck
		StrCmp $1 20 0 +3
			MessageBox MB_ICONSTOP|MB_RETRYCANCEL "Rainstaller failed to close Rainmeter.$\n$\nPlease close Rainmeter manually and try again." IDRETRY rainmetercheck
			Call QuitCleanup
		IntOp $1 $1 + 1
		Sleep 200
		Goto rainmetercheck

rainbrowsercheck:
	FindWindow $0 "AutoIt v3 GUI" "RainBrowser"
	IsWindow $0 0 continue
		${TerminateProcess} "RainBrowser.exe" $0
		Goto rainbrowsercheck

continue:
FunctionEnd

Function RainmeterCheck
	StrCpy $1 0

checkloop:
	StrCmp $1 100 0 +2
		Goto checksuccess
	IntOp $1 $1 + 1
	Sleep 100
	FindWindow $0 "RainmeterTrayClass"
	IsWindow $0 0 checkloop

checksuccess:
FunctionEnd

Function QuitCleanup
	SetShellVarContext all
	RMDir /r "$APPDATA\Rainstaller"
	Quit
FunctionEnd

Function .onGUIEnd
	HideWindow
	Call QuitCleanup
FunctionEnd

Section
SectionEnd