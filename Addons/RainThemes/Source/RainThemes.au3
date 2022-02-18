#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=rT.ico
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Res_Description=Rainmeter Themes Manager
#AutoIt3Wrapper_Res_Fileversion=2.0.0.0
#AutoIt3Wrapper_Res_LegalCopyright=2010 Jeffrey S. Morley
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs
	===========================================================================================================
	RainThemes
	Copyright: 2009 Jeffrey Morley
	License: Creative Commons Attribution-Non-Commercial-Share Alike 3.0
	===========================================================================================================

	===========================================================================================================
	Initialize variables and application defaults
	===========================================================================================================

#include <WinAPIEx.au3>

$RainMeterPath = _WinAPI_GetModuleFileNameEx(ProcessExists("Rainmeter.exe"))
MsgBox("","",$RainMeterPath)

#ce


#include <File.au3>
#include <Array.au3>
#include <ButtonConstants.au3>
#include <GuiButton.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <ListBoxConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <Misc.au3>
#include <GUIListBox.au3>
#include <GDIPlus.au3>
#include <ScreenCapture.au3>
#include <StructureConstants.au3>

Global $CurrentTextInput = ""
Global $Portable = 0
$AppDataDir = EnvGet("APPDATA")

#cs
	===========================================================================================================
	Validate Rainmeter environment and create variables for paths and files.  Parse command line
	===========================================================================================================
#ce

If FileFindFirstFile("..\..\Rainmeter.ini") <> - 1 Then
	$DataFolder = "..\..\"
	$Portable = 1
ElseIf FileFindFirstFile($AppDataDir & "\Rainmeter\Rainmeter.ini") <> - 1 Then
	$DataFolder = $AppDataDir & "\Rainmeter\"
	$Portable = 0
Else
	MsgBox(48, "RainThemes Error", "Unable to locate Rainmeter.ini")
	Exit
EndIf

Opt("TrayIconHide", 1)
Opt("GUICloseOnESC", 0)
_Singleton("RainThemes", 0)
$dll = DllOpen("user32.dll")

If $CmdLine[0] = 2 Then
	If StringUpper($CmdLine[1]) = "/LOAD" Then
		ShellExecute("..\..\rainmeter.exe", "!RainmeterQuit")
		Sleep(2000)
		If ProcessExists("RainmeterPortable.exe") = 0 Then
			_setWallPaper($DataFolder & "Themes\" & $CmdLine[2] & "\RainThemes.bmp")
		EndIf

		$SkinPath = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "SkinPath", "" )
		$ConfigEditor = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "ConfigEditor", "" )
		$DisableVersionCheck = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "DisableVersionCheck", "" )
		$LoggingEnabled = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "Logging", "" )
		$ArcsVersion = IniRead($DataFolder & "Rainmeter.ini", "Arcs", "Version", "" )
		$EnigmaVersion = IniRead($DataFolder & "Rainmeter.ini", "Enigma", "Version", "" )
		$GnometerVersion = IniRead($DataFolder & "Rainmeter.ini", "Gnometer", "Version", "" )
