#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=rBk.ico
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Res_Description=RainBackup
#AutoIt3Wrapper_Res_Fileversion=1.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=2010 Jeffrey S. Morley
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#cs
	===========================================================================================================
	RainBackup: Create a Rainmstaller .rmskin file from your Rainmeter Skins/Themes/Addons/Fonts/Plugins

	Copyright: 2010 Jeffrey Morley
	License: Creative Commons Attribution-Non-Commercial-Share Alike 3.0
	===========================================================================================================

	===========================================================================================================
	Initialize variables and application defaults
	===========================================================================================================
#ce

_Singleton("RainBackup", 0)

#include <File.au3>
#include <ButtonConstants.au3>
#include <GuiButton.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>

$WorkingDir = @TempDir & "\RainBackup\"
DirCreate($WorkingDir)

FileInstall (".\Include\RainBackup.bmp", $WorkingDir & "RainBackup.bmp", 1)
FileInstall (".\Include\Rainstaller.bmp", $WorkingDir & "Rainstaller.bmp", 1)
FileInstall (".\Include\Rainstaller.cfg", $WorkingDir & "Rainstaller.cfg", 1)
FileInstall (".\Include\7za.exe", $WorkingDir & "7za.exe", 1)

Global $ExeLocation, $RainmeterINI, $ThemesDir, $SkinsDataDir, $OutPutFile, $AddonsDir, $FontsDir, $PluginsDir
Global $EnvFail = 1, $WorkingNow = 0

While FileExists($WorkingDir & "7za.exe") = 0
WEnd

#cs
	===========================================================================================================
	Build the GUI interface
	===========================================================================================================
#ce

