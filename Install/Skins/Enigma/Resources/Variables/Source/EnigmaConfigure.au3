#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=EnigmaConfigure.ico
#AutoIt3Wrapper_UseUpx=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GUIConstantsEx.au3>
#include <GUIListBox.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <ScrollBarConstants.au3>
#include <array.au3>
#include <GuiStatusBar.au3>
#include <GuiEdit.au3>
#include <GuiButton.au3>
#include <Misc.au3>
#include <String.au3>
#Include <File.au3>
#include "FileListToArrayXT.au3"

Opt("GUICloseOnESC", 0)
Global $DarkText = 0x000000, $LightText = 0x808080, $BlueText = 0x99b0d1
Global $CurrentVarName

Global $VarName[999]
Global $VarDescription[999]
Global $VarDefault[999]
Global $VarNew[999]
Global $iniFiles[999]
Global $VarCount = 0
Global $FilesCount = 0
Global $ListCount = 0
Global $EndIt = 0
Global $Foundini = 0
Global $DefaultExists = 0, $UserExists = 0, $BothExist = 0
Global $CfgFile
Global $DefaultKeys
Global $FoundInUser
Global $Dirty = 0

$WorkingDir = @TempDir & "\EnigmaConfigure\"
DirCreate($WorkingDir)

FileInstall ("EnigmaConfigure.bmp", $WorkingDir & "EnigmaConfigure.bmp", 1)

$dll = DllOpen("user32.dll")