;~ 		$TrayExecuteL = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "TrayExecuteL", "" )
;~ 		$TrayExecuteM = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "TrayExecuteM", "" )
;~ 		$TrayExecuteR = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "TrayExecuteR", "" )
;~ 		$TrayExecuteDL = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "TrayExecuteDL", "" )
;~ 		$TrayExecuteDM = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "TrayExecuteDM", "" )
;~ 		$TrayExecuteDR = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "TrayExecuteDR", "" )

		FileCopy($DataFolder & "Themes\" & $CmdLine[2] & "\Rainmeter.thm", $DataFolder & "Rainmeter.ini", 1)

		_PreserveSettings("Rainmeter", "SkinPath", $SkinPath)
		_PreserveSettings("Rainmeter", "ConfigEditor", $ConfigEditor)
		_PreserveSettings("Rainmeter", "DisableVersionCheck", $DisableVersionCheck)
		_PreserveSettings("Rainmeter", "Logging", $LoggingEnabled)
		_PreserveSettings("Arcs", "Version", $ArcsVersion)
		_PreserveSettings("Enigma", "Version", $EnigmaVersion)
		_PreserveSettings("Gnometer", "Version", $GnometerVersion)
;~ 		_PreserveSettings("Rainmeter", "TrayExecuteL", $TrayExecuteL)
;~ 		_PreserveSettings("Rainmeter", "TrayExecuteM", $TrayExecuteM)
;~ 		_PreserveSettings("Rainmeter", "TrayExecuteR", $TrayExecuteR)
;~ 		_PreserveSettings("Rainmeter", "TrayExecuteDL", $TrayExecuteDL)
;~ 		_PreserveSettings("Rainmeter", "TrayExecuteDM", $TrayExecuteDM)
;~ 		_PreserveSettings("Rainmeter", "TrayExecuteDR", $TrayExecuteDR)

		ShellExecute("..\..\rainmeter.exe")
	EndIf
	Exit
EndIf

$Mainform = GUICreate("RainThemes", 382, 512, -1, -1)
$BannerPic = GUICtrlCreatePic("RainThemes.bmp", 0, 0, 400, 60)
$WelcomeLabel = GUICtrlCreateLabel("Welcome to RainThemes", 10, 71, 139, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$SelectOneLabel = GUICtrlCreateLabel("Select or enter the name of a theme and choose an action:", 10, 89, 311, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$ThemeList = GUICtrlCreateList("", 10, 118, 272, 261)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$LoadButton = GUICtrlCreateButton("Load", 289, 117, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Load the selected theme")
$RenameButton = GUICtrlCreateButton("Rename", 289, 172, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Rename the selected theme")
$EditButton = GUICtrlCreateButton("Edit", 289, 207, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Edit the selected theme in your text editor")
$DeleteButton = GUICtrlCreateButton("Delete", 289, 262, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Delete the selected theme")
$TextInput = GUICtrlCreateInput("", 10, 395, 269, 23)
GUICtrlSetFont(-1, 11, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Select or enter the name of a theme here to save")
$SaveButton = GUICtrlCreateButton("Save", 289, 391, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Save this theme")
$SaveEmptyCheckBox = GUICtrlCreateCheckbox("Save as an empty theme", 10, 430, 247, 21)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Save a blank theme with the selected name")
$RemoveInactiveCheckBox = GUICtrlCreateCheckbox("Remove unused skins from theme", 10, 455, 245, 21)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Remove all inactive skins from the theme when saved")
$SaveWallpaperCheckBox = GUICtrlCreateCheckbox("Save wallpaper with theme", 10, 480, 247, 21)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Save your current wallpaper in your theme folder")
$AppLabel = GUICtrlCreateLabel("RainThemes 2.0", 289, 440, 84, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetColor(-1, 0xC0C0C0)
$AuthorLabel = GUICtrlCreateLabel("JSMorley", 322, 460, 51, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetColor(-1, 0xC0C0C0)
$LinkLabel = GUICtrlCreateLabel("http://rainmeter.net", 262, 480, 110, 19)
GUICtrlSetFont(-1, 9, 400, 4, "Segoe UI")
GUICtrlSetColor(-1, 0xC0C0C0)
GUICtrlSetCursor (-1, 0)
GUICtrlSetTip(-1, "Rainmeter Home")

#cs
	===========================================================================================================
	Initial display of main GUI and populating list of Themes
	===========================================================================================================
#ce

GUISetState(@SW_SHOWNORMAL, $MainForm)
Dim $Form1_AccelTable[4][2] = [["^l", $LoadButton],["^r", $RenameButton],["^d", $DeleteButton],["^s", $SaveButton]]
GUISetAccelerators($Form1_AccelTable)

$FileList = _GetFolders()
If IsArray($FileList) Then
	For $a = 1 To $FileList[0]
		GUICtrlSetData($ThemeList, $FileList[$a], "")
	Next
EndIf

$aThemeList = _GetDefaultThemes()

#cs
	===========================================================================================================
	Processing loop.  Waiting for clicks to fire events
	===========================================================================================================
#ce

While 1

	$UserEvent = GUIGetMsg()

	Switch $UserEvent

		Case $GUI_EVENT_CLOSE
			DllClose($dll)
			Exit

		Case $LinkLabel
			ShellExecute("http://rainmeter.net")

		Case $LoadButton
			$ListItemSelected = GUICtrlRead($ThemeList)
			If $ListItemSelected = "" Then
				MsgBox(48, "RainThemes Error", "Nothing selected to load!")
				GUICtrlSetState($SaveEmptyCheckBox, $GUI_UNCHECKED)
				GUICtrlSetState($SaveWallpaperCheckBox, $GUI_UNCHECKED)
				GUICtrlSetState($RemoveInactiveCheckBox, $GUI_UNCHECKED)
			Else
				If $ListItemSelected <> "AutoSave" Then
					FileCopy($DataFolder & "Rainmeter.ini", $DataFolder & "Themes\AutoSave\Rainmeter.thm", 9)
					$CurWallpaper = RegRead("HKEY_CURRENT_USER\Control Panel\Desktop", "Wallpaper")
					FileCopy($CurWallpaper, $DataFolder & "Themes\AutoSave\RainThemes.bmp", 9)
					_GUICtrlListBox_ResetContent($ThemeList)
					$FileList = _GetFolders()
					If $FileList[0] Then
						For $a = 1 To $FileList[0]
							GUICtrlSetData($ThemeList, $FileList[$a], "")
							GUICtrlSetState($SaveEmptyCheckBox, $GUI_UNCHECKED)
							GUICtrlSetState($SaveWallpaperCheckBox, $GUI_UNCHECKED)
							GUICtrlSetState($RemoveInactiveCheckBox, $GUI_UNCHECKED)
						Next
					EndIf
					_GUICtrlListBox_SelectString($ThemeList, $ListItemSelected)
				EndIf
				ShellExecute("..\..\rainmeter.exe", "!RainmeterQuit")
				Sleep(2000)
				If ProcessExists("RainmeterPortable.exe") = 0 Then
					_setWallPaper($DataFolder & "Themes\" & $ListItemSelected & "\RainThemes.bmp")
				EndIf

				$SkinPath = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "SkinPath", "" )
				$ConfigEditor = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "ConfigEditor", "" )
				$DisableVersionCheck = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "DisableVersionCheck", "" )
				$LoggingEnabled = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "Logging", "" )
				$ArcsVersion = IniRead($DataFolder & "Rainmeter.ini", "Arcs", "Version", "" )
				$EnigmaVersion = IniRead($DataFolder & "Rainmeter.ini", "Enigma", "Version", "" )
				$GnometerVersion = IniRead($DataFolder & "Rainmeter.ini", "Gnometer", "Version", "" )

				FileCopy($DataFolder & "Themes\" & $ListItemSelected & "\Rainmeter.thm", $DataFolder & "Rainmeter.ini", 1)

				_PreserveSettings("Rainmeter", "SkinPath", $SkinPath)
				_PreserveSettings("Rainmeter", "ConfigEditor", $ConfigEditor)
				_PreserveSettings("Rainmeter", "DisableVersionCheck", $DisableVersionCheck)
				_PreserveSettings("Rainmeter", "Logging", $LoggingEnabled)
				_PreserveSettings("Arcs", "Version", $ArcsVersion)
				_PreserveSettings("Enigma", "Version", $EnigmaVersion)
				_PreserveSettings("Gnometer", "Version", $GnometerVersion)

				ShellExecute("..\..\rainmeter.exe")
				GUICtrlSetState($SaveEmptyCheckBox, $GUI_UNCHECKED)
				GUICtrlSetState($SaveWallpaperCheckBox, $GUI_UNCHECKED)
				GUICtrlSetState($RemoveInactiveCheckBox, $GUI_UNCHECKED)
			EndIf

		Case $RenameButton
			$ListItemSelected = GUICtrlRead($ThemeList)
			If $ListItemSelected <> "" Then
				$RenameAnswer = InputBox("RainThemes - Rename theme", "Enter new name for theme", $ListItemSelected, "", 250, 125)
				$TextArray = StringRegExp($RenameAnswer, '[/\:*?"<>|]', 0)
				If $TextArray Then
					MsgBox(48, "RainThemes Error", 'The characters' & @CRLF & @CRLF & '\ / : * ? " < > |' & @CRLF & @CRLF & 'may not be used in a theme name!')
				Else
					For $a = 1 To $FileList[0]
						If $RenameAnswer = $FileList[$a] Then
							MsgBox("48", "RainThemes Error", "Theme name already exists!")
						Else
							DirMove($DataFolder & "Themes\" & $ListItemSelected, $DataFolder & "Themes\" & $RenameAnswer, 0)
						EndIf
					Next
				EndIf
				_GUICtrlListBox_ResetContent($ThemeList)
				$FileList = _GetFolders()
				If $FileList[0] Then
					For $a = 1 To $FileList[0]
						GUICtrlSetData($ThemeList, $FileList[$a], "")
						GUICtrlSetState($SaveEmptyCheckBox, $GUI_UNCHECKED)
						GUICtrlSetState($SaveWallpaperCheckBox, $GUI_UNCHECKED)
						GUICtrlSetState($RemoveInactiveCheckBox, $GUI_UNCHECKED)
					Next
				EndIf
			EndIf

		Case $DeleteButton
			$ListItemSelected = GUICtrlRead($ThemeList)
			If $ListItemSelected Then
				If MsgBox(36, "RainThemes - Delete a saved theme", 'You are about to delete the theme' & @CRLF & @CRLF & $ListItemSelected & @CRLF & @CRLF & 'Are you sure?') = 6 Then
					DirRemove($DataFolder & "Themes\" & $ListItemSelected, 1)
					_GUICtrlListBox_ResetContent($ThemeList)
					$FileList = _GetFolders()
					If IsArray($FileList) Then
						For $a = 1 To $FileList[0]
							GUICtrlSetData($ThemeList, $FileList[$a], "")
							GUICtrlSetData($TextInput, "")
							GUICtrlSetState($SaveEmptyCheckBox, $GUI_UNCHECKED)
							GUICtrlSetState($SaveWallpaperCheckBox, $GUI_UNCHECKED)
							GUICtrlSetState($RemoveInactiveCheckBox, $GUI_UNCHECKED)
						Next
					EndIf
				EndIf
			EndIf

		Case $EditButton
			$ListItemSelected = GUICtrlRead($ThemeList)
			If $ListItemSelected Then
				$TextEditor = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "ConfigEditor", "Notepad.exe")
				ShellExecute($TextEditor, $DataFolder & "Themes\" & $ListItemSelected & "\Rainmeter.thm")
			EndIf

		Case $TextInput
			If _IsPressed("0D", $dll) Then
				_GUICtrlButton_Click($SaveButton)
			EndIf

		Case $SaveButton
			$CurrentTextInput = GUICtrlRead($TextInput)
			$FoundDefault = _ArraySearch($aThemeList, $CurrentTextInput, 0, 0, 0, 0, 1)
			If $FoundDefault <> -1  And $Portable = 0 Then
				MsgBox(48, "RainThemes Error", "Do not save your setup as one of the Rainmeter default theme names [" & $CurrentTextInput & "] as your changes could be lost in a Rainmeter upgrade or re-install." & @CRLF &@CRLF & "Please enter another name.")
			Else
				$TextArray = StringRegExp($CurrentTextInput, '[/\:*?"<>|]', 0)
				If $TextArray Then
					MsgBox(48, "RainThemes Error", 'The characters' & @CRLF & @CRLF & '\ / : * ? " < > |' & @CRLF & @CRLF & 'may not be used in a theme name!')
				ElseIf $CurrentTextInput = "" Then
					MsgBox(48, "RainThemes Error", "Nothing entered to save!")
				Else
					$CleanTheme = GUICtrlRead($RemoveInactiveCheckBox)
					$CreateEmpty = GUICtrlRead($SaveEmptyCheckBox)
					FileCopy($DataFolder & "Rainmeter.ini", $DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", 9)
					If $CreateEmpty = $GUI_CHECKED Then
						For $a = 1 to 100
							_ReplaceStringInFile($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", "Active=" & $a, "Active=0")
						Next
					EndIf
					If $CleanTheme = $GUI_CHECKED Then
					$ArcsVersion = IniRead($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", "Arcs", "Version", "" )
					$EnigmaVersion = IniRead($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", "Enigma", "Version", "" )
					$GnometerVersion = IniRead($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", "Gnometer", "Version", "" )
						$SectionNames = IniReadSectionNames($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm")
						For $a = 1 to $SectionNames[0]
							$ActiveState = IniRead($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", $SectionNames[$a], "Active", "MISSING")
						if $ActiveState = "0" then
							IniDelete($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", $SectionNames[$a])
						EndIf
						Next
					If $ArcsVersion <> "" Then IniWrite ($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", "Arcs", "Version", $ArcsVersion)
					If $EnigmaVersion <> "" Then IniWrite ($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", "Enigma", "Version", $EnigmaVersion)
					If $GnometerVersion <> "" Then IniWrite ($DataFolder & "Themes\" & $CurrentTextInput & "\Rainmeter.thm", "Gnometer", "Version", $GnometerVersion)
					EndIf
					$SaveWallpaper = GUICtrlRead($SaveWallpaperCheckBox)
					If $SaveWallpaper = $GUI_CHECKED Then
						_SaveWallpaper($DataFolder & "Themes\" & $CurrentTextInput)
					EndIf
					MsgBox(64, "RainThemes - Theme saved", 'Your current Rainmeter configuration saved as' & @CRLF & @CRLF & $CurrentTextInput)
					_GUICtrlListBox_ResetContent($ThemeList)
					$FileList = _GetFolders()
					For $a = 1 To $FileList[0]
						GUICtrlSetData($ThemeList, $FileList[$a], "")
						GUICtrlSetData($TextInput, "")
						GUICtrlSetState($SaveEmptyCheckBox, $GUI_UNCHECKED)
						GUICtrlSetState($SaveWallpaperCheckBox, $GUI_UNCHECKED)
						GUICtrlSetState($RemoveInactiveCheckBox, $GUI_UNCHECKED)
						_GUICtrlListBox_SelectString($ThemeList, $CurrentTextInput)
					Next
				EndIf
			EndIf

		Case $ThemeList
			$ListItemSelected = GUICtrlRead($ThemeList)
			GUICtrlSetData($TextInput, $ListItemSelected)
			GUICtrlSetState($SaveEmptyCheckBox, $GUI_UNCHECKED)
			GUICtrlSetState($SaveWallpaperCheckBox, $GUI_UNCHECKED)
			GUICtrlSetState($RemoveInactiveCheckBox, $GUI_UNCHECKED)

	EndSwitch

WEnd

DllClose($dll)

Exit

#cs
	===========================================================================================================
	All below here are functions
	===========================================================================================================
#ce


Func _GetFolders()
	$ThemeSearch = FileFindFirstFile($DataFolder & "Themes\*.*")
	Dim $aFileList[9999]
	$FileAttrib = ""
	$ArrayNum = 0

	If $ThemeSearch <> -1 Then

		While 1

			$FoundFile = FileFindNextFile($ThemeSearch)
			If @error Then ExitLoop
			$FileAttrib = FileGetAttrib($DataFolder & "Themes\" & $FoundFile)
			If StringRegExp($FileAttrib, 'D', 0) Then
				$ArrayNum = $ArrayNum + 1
				$aFileList[0] = $ArrayNum
				$aFileList[$ArrayNum] = $FoundFile
			EndIf

		WEnd

	EndIf

	FileClose($ThemeSearch)
	ReDim $aFileList[$aFileList[0] + 1]
	Return $aFileList

EndFunc   ;==>_GetFolders

Func _GetDefaultThemes()
	$DefaultSearch = FileFindFirstFile("..\..\Themes\*.*")
	Dim $aThemeList[9999]
	$FileAttrib = ""
	$ArrayNum = 0

	If $DefaultSearch <> -1 Then

		While 1

			$FoundTheme = FileFindNextFile($DefaultSearch)
			If @error Then ExitLoop
			$FileAttrib = FileGetAttrib($DataFolder & "Themes\" & $FoundTheme)
			If StringRegExp($FileAttrib, 'D', 0) Then
				$ArrayNum = $ArrayNum + 1
				$aThemeList[0] = $ArrayNum
				$aThemeList[$ArrayNum] = $FoundTheme
			EndIf

		WEnd

	EndIf

	FileClose($DefaultSearch)
	ReDim $aThemeList[$aThemeList[0] + 1]
	Return $aThemeList

EndFunc   ;==>_GetDefaultThemes

Func _setWallPaper($SavedWallpaper)

	If Not FileExists($SavedWallpaper) Then Return -1
	Dim $szDrive, $szDir, $szFName, $szExt
	$WallPath = _PathSplit($SavedWallpaper, $szDrive, $szDir, $szFName, $szExt)
	$FullWallpaper = _PathFull($WallPath[2] & "\" & $WallPath[3] & $WallPath[4])
	Local $SPI_SETDESKWALLPAPER = 20
	Local $SPIF_UPDATEINIFILE = 1
	Local $SPIF_SENDCHANGE = 2
	Local $REG_DESKTOP = "HKEY_CURRENT_USERControl PanelDesktop"
	RegWrite($REG_DESKTOP, "TileWallPaper", "REG_SZ", 0)
	RegWrite($REG_DESKTOP, "WallpaperStyle", "REG_SZ", 10)

	DllCall("user32.dll", "int", "SystemParametersInfo", _
			"int", $SPI_SETDESKWALLPAPER, _
			"int", 0, _
			"str", $FullWallpaper, _
			"int", BitOR($SPIF_UPDATEINIFILE, $SPIF_SENDCHANGE))
	Return 0

EndFunc   ;==>_setWallPaper

Func _SaveWallpaper($WallpaperPath)

	$CurWallpaper = RegRead("HKEY_CURRENT_USER\Control Panel\Desktop", "Wallpaper")
	FileCopy($CurWallpaper, $DataFolder & "Themes\" & $CurrentTextInput & "\RainThemes.bmp", 9)

EndFunc   ;==>_SaveWallpaper

Func _SaveScreen($ScreenName)

	Send("#m")
	Sleep(1000)
	_ScreenCapture_Capture("RainThemes.bmp")
	Send("#+m")

EndFunc   ;==>_SaveScreen

Func _PreserveSettings($SectionToPreserve, $SettingToPreserve, $SettingValue)

	If $SettingValue <> "" Then
		IniWrite ($DataFolder & "Rainmeter.ini", $SectionToPreserve, $SettingToPreserve, $SettingValue)
	EndIf

EndFunc    ;==>_PreserveSettings

#cs
	===========================================================================================================
	End of RainThemes code
	===========================================================================================================
#ce