$Mainform = GUICreate("RainBackup", 382, 430, -1, -1)
$BannerPic = GUICtrlCreatePic($WorkingDir & "RainBackup.bmp", 0, 0, 400, 60)
$WelcomeLabel = GUICtrlCreateLabel("Welcome to RainBackup for Rainmeter", 10, 71, 311, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$SelectOneLabel = GUICtrlCreateLabel("Create a backup of your customizations as a Rainstaller .rmskin file", 10, 89, 350, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

$GetExeLabel = GUICtrlCreateLabel("", 10, 130, 300, 20)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$GetExeInput = GUICtrlCreateInput("", 10, 150, 280, 25, BitOr($ES_READONLY, $ES_AUTOHSCROLL))
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$GetExeButton = GUICtrlCreateButton("Browse", 300, 149, 70, 24)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

$GetOutputLabel = GUICtrlCreateLabel("Select folder and name of .rmskin to create:", 10, 200, 300, 20)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$GetOutputInput = GUICtrlCreateInput(@DesktopDir & "\RainBackup.rmskin", 10, 220, 280, 23, BitOr($ES_READONLY, $ES_AUTOHSCROLL))
GUICtrlSetTip($GetOutputInput, @DesktopDir & "\RainBackup.rmskin")
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$GetOutputButton = GUICtrlCreateButton("Browse", 300, 219, 70, 24)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

$MainOkLabel = GUICtrlCreateLabel("Folders found to save:", 10, 260, 300, 20)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$SkinsOkLabel = GUICtrlCreateInput("Skins Folder", 10, 285, 358, 15, BitOr($ES_READONLY, $ES_AUTOHSCROLL), $WS_EX_TRANSPARENT)
GUICtrlSetFont(-1, 8.5, 400, 0, "Segoe UI")
GUICtrlSetColor($SkinsOkLabel, 0xC0C0C0)
$ThemesOkLabel = GUICtrlCreateInput("Themes Folder", 10, 301, 358, 15, BitOr($ES_READONLY, $ES_AUTOHSCROLL), $WS_EX_TRANSPARENT)
GUICtrlSetFont(-1, 8.5, 400, 0, "Segoe UI")
GUICtrlSetColor($ThemesOkLabel, 0xC0C0C0)
$AddonsOkLabel = GUICtrlCreateInput("Addons Folder", 10, 317, 358, 15, BitOr($ES_READONLY, $ES_AUTOHSCROLL), $WS_EX_TRANSPARENT)
GUICtrlSetFont(-1, 8.5, 400, 0, "Segoe UI")
GUICtrlSetColor($AddonsOkLabel, 0xC0C0C0)
$FontsOkLabel = GUICtrlCreateInput("Fonts Folder", 10, 333, 358, 15, BitOr($ES_READONLY, $ES_AUTOHSCROLL), $WS_EX_TRANSPARENT)
GUICtrlSetFont(-1, 8.5, 400, 0, "Segoe UI")
GUICtrlSetColor($FontsOkLabel, 0xC0C0C0)
$PluginsOkLabel = GUICtrlCreateInput("Plugins Folder", 10, 349, 361, 15, BitOr($ES_READONLY, $ES_AUTOHSCROLL), $WS_EX_TRANSPARENT)
GUICtrlSetFont(-1, 8.5, 400, 0, "Segoe UI")
GUICtrlSetColor($PluginsOkLabel, 0xC0C0C0)

$GoButton = GUICtrlCreateButton("Backup", 10, 385, 70, 24)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetState($GoButton, $GUI_DISABLE)

$AppLabel = GUICtrlCreateLabel("RainBackup 1.0", 279, 365, 84, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetColor(-1, 0xC0C0C0)
$AuthorLabel = GUICtrlCreateLabel("JSMorley", 314, 380, 51, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetColor(-1, 0xC0C0C0)
$LinkLabel = GUICtrlCreateLabel("http://rainmeter.net", 254, 395, 110, 19)
GUICtrlSetFont(-1, 9, 400, 4, "Segoe UI")
GUICtrlSetColor(-1, 0xC0C0C0)
GUICtrlSetCursor (-1, 0)
GUICtrlSetTip(-1, "Rainmeter Home")

GUISetState(@SW_SHOWNORMAL, $MainForm)

GetRainmeterEnv()

#cs
	===========================================================================================================
	Main processing loop.  Waiting for user clicks to take actions.
	===========================================================================================================
#ce

While 1

	$UserEvent = GUIGetMsg()

	Switch $UserEvent

		Case $LinkLabel
			ShellExecute("http://rainmeter.net")

		Case $GUI_EVENT_CLOSE
			If $WorkingNow = 0 Then
				While ProcessExists("7za.exe")
					ProcessClose("7za.exe")
					Sleep(100)
				Wend
				DirRemove($WorkingDir, 1)
				Exit
			EndIf

		Case $GetOutputButton
			$OldOutPutFile = GUICtrlRead($GetOutputInput)
			$OutPutFile = FileSaveDialog("Output rmskin name.", @DesktopDir, "Rainstaller files (*.rmskin)", 2)
			If $OutPutFile <> "" Then
				If StringUpper(StringRight($OutPutFile, 7)) <> ".RMSKIN" Then
					$OutPutFile = $OutPutFile & ".rmskin"
				EndIf
			Else
				$OutPutFile = $OldOutPutFile
			EndIf
			GUICtrlSetData($GetOutputInput, $OutPutFile)
			GUICtrlSetTip($GetOutputInput, $OutPutFile)
			GetRainmeterEnv()

		Case $GetExeButton
			$ExeBrowseFile = FileOpenDialog ("Browse for Rainmeter.exe", @ProgramFilesDir, "Rainmeter.exe (Rainmeter.exe)", 3)
			FileChangeDir(@ScriptDir)
			If $ExeBrowseFile <> "" Then
				$ExeLocation = StringLeft($ExeBrowseFile, StringLen($ExeBrowseFile)-14)
			EndIf
			GetRainmeterEnv()

		Case $GoButton
			GetRainmeterEnv()
			iF $EnvFail = 0 And GUICtrlRead($GetOutputInput) <> "" Then
				$WorkingNow = 1
				GUICtrlSetData ($GoButton, "Working")
				GUICtrlSetState($GoButton, $GUI_DISABLE)
				MakeZip()
				$WorkingNow = 0
				GUICtrlSetData ($GoButton, "Backup")
				GUICtrlSetState($GoButton, $GUI_ENABLE)
			EndIf

	EndSwitch

WEnd

#cs
	===========================================================================================================
	All below here are functions
	===========================================================================================================
#ce

#cs
	===========================================================================================================
	Function GetRainmeterEnv: Validate Rainmeter environment and create variables for paths and files.
	===========================================================================================================
#ce
Func GetRainmeterEnv()

	GUICtrlSetColor($SkinsOkLabel, 0xC0C0C0)
	GUICtrlSetData($SkinsOkLabel, "Skins Folder")

	If $ExeLocation = "" Then
		$ExeLocation = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Rainmeter", "")
	EndIf

	If $ExeLocation = "" Then
		If FileFindFirstFile(@ProgramFilesDir & "\Rainmeter\Rainmeter.exe") <> -1 Then
			$ExeLocation = @ProgramFilesDir & "\Rainmeter"
		EndIf
	EndIf

	If $ExeLocation <> "" Then
		GUICtrlSetData($GetExeLabel, "Found Rainmeter at:")
		GUICtrlSetData($GetExeInput, $ExeLocation & "\Rainmeter.exe")
		GUICtrlSetTip($GetExeInput, $ExeLocation & "\Rainmeter.exe")
	Else
		GUICtrlSetData($GetExeInput, "Please browse to Rainmeter.exe")
		GUICtrlSetData($GetExeLabel, "Rainmeter not found")
		GUICtrlSetTip($GetExeInput, "Please browse to Rainmeter.exe")
	EndIf

	$AppDataDir = EnvGet("APPDATA")

	If $ExeLocation <> "" Then
		If FileFindFirstFile($ExeLocation & "\Rainmeter.ini") <> -1 Then
			$RainmeterINI = $ExeLocation & "\Rainmeter.ini"
			$ThemesDir = $ExeLocation & "\Themes"
		ElseIf FileFindFirstFile($AppDataDir & "\Rainmeter\Rainmeter.ini") <> -1 Then
			$RainmeterINI = $AppDataDir & "\Rainmeter\Rainmeter.ini"
			$ThemesDir = $AppDataDir & "\Rainmeter\Themes"
		Else
			$ThemesDir = ""
		EndIf
	Else
		$RainmeterINI = ""
		$ThemesDir = ""
	EndIf

	$SkinsDataDir = IniRead ($RainmeterINI, "Rainmeter", "SkinPath", "")
	If $SkinsDataDir <> "" then $SkinsDataDir = StringLeft($SkinsDataDir, StringLen($SkinsDataDir)-1)

	If $ExeLocation <> "" Then
		$AddonsDir = $ExeLocation & "\Addons"
		If FileFindFirstFile($AddonsDir) = -1 Then
			$AddonsDir = ""
		EndIf
	EndIf

	If $ExeLocation <> "" Then
		$FontsDir = $ExeLocation & "\Fonts"
		If FileFindFirstFile($FontsDir) = -1 Then
			$FontsDir = ""
		EndIf
	EndIf

	If $ExeLocation <> "" Then
		$PluginsDir = $ExeLocation & "\Plugins"
		If FileFindFirstFile($PLuginsDir) = -1 Then
			$PluginsDir = ""
		EndIf
	EndIf

	If $ExeLocation = "" Or $RainmeterINI = "" Or $ThemesDir = "" Or $SkinsDataDir = "" Then
		$EnvFail = 1
	Else
		$EnvFail = 0
	EndIf

	If FileFindFirstFile($SkinsDataDir) <> -1 Then
		GUICtrlSetData($SkinsOkLabel, $SkinsDataDir)
		GUICtrlSetColor($SkinsOkLabel, 0x012201)
	EndIf

	If FileFindFirstFile($ThemesDir) <> -1 Then
		GUICtrlSetData($ThemesOkLabel, $ThemesDir)
		GUICtrlSetColor($ThemesOkLabel, 0x012201)
	EndIf

	If FileFindFirstFile($AddonsDir) <> -1 Then
		GUICtrlSetData($AddonsOkLabel, $AddonsDir)
		GUICtrlSetColor($AddonsOkLabel, 0x012201)
	EndIf

	If FileFindFirstFile($FontsDir) <> -1 Then
		GUICtrlSetData($FontsOkLabel, $FontsDir)
		GUICtrlSetColor($FontsOkLabel, 0x012201)
	EndIf

	If FileFindFirstFile($PluginsDir) <> -1 Then
		GUICtrlSetData($PluginsOkLabel, $PluginsDir)
		GUICtrlSetColor($PluginsOkLabel, 0x012201)
	EndIf

	$OutPutFile = GUICtrlRead($GetOutputInput)
	If $OutPutFile = "" Then
		GUICtrlSetData($GetOutputInput, @DesktopDir & "\RainBackup.rmskin")
	EndIf

	iF $EnvFail = 0 And GUICtrlRead($GetOutputInput) <> "" Then
		GUICtrlSetState($GoButton, $GUI_ENABLE)
	EndIf

EndFunc   ;==>GetRainmeterEnv

#cs
	===========================================================================================================
	Function MakeZip: Create .rmskin file from Rainmeter folders
	===========================================================================================================
#ce
Func MakeZip()

	While FileExists($OutPutFile)
		FileDelete($OutPutFile)
		Sleep(300)
	Wend

	If FileExists($WorkingDir & "Rainstaller.cfg") = 1 and FileExists($WorkingDir & "Rainstaller.bmp") = 1 Then
		ShellExecute($WorkingDir & "7za.exe", "a -tZip " & chr(34) & $OutPutFile & chr(34) & " " & chr(34) & $WorkingDir & "Rainstaller.cfg" & chr(34),"","open", @SW_HIDE)
		While ProcessExists("7za.exe")
			Sleep(100)
		Wend
		ShellExecute($WorkingDir & "7za.exe", "a -tZip " & chr(34) & $OutPutFile & chr(34) & " " & chr(34) & $WorkingDir & "Rainstaller.bmp" & chr(34),"","open", @SW_HIDE)
	Else
		MsgBox(48,"RainBackup Error", "Required Rainstaller components missing!")
		Return
	EndIf
	While ProcessExists("7za.exe")
	Sleep(100)
	Wend

	if FileExists ($ThemesDir) = 1 Then
		DirCreate($ThemesDir & "\RainBackup")
		FileCopy ($RainmeterINI, $ThemesDir & "\RainBackup\Rainmeter.thm", 1)
	EndIf

	If $SkinsDataDir <> "" Then
		if FileExists ($SkinsDataDir) = 1 Then
			GUICtrlSetColor($SkinsOkLabel, 0x500000)
			GUICtrlSetFont($SkinsOkLabel, 8.5, 800, 0, "Segoe UI")
			ShellExecute($WorkingDir & "7za.exe", "a -tZip " & chr(34) & $OutPutFile & chr(34) & " " & chr(34) & $SkinsDataDir & chr(34),"","open", @SW_HIDE)
		Else
			MsgBox(48,"RainBackup Error", $SkinsDataDir & " INVALID")
			Return
		EndIf
		While ProcessExists("7za.exe")
			Sleep(100)
		Wend
		GUICtrlSetColor($SkinsOkLabel, 0x005000)
		GUICtrlSetFont($SkinsOkLabel, 8.5, 400, 0, "Segoe UI")
	EndIf

	If $ThemesDir <> "" Then
		if FileExists ($ThemesDir) = 1 Then
			GUICtrlSetColor($ThemesOkLabel, 0x500000)
			GUICtrlSetFont($ThemesOkLabel, 8.5, 800, 0, "Segoe UI")
			ShellExecute($WorkingDir & "7za.exe", "a -tZip " & chr(34) & $OutPutFile & chr(34) & " " & chr(34) & $ThemesDir & chr(34),"","open", @SW_HIDE)
		Else
			MsgBox(48,"RainBackup Error", $ThemesDir & " INVALID")
			Return
		EndIf
		While ProcessExists("7za.exe")
			Sleep(100)
		Wend
		GUICtrlSetColor($ThemesOkLabel, 0x005000)
		GUICtrlSetFont($ThemesOkLabel, 8.5, 400, 0, "Segoe UI")
	EndIf

	If $AddonsDir <> "" Then
		if FileExists ($AddonsDir) = 1 Then
			GUICtrlSetColor($AddonsOkLabel, 0x500000)
			GUICtrlSetFont($AddonsOkLabel, 8.5, 800, 0, "Segoe UI")
			ShellExecute($WorkingDir & "7za.exe", "a -tZip " & chr(34) & $OutPutFile & chr(34) & " " & chr(34) & $AddonsDir & chr(34),"","open", @SW_HIDE)
		Else
			MsgBox(48,"RainBackup Error", $AddonsDir & " INVALID")
			Return
		EndIf
		While ProcessExists("7za.exe")
			Sleep(100)
		Wend
		GUICtrlSetColor($AddonsOkLabel, 0x005000)
		GUICtrlSetFont($AddonsOkLabel, 8.5, 400, 0, "Segoe UI")
	EndIf

	If $FontsDir <> "" Then
		if FileExists ($FontsDir) = 1 Then
			GUICtrlSetColor($FontsOkLabel, 0x500000)
			GUICtrlSetFont($FontsOkLabel, 8.5, 800, 0, "Segoe UI")
			ShellExecute($WorkingDir & "7za.exe", "a -tZip " & chr(34) & $OutPutFile & chr(34) & " " & chr(34) & $FontsDir & chr(34),"","open", @SW_HIDE)
		Else
			MsgBox(48,"RainBackup Error", $FontsDir & " INVALID")
			Return
		EndIf
		While ProcessExists("7za.exe")
			Sleep(100)
		Wend
		GUICtrlSetColor($FontsOkLabel, 0x005000)
		GUICtrlSetFont($FontsOkLabel, 8.5, 400, 0, "Segoe UI")
	EndIf

	If $PluginsDir <> "" Then
		if FileExists ($PluginsDir) = 1 Then
			GUICtrlSetColor($PluginsOkLabel, 0x500000)
			GUICtrlSetFont($PluginsOkLabel, 8.5, 800, 0, "Segoe UI")
			ShellExecute($WorkingDir & "7za.exe", "a -tZip " & chr(34) & $OutPutFile & chr(34) & " " & chr(34) & $PluginsDir & chr(34),"","open", @SW_HIDE)
		Else
			MsgBox(48,"RainBackup Error", $PluginsDir & " INVALID")
			Return
		EndIf
		While ProcessExists("7za.exe")
			Sleep(100)
		Wend
		GUICtrlSetColor($PluginsOkLabel, 0x005000)
		GUICtrlSetFont($PluginsOkLabel, 8.5, 400, 0, "Segoe UI")
	EndIf

	MsgBox(64, "RainBackup", "RainBackup complete in: " & @CRLF & @CRLF & $OutPutFile)

EndFunc   ;==>MakeZip