$MainForm = GUICreate("Enigma Configuration Tool", 382, 450, -1, -1)
$BannerPic = GUICtrlCreatePic($WorkingDir & "EnigmaConfigure.bmp", 0, 0, 400, 60)
$Instructions1Label = GUICtrlCreateLabel("Select an item, then modify it and click " & chr(34) & "Set Value" & chr(34) & " below.", 10, 71, 311, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$Instructions2Label = GUICtrlCreateLabel("Click " & chr(34) & "Save All" & chr(34) & "when done.", 10, 89, 311, 19)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
$VariableList = GUICtrlCreateList("", 10, 118, 272, 261, BitOR($ES_AUTOVSCROLL,$ES_AUTOHSCROLL,$WS_HSCROLL,$WS_VSCROLL)) ;371
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetCursor(-1,0)
$VariableDescripton = GUICtrlCreateLabel("Click an item and enter your value", 10, 387, 272, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$VariableInput = GUICtrlCreateInput("", 10, 407, 272, 21,BitOR($ES_AUTOHSCROLL,$LBS_WANTKEYBOARDINPUT))
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$ButtonSave = GUICtrlCreateButton("Save All", 289, 117, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Save all entries you have modified", "")
$ButtonReset = GUICtrlCreateButton("Reset", 289, 177, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetTip(-1, "Reset to previously saved values", "")
$ButtonDefaults = GUICtrlCreateButton("Defaults", 289, 212, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetCursor(-1,0)
GUICtrlSetTip(-1, "Restore UNCONFIGURED DEFAULTS", "")
$ButtonSet = GUICtrlCreateButton("Set Value", 289, 402, 85, 30)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetCursor(-1,0)
GUICtrlSetTip(-1, "Set the change to this item", "")

GUISetState(@SW_SHOWNORMAL, $MainForm)

Main()

While 1

	$nMsg = GUIGetMsg()

	Select

		Case $nMsg = $GUI_EVENT_CLOSE
			If $Dirty = 1 Then
				$ExitAnswer = MsgBox(49,"Enigma Configure","You have made unsaved changes." & @CRLF & @CRLF & "Are you sure you wish to exit without saving?")
				If $ExitAnswer = 1 Then
					FileClose($CfgFile)
					DllClose($dll)
					Exit
				EndIf
			Else
				FileClose($CfgFile)
				DirRemove($WorkingDir, 1)
				DllClose($dll)
				Exit
			EndIf

		Case $nMsg = $VariableList
			$CurrentVarName = GUICtrlRead($VariableList)
			For $ListCount = 1 to $VarCount
				if $VarName[$ListCount] = $CurrentVarName Then
					$CurrentVarDescription = $VarDescription[$ListCount]
				EndIf
			Next
			GUICtrlSetData($VariableDescripton, $CurrentVarDescription)
			For $a = 1 To $VarCount
				If $VarName[$a] = $CurrentVarName Then ExitLoop
			Next
			If $VarNew[$a] = "" Then $VarNew[$a] = $VarDefault[$a]
			If $VarNew[$a] == $VarDefault[$a] Then
				GUICtrlSetData($VariableInput, $VarDefault[$a])
			Else
				GUICtrlSetData($VariableInput, $VarNew[$a])
			EndIf

			Case $nMsg = $ButtonSet
				For $a = 1 To $VarCount
					If $VarName[$a] = $CurrentVarName Then ExitLoop
				Next
				$VarNew[$a] = GUICtrlRead($VariableInput)
				GUICtrlSetState($ButtonSet, $GUI_DISABLE)
				Sleep(300)
				GUICtrlSetState($ButtonSet, $GUI_ENABLE)
				$Dirty = 1

			Case $nMsg = $ButtonSave
				GUICtrlSetState($ButtonSave, $GUI_DISABLE)
				For $a = 1 To $VarCount
					If $VarNew[$a] = "" Then $VarNew[$a] = $VarDefault[$a]
					If $VarNew[$a] == $VarDefault[$a] Then
						IniWrite("UserVariables.inc","Variables",$VarName[$a], $VarDefault[$a])
					Else
						IniWrite("UserVariables.inc","Variables",$VarName[$a], $VarNew[$a])
					EndIf
				Next
				Sleep(300)
				GUICtrlSetState($ButtonSave, $GUI_ENABLE)
				$Dirty = 0

			Case $nMsg = $ButtonReset
				GUICtrlSetState($ButtonReset, $GUI_DISABLE)
				Main()
				Sleep(300)
				GUICtrlSetState($ButtonReset, $GUI_ENABLE)
				$Dirty = 0

			Case $nMsg = $ButtonDefaults
				GUICtrlSetState($ButtonDefaults, $GUI_DISABLE)
				If FileExists("DefaultVariables.sav") <> - 1 Then
					$DefaultsAnswer = MsgBox(33,"Enigma Configuration","This will reset all Enigma variables to the DEFAULT values!"  & @CRLF & @CRLF & "Are you sure you wish to clear all changes to Enigma variables"  & @CRLF & @CRLF & "and start over with default placeholder values?")
					If $DefaultsAnswer = 1 Then
						FileCopy("DefaultVariables.sav", "UserVariables.inc", 1)
					EndIf
				Else
					MsgBox(32,"Enigma Configuration","Missing 'DefaultVariables.sav' backup file" & @CRLF & @CRLF & "Unable to restore default variable values")
				EndIf
				main()
				Sleep(300)
				GUICtrlSetState($ButtonDefaults, $GUI_ENABLE)
				$Dirty = 0

	EndSelect

WEnd

Func Main()

	Global $VarName[999]
	Global $VarDescription[999]
	Global $VarDefault[999]
	Global $VarNew[999]
	Global $iniFiles[999]
	Global $VarCount = 0
	Global $FilesCount = 0
	Global $ListCount = 0
	Global $EndIt = 0
	Global $Foundini = 0
	Global $DefaultExists = 0, $UserExists = 0, $BothExist = 0
	Global $CfgFile
	Global $DefaultKeys
	Global $FoundInUser

	FileClose($CfgFile)

	GUICtrlSetData($VariableList, "")

	If FileExists("DefaultVariables.inc") <> 0 Then $DefaultExists = 1
	If FileExists("UserVariables.inc") <> 0 Then $UserExists = 1
	If FileExists("DefaultVariables.sav") <> 0 Then $DefSaveExists = 1
	If $DefaultExists = 1 And $UserExists = 1 Then $BothExist = 1

	If $DefaultExists = 1 And $BothExist = 0 Then
		FileCopy("DefaultVariables.inc", "UserVariables.inc", 1)
		FileMove("DefaultVariables.inc", "DefaultVariables.sav", 1)
		If FileFindFirstFile("..\..\..\Backup\Enigma*") <> -1 Then
			$BackupArray = _FileListToArrayXT("..\..\..\Backup\", "UserVariables.inc", 1, 2, True, "Desktop.ini", 1)
			If IsArray($BackupArray) Then
				MsgBox(64, "EnigmaConfigure", "Enigma Configure has detected that you had previously saved settings from an earlier version of Enigma. These settings have been restored.")
				Dim $BackupDateArray[50][3]
				$b = 0
				For $a = 1 to $BackupArray[0]
					If _ArraySearch($BackupArray, "Enigma", $a, $a, 0, 1) <> -1 Then
						$b = $b + 1
						$BackupDateArray[$b][1] = $BackupArray[$a]
						$BackupDateArray[$b][2] = FileGetTime($BackupArray[$a],0,1)
					EndIf
				Next
				_ArraySort($BackupDateArray, 1, 0, 0,2)
				FileCopy($BackupDateArray[0][1],".\UserVariables.inc",1)
				$BackupFolder = StringLeft($BackupDateArray[0][1], StringInStr($BackupDateArray[0][1],"Resources")-1)
				FileCopy($BackupFolder & "Sidebar\Notes\Notes.txt", "..\..\Sidebar\Notes\Notes.txt", 1)
				$DefaultKeys = IniReadSection("DefaultVariables.sav", "Variables" )
					If IsArray($DefaultKeys) Then
						For $a = 1 To $DefaultKeys[0][0]
							$FoundInUser = IniRead("UserVariables.inc","Variables",$DefaultKeys[$a][0],"KeyMissing")
							If $FoundInUser = "KeyMissing" Then
								IniWrite("UserVariables.inc","Variables", $DefaultKeys[$a][0],$DefaultKeys[$a][1])
							EndIf
						Next
					EndIf
			EndIf
		EndIf
	EndIf

	If $DefaultExists = 0 And $UserExists = 0 Then
		If $DefSaveExists = 1 Then
			FileCopy("DefaultVariables.sav", "UserVariables.inc", 1)
			$DefaultExists = 1
		Else
			MsgBox(16,"EnigmaConfigure Error!", "Variables files!" & @CRLF & @CRLF & "Please reinstall Enigma")
		EndIf
	EndIf

	If $DefaultExists = 1 And $BothExist = 1 Then
		$DefaultKeys = IniReadSection("DefaultVariables.inc", "Variables" )
			If IsArray($DefaultKeys) Then
				For $a = 1 To $DefaultKeys[0][0]
					$FoundInUser = IniRead("UserVariables.inc","Variables",$DefaultKeys[$a][0],"KeyMissing")
					If $FoundInUser = "KeyMissing" Then
						IniWrite("UserVariables.inc","Variables", $DefaultKeys[$a][0],$DefaultKeys[$a][1])
					EndIf
				Next
			Else
				MsgBox(16,"EnigmaConfigure Error!", "Invalid DefaultVariables.inc file" & @CRLF & @CRLF & "Please reinstall Enigma")
				Exit
			EndIf
		FileMove("DefaultVariables.inc", "DefaultVariables.sav", 1)
	EndIf

	If FileFindFirstFile("..\..\..\Enigma.*") = -1 Then
	MsgBox(16, "EnigmaConfigure Error!", "Unable to locate \Skins\Enigma" & @CRLF & @CRLF & "EnigmaConfigure.exe must reside in" & @CRLF & _
			"\Skins\Enigma\Resources\Variables")
	Exit
	EndIf

	$SkinPath = "..\..\..\Enigma\"
	$SkinArray = _FileListToArrayXT($SkinPath, "*.ini", 1, 2, True, "Desktop.ini", 1)
	For $a = 1 To $SkinArray[0]
		_ReplaceStringInFile($SkinArray[$a],"@include=#SKINSPATH#Enigma\Resources\Variables\DefaultVariables.inc","@include=#SKINSPATH#Enigma\Resources\Variables\UserVariables.inc")
	Next

	$CfgFile = FileOpen ("EnigmaConfigure.cfg", 0)
	$VariableSection = FileReadLine ($CfgFile)

	Do
		$VarCount = $VarCount + 1
		$VarName[$VarCount] = FileReadLine ($CfgFile)
		$VarDescription[$VarCount] = FileReadLine ($CfgFile)
		$VarDefault[$VarCount] = IniRead("UserVariables.inc","Variables",$VarName[$VarCount],"")
		If $VarName[$VarCount] = "[Files]" Then $EndIt = 1
	Until $EndIt = 1

	$iniFiles[1] = $VarDescription[$VarCount]
	$FilesCount = $FilesCount + 1

	While @error <> -1
		$FilesCount = $FilesCount + 1
		$iniFiles[$FilesCount] = FileReadLine ($CfgFile)
	WEnd

	FileClose ($CfgFile)
	$VarCount = $VarCount - 1
	$FilesCount = $FilesCount - 1

	For $ListCount = 1 to $VarCount
	GUICtrlSetData($VariableList,$VarName[$ListCount] & "|")
	Next

	ControlCommand ( "", "", $VariableList, "SetCurrentSelection", 0)

EndFunc ;==>Main
