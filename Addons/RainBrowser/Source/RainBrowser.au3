#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_icon=RB.ico
#AutoIt3Wrapper_UseUpx=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs
	===========================================================================================================
	RainBrowser
	Copyright: 2009 Jeffrey Morley
	License: Creative Commons Attribution-Non-Commercial-Share Alike 3.0
	===========================================================================================================

	===========================================================================================================
	Initialize variables and application defaults
	===========================================================================================================
#ce

;**** Directives created by AutoIt3Wrapper_GUI ****
#EndRegion
;**** Directives created by AutoIt3Wrapper_GUI ****

#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <GDIPlus.au3>
#include <Array.au3>
#include <file.au3>
#include <GuiTreeView.au3>
#include <StructureConstants.au3>
#include <TreeViewConstants.au3>
#include <ListboxConstants.au3>
#include <GUIListBox.au3>
#include <EditConstants.au3>
#include <Misc.au3>
#include <FontConstants.au3>
#include "FileListToArrayXT.au3"
#include <SliderConstants.au3>
#include <GuiSlider.au3>
#include <SQLite.au3>
#include <SQLite.dll.au3>
#include <TabConstants.au3>
#Include <WinAPI.au3>

_Singleton("RainBrowser", 0)

$WorkingDir = @TempDir & "\RainBrowser\"
DirCreate($WorkingDir)

FileInstall("TopImage.bmp", $WorkingDir & "TopImage.bmp", 1)
FileInstall("RainBrowser.bmp", $WorkingDir & "RainBrowser.bmp", 1)
FileInstall("Tab.bmp", $WorkingDir & "Tab.bmp", 1)
FileInstall("RainThemes_sm.bmp", $WorkingDir & "RainThemes_sm.bmp", 1)
FileInstall("RainBackup_sm.bmp", $WorkingDir & "RainBackup_sm.bmp", 1)

Opt("TrayIconHide", 1)
Opt("GUICloseOnESC", 0)
Opt("GUIOnEventMode", 1)

_GDIPlus_Startup()

$TreeFont = _WinAPI_CreateFont(16, 0, 0, 0, $FW_NORMAL, False, False, False, $DEFAULT_CHARSET, $OUT_OUTLINE_PRECIS, $CLIP_DEFAULT_PRECIS, $DEFAULT_QUALITY, $DEFAULT_PITCH, 'Segoe UI')

$RainBrowserVersion = "Version 2.00"

Global $SkinArray, $NewSkinArray, $CurrentIni, $NodeCount = 0, $CustomColors = 0
Global $MainForm, $TreeSkins, $OldPath, $IniFile, $AuthorName, $Editing = False
Global $SkinPath, $DataFolder, $SplitFile, $IsConfigActive, $EditingSkinSettings
Global $szDrive, $szDir, $szFName, $szExt, $BrowseFolderLabel, $Running = 1
Global $TempCount, $ParentID, $ParentPath, $IniActive, $RunningSkins, $PreviewGUI
Global $CFGArray, $TreeArray, $ReadArray, $idActive, $idBrowse, $LabelTags
Global $SkinName, $VariantName, $SkinDesc, $VariantDesc, $TempArray, $oldImage
Global $EditPanel, $SaveSkinName, $CancelSkinName, $aRecords, $SkinList
Global $SaveSkinDesc, $CancelSkinDesc, $SaveSkinInstr, $CancelSkinInstr
Global $SkinTagsLabel, $SkinInstrLabel, $SkinInstr, $SaveSkinTags, $CancelSkinTags
Global $SaveAuthorName, $CancelAuthorName, $SaveVersionName, $CancelVersionName
Global $SaveLicenseName, $CancelLicenseName, $FileArray, $LabelMin, $SkinPreview, $SavePreviewName, $CancelPreviewName
Global $tvbParent, $tvbNode, $OldParentPath, $TempFile, $BigArray[1], $SplitBigArray
Global $iConfigNameLabel, $SettingsSaveLabel, $SettingsDividerLabel, $OldiWindowX, $OldiWindowY
Global $SettingsCancelLabel, $iPositionLabel, $PositionGroup, $Running, $Browsing
Global $PositionGroup, $StayTopMostRadio, $TopMostRadio, $TagSkins, $Tagging, $MainPos
Global $NormalRadio, $BottomRadio, $DesktopRadio, $iWindowXLabel, $iWindowYLabel
Global $iLoadOrderLabel, $iLoadOrderEdit, $OldiLoadOrder
Global $iWindowXEdit, $iWindowYEdit, $iPositionLabel, $iAlphaValueLabel, $iAlphaValueSlider
Global $iAlphaValueTicsLabel, $iHideFadeLabel, $iHideOnMouseOverRadio, $iFadeInRadio
Global $iFadeOutRadio, $iNoFadeHideRadio, $iFadeDurationSlider, $iFadeDurationLabel, $iFadeDurationTicsLabel
Global $iSavePositionCheck, $iSnapEdgesCheck, $iKeepOnScreenCheck, $iDraggableCheck, $iClickThroughCheck
Global $hQuery, $aRow, $sMsg, $iAnchorXLabel, $iAnchorXEdit, $iAnchorYLabel, $iAnchorYEdit
Global $hGraphic, $hImage, $hImage2, $DisplayTop, $DisplayW, $DisplayH, $DisplaySide = 0, $Preview = 0, $hPopup

#cs
	===========================================================================================================
	Validate Rainmeter environment and create variables for paths and files
	===========================================================================================================
#ce

$AppDataDir = EnvGet("APPDATA")

If FileFindFirstFile("..\..\Rainmeter.ini") <> -1 Then
	$DataFolder = "..\..\"
ElseIf FileFindFirstFile($AppDataDir & "\Rainmeter\Rainmeter.ini") <> -1 Then
	$DataFolder = $AppDataDir & "\Rainmeter\"
Else
	MsgBox(16, "RainBrowser Error", "Unable to locate Rainmeter.ini")
	Exit
EndIf

If FileFindFirstFile("..\..\Rainmeter.exe") = -1 Then
	MsgBox(16, "RainBrowser Error", "Unable to locate Rainmeter.exe" & @CRLF & @CRLF & "RainBrowser.exe must reside in the" & @CRLF & _
			"Rainmeter program folder" & @CRLF & "(default: Program Files\Rainmeter)" & @CRLF & @CRLF & "under \Addons\Rainbrowser")
	Exit
Else
$ProgramPath = _PathFull("..\..\")
EndIf

$Editor = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "ConfigEditor", "Notepad.exe")

$SkinPath = IniRead($DataFolder & "Rainmeter.ini", "Rainmeter", "SkinPath", "")
If FileFindFirstFile($SkinPath & "*") = -1 Then
	MsgBox(16, "RainBrowser Error", "Unable to locate Skins folder" & @CRLF & @CRLF & "Please check SkinPath= setting" & @CRLF & "in Rainmeter.ini")
	Exit
EndIf

#cs
	===========================================================================================================
	Create temporary splash screen
	===========================================================================================================
#ce

$SplashScreen = GUICreate("RainBrowser", 200, 50, -1, -1, BitOR($WS_SYSMENU, $WS_POPUP, $WS_POPUPWINDOW, $WS_BORDER, $WS_CLIPSIBLINGS))
$SplashLabel = GUICtrlCreateLabel("R a i n B r o w s e r", 1, 12, 200, 30, $SS_CENTER)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
GUISetState(@SW_SHOWNORMAL, $SplashScreen)

#cs
	===========================================================================================================
	Create main GUI and controls
	===========================================================================================================
#ce

$MainForm = GUICreate("RainBrowser", 800, 645, -1, -1, -1)
GUIRegisterMsg($WM_NOTIFY, 'WM_NOTIFY')
GUISetOnEvent($GUI_EVENT_CLOSE, "clickedExit")

$WhiteColor = _WinAPI_GetSysColor($COLOR_WINDOW)
$GreyColor = _WinAPI_GetSysColor($COLOR_BTNFACE)
$DisabledText = 0xCCCCCC

$Group1 = GUICtrlCreateGroup("", 8, 60, 195, 580)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$Group2 = GUICtrlCreateGroup("", 220, 495, 560, 145)
GUICtrlCreateGroup("", -99, -99, 1, 1)
$ConfigsLabel = GUICtrlCreateLabel("Rainmeter Configs", 15, 70, 150, 25)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
$RunningLabel = GUICtrlCreatePic($WorkingDir & "Tab.bmp",15, 96, 54,25)
GUICtrlSetTip($RunningLabel, "Display Active Configs", "")
GUICtrlSetOnEvent($RunningLabel, "clickedRunningLabel")
$RunningLabelText = GUICtrlCreateLabel(" Active", 16, 99, 52, 19)
GUICtrlSetBkColor($RunningLabelText, $WhiteColor)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$TreeLabel = GUICtrlCreatePic($WorkingDir & "Tab.bmp",71, 96, 54,25)
GUICtrlSetTip($TreeLabel, "Browse all Configs", "")
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetOnEvent($TreeLabel, "clickedTreeLabel")
$TreeLabelText = GUICtrlCreateLabel(" Browse", 72, 99, 52, 19)
GUICtrlSetBkColor($TreeLabelText, $GreyColor)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$TagsLabel = GUICtrlCreatePic($WorkingDir & "Tab.bmp",127, 96, 54,25)
GUICtrlSetTip($TagsLabel, "Browse Metadata Tags", "")
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetOnEvent($TagsLabel, "clickedTagsLabel")
$TagsLabelText = GUICtrlCreateLabel(" Tags", 128, 99, 52, 19)
GUICtrlSetBkColor($TagsLabelText, $GreyColor)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$LabelSkins = GUICtrlCreateLabel("Skins and Variants", 15, 510, 140, 18)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
$SkinList = GUICtrlCreateList("Skins", 15, 535, 180, 100, $WS_VSCROLL)
GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
GUICtrlSetOnEvent($SkinList, "clickedSkinList")
$LabelActions = GUICtrlCreateLabel("Skin Actions", 230, 510, 140, 20)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
$LoadLabel = GUICtrlCreateLabel("Load Skin", 230, 535, 100, 20)
GUICtrlSetTip($LoadLabel, "Load / Unload Selected Skin", "")
GUICtrlSetFont($LoadLabel, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($LoadLabel, 0)
GUICtrlSetOnEvent($LoadLabel, "clickedLoad")
$RefreshLabel = GUICtrlCreateLabel("Refresh Skin", 230, 555, 100, 20)
GUICtrlSetTip($RefreshLabel, "Refresh Selected Skin", "")
GUICtrlSetFont($RefreshLabel, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($RefreshLabel, 0)
GUICtrlSetOnEvent($RefreshLabel, "clickedRefresh")
$DeadRefreshLabel = GUICtrlCreateLabel("Refresh Skin", 230, 555, 100, 20)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetColor(-1, 0x808080)
$SkinSettingsLabel = GUICtrlCreateLabel("Skin Settings", 230, 575, 100, 18)
GUICtrlSetTip($SkinSettingsLabel, "Set Transparency/Position/etc.", "")
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($SkinSettingsLabel, "clickedSkinSettings")
$DeadSkinSettingsLabel = GUICtrlCreateLabel("Skin Settings", 230, 575, 100, 18)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetColor(-1, 0x808080)
$BrowseFolderLabel = GUICtrlCreateLabel("Browse Folder", 230, 595, 100, 18)
GUICtrlSetTip($BrowseFolderLabel, "Open Skin Folder in Explorer", "")
GUICtrlSetFont($BrowseFolderLabel, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($BrowseFolderLabel, 0)
GUICtrlSetOnEvent($BrowseFolderLabel, "clickedBrowseFolder")
$EditLabel = GUICtrlCreateLabel("Edit Skin", 230, 615, 100, 20)
GUICtrlSetTip($EditLabel, "Edit Selected Skin in Your Text Editor", "")
GUICtrlSetFont($EditLabel, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($EditLabel, 0)
GUICtrlSetOnEvent($EditLabel, "clickedEdit")
$LabelGlobalActions = GUICtrlCreateLabel("Global Actions", 350, 510, 140, 20)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
$RefreshGlobalLabel = GUICtrlCreateLabel("Refresh All", 350, 535, 120, 20)
GUICtrlSetTip($RefreshGlobalLabel, "Refresh all Configs", "")
GUICtrlSetFont($RefreshGlobalLabel, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($RefreshGlobalLabel, 0)
GUICtrlSetOnEvent($RefreshGlobalLabel, "clickedRefreshAll")
$RestartGlobalLabel = GUICtrlCreateLabel("Restart Rainmeter", 350, 555, 120, 20)
GUICtrlSetTip($RestartGlobalLabel, "Restart Rainmeter.exe", "")
GUICtrlSetFont($RestartGlobalLabel, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($RestartGlobalLabel, 0)
GUICtrlSetOnEvent($RestartGlobalLabel, "clickedRestart")
$BrowseGlobalLabel = GUICtrlCreateLabel("Browse Skins", 350, 575, 120, 20)
GUICtrlSetTip($BrowseGlobalLabel, "Open all Skin Folders in Explorer", "")
GUICtrlSetFont($BrowseGlobalLabel, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($BrowseGlobalLabel, 0)
GUICtrlSetOnEvent($BrowseGlobalLabel, "clickedBrowseGlobal")
$EditGlobalSettings = GUICtrlCreateLabel("Edit Settings", 350, 595, 120, 20)
GUICtrlSetTip($EditGlobalSettings, "Edit Rainmeter.ini in Your Text Editor", "")
GUICtrlSetFont($EditGlobalSettings, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor($EditGlobalSettings, 0)
GUICtrlSetOnEvent($EditGlobalSettings, "clickedEditGlobalSettings")
$SuiteNameLabel = GUICtrlCreateLabel("", 230, 70, 450, 20)
GUICtrlSetFont(-1, 12, 400, 0, "Segoe UI")
$SkinNameLabel = GUICtrlCreateLabel("", 230, 95, 450, 30)
GUICtrlSetFont(-1, 17, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($SkinNameLabel, "clickedSkinNameLabel")
$SkinDescTextLabel = GUICtrlCreateLabel("Description", 230, 142, 80, 20)
GUICtrlSetFont(-1, 11, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($SkinDescTextLabel, "clickedSkinDescTextLabel")
$SkinDescValueLabel = GUICtrlCreateEdit("", 230, 165, 550, 55, BitOR($ES_READONLY, $WS_VSCROLL), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$SkinInstrLabel = GUICtrlCreateLabel("Instructions", 230, 230, 80, 20)
GUICtrlSetFont(-1, 11, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($SkinInstrLabel, "clickedSkinInstrLabel")
$SkinInstrEdit = GUICtrlCreateEdit("", 230, 255, 550, 55, BitOR($ES_READONLY, $WS_VSCROLL), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$SkinTagsLabel = GUICtrlCreateLabel("Tags", 230, 325, 30, 20)
GUICtrlSetFont(-1, 11, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($SkinTagsLabel, "clickedEditTags")
$SkinTagsEdit = GUICtrlCreateEdit("", 230, 350, 550, 55, BitOR($ES_READONLY, $WS_VSCROLL), 0)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$AuthorLabel = GUICtrlCreateLabel("Author:", 230, 405, 50, 20)
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($AuthorLabel, "clickedAuthorLabel")
$AuthorNameLabel = GUICtrlCreateLabel("", 282, 406, 205, 20,$SS_LEFTNOWORDWRAP)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$VersionLabel = GUICtrlCreateLabel("Version:", 500, 405, 50, 20)
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($VersionLabel, "clickedVersionLabel")
$VersionNameLabel = GUICtrlCreateLabel("", 556, 406, 100, 20,$SS_LEFTNOWORDWRAP)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$LicenseLabel = GUICtrlCreateLabel("License:", 230, 437, 50, 20)
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($LicenseLabel, "clickedLicenseLabel")
$LicenseNameLabel = GUICtrlCreateLabel("", 286, 438, 460, 20,$SS_LEFTNOWORDWRAP)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$PreviewLabel = GUICtrlCreateLabel("Preview:", 230, 470, 50, 20)
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($PreviewLabel, "clickedPreviewLabel")
$PreviewNameLabel = GUICtrlCreateLabel("", 288, 471, 370, 20,$SS_LEFTNOWORDWRAP)
GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
$PreviewViewLabel = GUICtrlCreateLabel("View", 665, 470, 50, 20)
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($PreviewViewLabel, "clickedPreviewViewLabel")
$PreviewBrowseLabel = GUICtrlCreateLabel("Browse", 710, 470, 50, 20)
GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($PreviewBrowseLabel, "clickedPreviewBrowseLabel")
$BannerPic = GUICtrlCreatePic($WorkingDir & "RainBrowser.bmp", 0, 0, 800, 60)
GuiCtrlSetState(-1,$GUI_DISABLE)
$RainThemesPic = GUICtrlCreatePic($WorkingDir & "RainThemes_sm.bmp", 560, 27, 110, 27)
GUICtrlSetTip($RainThemesPic, "Run the RainThemes Application", "")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($RainThemesPic, "clickedRainThemes")
$RainBackupPic = GUICtrlCreatePic($WorkingDir & "RainBackup_sm.bmp", 675, 27, 110, 27)
GUICtrlSetTip($RainBackupPic, "Run the RainBackup Application", "")
GUICtrlSetCursor(-1, 0)
GUICtrlSetOnEvent($RainBackupPic, "clickedRainBackup")
$TopImage = GUICtrlCreatePic($WorkingDir & "TopImage.bmp", 210, 145, 578, 325, Default)

If FileExists(".\RainBrowserColors.ini") Then
	$MainBackgroundColor = IniRead(".\RainBrowserColors.ini", "RainBrowserColors", "MainBackground","")
	If $MainBackgroundColor <> "" Then
		$CustomColors = 1
		GUISetBkColor($MainBackgroundColor, $MainForm)
		GUICtrlSetBkColor($SkinDescTextLabel, $MainBackgroundColor)
		GUICtrlSetBkColor($SkinInstrEdit, $MainBackgroundColor)
		GUICtrlSetBkColor($SkinTagsEdit, $MainBackgroundColor)
	EndIf
	$TreeBackgroundColor = IniRead(".\RainBrowserColors.ini", "RainBrowserColors", "TreeBackground","")
	If $TreeBackgroundColor <> "" Then
			GUICtrlSetBkColor($SkinList, $TreeBackgroundColor)
		$CustomColors = 1
	EndIf
EndIf

#cs
	===========================================================================================================
	Initial display of main GUI
	===========================================================================================================
#ce

ControlHide("", "", $TopImage)
_GetSkins()
_GetActive()
GUIDelete($SplashScreen)
GUISetState(@SW_SHOWNORMAL, $MainForm)
_HideRightScreen(3)
clickedRunningLabel()

#cs
	===========================================================================================================
	Processing loop.  Waiting for clicks to fire functions
	===========================================================================================================
#ce

While 1

	If $EditingSkinSettings = 0 Then
		If ProcessExists("Rainmeter.exe") = 0 Then
			If GUICtrlGetState($RefreshGlobalLabel) <> $GUI_DISABLE Then GUICtrlSetState($RefreshGlobalLabel, $GUI_DISABLE)
			If GUICtrlGetState($LoadLabel) <> $GUI_DISABLE Then GUICtrlSetState($LoadLabel, $GUI_DISABLE)
			If GUICtrlGetState($RefreshLabel) <> $GUI_DISABLE Then GUICtrlSetState($RefreshLabel, $GUI_DISABLE)
			If GUICtrlGetState($DeadRefreshLabel) <> $GUI_DISABLE Then GUICtrlSetState($DeadRefreshLabel, $GUI_DISABLE)
		Else
			If GUICtrlGetState($RefreshGlobalLabel) <> $GUI_ENABLE Then GUICtrlSetState($RefreshGlobalLabel, $GUI_ENABLE)
			If GUICtrlGetState($LoadLabel) <> $GUI_ENABLE Then GUICtrlSetState($LoadLabel, $GUI_ENABLE)
			If GUICtrlGetState($RefreshLabel) <> $GUI_ENABLE Then GUICtrlSetState($RefreshLabel, $GUI_ENABLE)
			If GUICtrlGetState($DeadRefreshLabel) <> $GUI_ENABLE Then GUICtrlSetState($DeadRefreshLabel, $GUI_ENABLE)
		EndIf
	EndIf
	Sleep(500)

WEnd

#cs
	===========================================================================================================
	All below here are functions
	===========================================================================================================
#ce

#cs
	===========================================================================================================
	Closing Application - Exit
	===========================================================================================================
#ce

Func clickedExit()
	_ManageDatabase(2)
	GUIDelete()
	_GDIPlus_Shutdown()
	DirRemove($WorkingDir, 1)
	Exit
EndFunc   ;==>clickedExit

#cs
	===========================================================================================================
	Clicked on Active | Browse | Tags on top left
	===========================================================================================================
#ce

Func clickedRunningLabel()
	If $Editing Then Return
	If $EditingSkinSettings Then Return
	$Running = 1
	$Browsing = 0
	$Tagging = 0
	GUICtrlSetBkColor($RunningLabelText, $WhiteColor)
	GUICtrlSetBkColor($TreeLabelText, $GreyColor)
	GUICtrlSetBkColor($TagsLabelText, $GreyColor)
	ControlHide("", "", $SkinList)
	GUICtrlSetData($SkinList, "")
	ControlHide("", "", $TreeSkins)
	ControlHide("", "", $TagSkins)
	ControlShow("", "", $RunningSkins)
	ControlShow("", "", $RunningLabel)
	ControlShow("", "", $TreeLabel)
	ControlShow("", "", $SkinList)
	_GetActive()

	_GUICtrlTreeView_ClickItem($RunningSkins, _GUICtrlTreeView_GetFirstItem($RunningSkins))
EndFunc   ;==>clickedRunningLabel

Func clickedTreeLabel()
	If $Editing Then Return
	If $EditingSkinSettings Then Return
	$Running = 0
	$Browsing = 1
	$Tagging = 0
	$Preview = 0
	GUICtrlSetBkColor($RunningLabelText, $GreyColor)
	GUICtrlSetBkColor($TreeLabelText, $WhiteColor)
	GUICtrlSetBkColor($TagsLabelText, $GreyColor)
	ControlHide("", "", $RunningSkins)
	ControlHide("", "", $TagSkins)
	ControlHide("", "", $SkinList)
	GUICtrlSetData($SkinList, "")
	ControlShow("", "", $TreeSkins)
	ControlShow("", "", $SkinList)
	ControlShow("", "", $RunningLabel)
	ControlShow("", "", $TreeLabel)
	_GetSkins()
	_GUICtrlTreeView_ClickItem($TreeSkins, _GUICtrlTreeView_GetFirstItem($TreeSkins))
EndFunc   ;==>clickedTreeLabel

Func clickedTagsLabel()
	If $Editing Then Return
	If $EditingSkinSettings Then Return
	$Running = 0
	$Browsing = 0
	$Tagging = 1
	$Preview = 0
	GUICtrlSetBkColor($RunningLabelText, $GreyColor)
	GUICtrlSetBkColor($TreeLabelText, $GreyColor)
	GUICtrlSetBkColor($TagsLabelText, $WhiteColor)
	ControlHide("", "", $SkinList)
	ControlHide("", "", $RunningSkins)
	ControlHide("", "", $TreeSkins)
	GUICtrlSetData($SkinList, "")
	ControlShow("", "", $TagSkins)
	ControlShow("", "", $SkinList)
	_GetTags()
	_GUICtrlTreeView_ClickItem($TagSkins, _GUICtrlTreeView_GetFirstItem($TagSkins))

EndFunc   ;==>clickedTagsLabel

#cs
	===========================================================================================================
	Clicked on controls on lower right
	===========================================================================================================
#ce

Func clickedLoad()
	If $Editing Then Return
	GUICtrlSetState($LoadLabel, $GUI_DISABLE)
	If $IniActive = 0 Then
		ShellExecute($ProgramPath & "rainmeter.exe", "!RainmeterActivateConfig " & ChrW(34) & StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1) & ChrW(34) & " " & ChrW(34) & GUICtrlRead($SkinList) & ChrW(34))
		Sleep(500)
		If $Running = 1 Then
			_GetActive()
			ControlClick("", "", $RunningLabel)
		EndIf
		clickedSkinList()
		$IniActive = 1
	Else
		ShellExecute($ProgramPath & "Rainmeter.exe", "!RainmeterDeactivateConfig " & ChrW(34) & StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1) & ChrW(34))
		Sleep(500)
		If $Running = 1 Then
			_GetActive()
			ControlClick("", "", $RunningLabel)
		EndIf
		clickedSkinList()
		$IniActive = 0
	EndIf
	GUICtrlSetState($LoadLabel, $GUI_ENABLE)
EndFunc   ;==>clickedLoad

Func clickedBrowseFolder()
	If $Editing Then Return
	GUICtrlSetState($BrowseFolderLabel, $GUI_DISABLE)
	ShellExecute("explorer.exe", ChrW(34) & $SkinPath & $SplitBigArray[4] & ChrW(34))
	Sleep(300)
	GUICtrlSetState($BrowseFolderLabel, $GUI_ENABLE)
EndFunc   ;==>clickedBrowseFolder

Func clickedBrowseGlobal()
	If $Editing Then Return
	GUICtrlSetState($BrowseGlobalLabel, $GUI_DISABLE)
	ShellExecute("explorer.exe", $SkinPath)
	Sleep(300)
	GUICtrlSetState($BrowseGlobalLabel, $GUI_ENABLE)
EndFunc   ;==>clickedBrowseGlobal

Func clickedRefresh()
	If $Editing Then Return
	GUICtrlSetState($RefreshLabel, $GUI_DISABLE)
	ShellExecute($ProgramPath & "Rainmeter.exe", "!RainmeterRefresh " & ChrW(34) & StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1) & ChrW(34))
	Sleep(300)
	GUICtrlSetState($RefreshLabel, $GUI_ENABLE)
EndFunc   ;==>clickedRefresh

Func clickedRefreshAll()
	If $Editing Then Return
	GUICtrlSetState($RefreshGlobalLabel, $GUI_DISABLE)
	ShellExecute($ProgramPath & "Rainmeter.exe", "!RainmeterRefreshApp")
	Sleep(300)
	GUICtrlSetState($RefreshGlobalLabel, $GUI_ENABLE)
EndFunc   ;==>clickedRefreshAll

Func clickedRestart()
	If $Editing Then Return
	GUICtrlSetState($RestartGlobalLabel, $GUI_DISABLE)
	ShellExecute($ProgramPath & "Rainmeter.exe", "!RainmeterQuit")
	Sleep(1200)
	ShellExecute($ProgramPath & "Rainmeter.exe")
	GUICtrlSetState($RestartGlobalLabel, $GUI_ENABLE)
EndFunc   ;==>clickedRestart

Func clickedEdit()
	If $Editing Then Return
	GUICtrlSetState($EditLabel, $GUI_DISABLE)
	ShellExecute($Editor, ChrW(34) & $SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList) & ChrW(34))
	Sleep(300)
	GUICtrlSetState($EditLabel, $GUI_ENABLE)
EndFunc   ;==>clickedEdit

Func clickedEditGlobalSettings()
	If $Editing Then Return
	GUICtrlSetState($EditGlobalSettings, $GUI_DISABLE)
	Sleep(300)
	ShellExecute($Editor, ChrW(34) & $DataFolder & "Rainmeter.ini" & ChrW(34))
	GUICtrlSetState($EditGlobalSettings, $GUI_ENABLE)
EndFunc   ;==>clickedEditGlobalSettings

Func clickedLinkLabel()
	ShellExecute("http://rainmeter.net")
EndFunc   ;==>clickedLinkLabel

Func clickedRainThemes()
	ShellExecute($ProgramPath & "Addons\RainThemes\RainThemes.exe", "", $ProgramPath & "Addons\RainThemes\")
EndFunc   ;==>clickedRainThemes

Func clickedRainBackup()
	ShellExecute($ProgramPath & "Addons\RainBackup\RainBackup.exe", "", $ProgramPath & "Addons\RainBackup\")
EndFunc   ;==>clickedRainBackup

#cs
	===========================================================================================================
	Clicked on a SKIN: Display Metadata in top right screen and enable controls on bottom right
	===========================================================================================================
#ce

Func clickedSkinList()
	If $Editing Then Return
	If $EditingSkinSettings Then Return
	$Preview = 0
	$FindPreview = -1

	ControlHide("", "", $TopImage)
	ControlHide("", "", $AuthorNameLabel)
	ControlHide("", "", $SuiteNameLabel)
	ControlHide("", "", $SkinNameLabel)
	ControlHide("", "", $SkinDescValueLabel)
	ControlHide("", "", $SkinInstrEdit)
	ControlHide("", "", $SkinTagsEdit)
	ControlHide("", "", $VersionNameLabel)
	ControlHide("", "", $LicenseNameLabel)
	ControlHide("", "", $PreviewNameLabel)

	ControlShow("", "", $AuthorLabel)
	ControlShow("", "", $SkinDescTextLabel)
	ControlShow("", "", $SkinInstrLabel)
	ControlShow("", "", $SkinTagsLabel)
	ControlShow("", "", $VersionLabel)
	ControlShow("", "", $LicenseLabel)
	ControlShow("", "", $PreviewLabel)
	ControlShow("", "", $PreviewBrowseLabel)
	ControlShow("", "", $SkinList)

	If $Browsing = 1 Then
		For $a = 1 To $BigArray[0]
			$SplitBigArray = StringSplit($BigArray[$a], "|")
			If $SplitBigArray[5] = _GUICtrlTreeView_GetSelection($TreeSkins) Then ExitLoop
		Next
	ElseIf $Running = 1 Then
		For $a = 1 To $BigArray[0]
			$SplitBigArray = StringSplit($BigArray[$a], "|")
			If $SplitBigArray[4] = _GUICtrlTreeView_GetText($RunningSkins, _GUICtrlTreeView_GetSelection($RunningSkins)) & "\" Then ExitLoop
		Next
	ElseIf $Tagging = 1 Then
		For $a = 1 To $BigArray[0]
			$SplitBigArray = StringSplit($BigArray[$a], "|")
			If $SplitBigArray[4] = _GUICtrlTreeView_GetText($TagSkins, _GUICtrlTreeView_GetSelection($TagSkins)) Then ExitLoop
		Next
	EndIf

	$IniFile = $SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList)

	GUICtrlSetData($BrowseFolderLabel, "Browse Folder")

	$TempMetaArray = StringSplit(StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "\")
	GUICtrlSetData($SuiteNameLabel, $TempMetaArray[1])
	ControlShow("", "", $SuiteNameLabel)

	GUICtrlSetData($SkinNameLabel, StringLeft(GUICtrlRead($SkinList), StringLen(GUICtrlRead($SkinList)) - 4))
	ControlShow("", "", $SkinNameLabel)

	$IsConfigActive = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "Active", "0")
	$TempSkinNumArray = _FileListToArray($SkinPath & $SplitBigArray[4], "*.ini", 1)
	$IniActive = 0

	For $a = 1 To $TempSkinNumArray[0]

		If GUICtrlRead($SkinList) = $TempSkinNumArray[$IsConfigActive] Then
			$IniActive = 1
			ExitLoop
		Else
			$IniActive = 0
		EndIf
	Next

	If $IniActive = 0 Then
		GUICtrlSetData($LoadLabel, "Load Skin")
		ControlHide("", "", $RefreshLabel)
		ControlShow("", "", $DeadRefreshLabel)
		ControlHide("", "", $SkinSettingsLabel)
		ControlShow("", "", $DeadSkinSettingsLabel)
	ElseIf $IniActive = 1 Then
		GUICtrlSetData($LoadLabel, "Unload Skin")
		ControlShow("", "", $RefreshLabel)
		ControlHide("", "", $DeadRefreshLabel)
		ControlShow("", "", $SkinSettingsLabel)
		ControlHide("", "", $DeadSkinSettingsLabel)
	EndIf

	ControlShow("", "", $LoadLabel)
	ControlShow("", "", $EditLabel)
	ControlShow("", "", $BrowseFolderLabel)

	$AuthorName = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Rainmeter", "Author", "")

	If $AuthorName <> "" Then
		GUICtrlSetData($AuthorNameLabel, $AuthorName)
		ControlShow("", "", $AuthorNameLabel)
	EndIf

	$SkinName = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "Name", "")
	If $SkinName <> "" Then GUICtrlSetData($SkinNameLabel, $SkinName)
	$ConfigName = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "Config", "")
	If $ConfigName <> "" Then
		$TempMetaArray = StringSplit($ConfigName, "|")
		GUICtrlSetData($SuiteNameLabel, $TempMetaArray[1])
		ControlShow("", "", $SuiteNameLabel)
	EndIf
	$SkinDesc = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "Description", "")
	If $SkinDesc <> "" Then
		$TempMetaArray = StringSplit($SkinDesc, " | ", 1)
		If IsArray($TempMetaArray) Then
			$SkinDesc = ""
			For $a = 1 To $TempMetaArray[0] - 1
				$SkinDesc = $SkinDesc & $TempMetaArray[$a] & @CRLF
			Next
			$SkinDesc = $SkinDesc & $TempMetaArray[$a]
		EndIf
		GUICtrlSetData($SkinDescValueLabel, $SkinDesc)
		ControlShow("", "", $SkinDescValueLabel)
	EndIf
	$SkinInstr = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "Instructions", "")
	If $SkinInstr <> "" Then
		$TempMetaArray = StringSplit($SkinInstr, " | ", 1)
		If IsArray($TempMetaArray) Then
			$SkinInstr = ""
			For $a = 1 To $TempMetaArray[0] - 1
				$SkinInstr = $SkinInstr & $TempMetaArray[$a] & @CRLF
			Next
			$SkinInstr = $SkinInstr & $TempMetaArray[$a]
		EndIf
		GUICtrlSetData($SkinInstrEdit, $SkinInstr)
		ControlShow("", "", $SkinInstrEdit)
	EndIf
	$SkinTags = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "Tags", "")
	If $SkinTags <> "" Then
		GUICtrlSetData($SkinTagsEdit, $SkinTags)
		ControlShow("", "", $SkinTagsEdit)
	EndIf
	$SkinVersion = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "Version", "")
	If $SkinVersion <> "" Then
		GUICtrlSetData($VersionNameLabel, $SkinVersion)
		ControlShow("", "", $VersionNameLabel)
	EndIf
	$SkinLicense = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "License", "")
	If $SkinLicense <> "" Then
		GUICtrlSetData($LicenseNameLabel, $SkinLicense)
		ControlShow("", "", $LicenseNameLabel)
	EndIf
	$VariantName = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "VariantName", "")

 	$SkinPreview = "" & IniRead($SkinPath & $SplitBigArray[4] & GUICtrlRead($SkinList), "Metadata", "Preview", "")
 	GUICtrlSetData($PreviewNameLabel, $SkinPreview)
 	ControlShow("", "", $PreviewNameLabel)
	If $SkinPreview <> "" Then
		ControlShow("", "", $PreviewViewLabel)
		If StringInStr($SkinPreview, ":\") > 0 Then
			$SkinPreview = $SkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#SKINSPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#SKINSPATH#", $SkinPath)
			$SkinPreview = $NewSkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#CURRENTPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#CURRENTPATH#", $SkinPath & $SplitBigArray[4])
			$SkinPreview = $NewSkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#PROGRAMPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#PROGRAMPATH#", "..\..\")
			$SkinPreview = $NewSkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#ADDONSPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#ADDONSPATH#", "..\..\Addons\")
			$SkinPreview = $NewSkinPreview
		Else
			$SkinPreview = $SkinPath & $SplitBigArray[4] & $SkinPreview
		EndIf
	EndIf

EndFunc   ;==>clickedSkinList

#cs
	===========================================================================================================
	Clicked on a Treeview: Active($RunningSkins) or Browse($TreeSkins) or Tags($TagSkins)
	===========================================================================================================
#ce

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
	If $Editing Then Return 1
	If $EditingSkinSettings Then Return 1

	Local $tNMHdr = DllStructCreate($tagNMHDR, $ilParam), $tNM_TREEVIEW
	Local $hWndFrom = DllStructGetData($tNMHdr, 'hWndFrom')
	Local $iIDFrom = DllStructGetData($tNMHdr, 'IDFrom')
	Local $iCode = DllStructGetData($tNMHdr, 'Code')

	If $hWndFrom = $RunningSkins Then
		Switch $iCode
			Case $TVN_SELCHANGEDA, $TVN_SELCHANGEDW
				GUICtrlSetData($SkinList, "")
				_HideRightScreen(3)
				$SelectedActive = _GUICtrlTreeView_GetText($RunningSkins, _GUICtrlTreeView_GetSelection($RunningSkins))
				ControlShow("", "", $TopImage)
				For $a = 1 To $BigArray[0]
					$SplitBigArray = StringSplit($BigArray[$a], "|")
					If StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1) = $SelectedActive Then ExitLoop
				Next
				$TempArray = _FileListToArray($SkinPath & $SplitBigArray[4], "*.ini", 1)
				$ActiveSkin = 0
				If IsArray($TempArray) Then
					For $a = 1 To $TempArray[0]
						$ActiveSkin = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4])-1), "Active", "0")
						GUICtrlSetData($SkinList, $TempArray[$a])
					Next
				EndIf
				_GUICtrlListBox_ClickItem($SkinList, $ActiveSkin -1, "left", False)
		EndSwitch
	EndIf

	If $hWndFrom = $TreeSkins Then
		Switch $iCode
			Case $TVN_SELCHANGEDA, $TVN_SELCHANGEDW
				GUICtrlSetData($SkinList, "")
				_HideRightScreen(3)
				ControlShow("", "", $TopImage)
				$SelectedActive = _GUICtrlTreeView_GetText($TreeSkins, _GUICtrlTreeView_GetSelection($TreeSkins))
				For $a = 1 To $BigArray[0]
					$SplitBigArray = StringSplit($BigArray[$a], "|")
					If $SplitBigArray[5] = _GUICtrlTreeView_GetSelection($TreeSkins) Then ExitLoop
				Next
				$TempArray = _FileListToArray($SkinPath & $SplitBigArray[4], "*.ini", 1)
				$ActiveSkin = 0
				If IsArray($TempArray) Then
					For $a = 1 To $TempArray[0]
						$ActiveSkin = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4])-1), "Active", "0")
						If $ActiveSkin = 0 Then $ActiveSkin = 1
						GUICtrlSetData($SkinList, $TempArray[$a])
					Next
				EndIf
				_GUICtrlListBox_ClickItem($SkinList, $ActiveSkin -1, "left", False)
		EndSwitch
	EndIf

	If $hWndFrom = $TagSkins Then
		Switch $iCode
			Case $TVN_SELCHANGEDA, $TVN_SELCHANGEDW
				GUICtrlSetData($SkinList, "")
				_HideRightScreen(3)
				ControlShow("", "", $TopImage)
				$ActiveSkin = 0
				$SelectedActive = _GUICtrlTreeView_GetText($TagSkins, _GUICtrlTreeView_GetSelection($TagSkins))
				If _GUICtrlTreeView_GetParentHandle($TagSkins, _GUICtrlTreeView_GetSelection($TagSkins)) <> 0 Then
					$SelectedActive = StringLeft($SelectedActive, StringLen($SelectedActive) - 1)
					For $a = 1 To $BigArray[0]
						$SplitBigArray = StringSplit($BigArray[$a], "|")
						If StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1) = $SelectedActive Then ExitLoop
					Next
					$TempArray = _FileListToArray($SkinPath & $SplitBigArray[4], "*.ini", 1)
					If IsArray($TempArray) Then
						For $a = 1 To $TempArray[0]
							$ActiveSkin = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4])-1), "Active", "0")
							If $ActiveSkin = 0 Then $ActiveSkin = 1
							GUICtrlSetData($SkinList, $TempArray[$a])
						Next
					EndIf
				EndIf
				_GUICtrlListBox_ClickItem($SkinList, $ActiveSkin -1, "left", False)
		EndSwitch
	EndIf

	Return $GUI_RUNDEFMSG

EndFunc   ;==>WM_NOTIFY

#cs
	===========================================================================================================
	Editing Metadata items on upper right screen when a skin is selected
	===========================================================================================================
#ce

Func clickedSkinNameLabel()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$SkinName = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Name", "")
	If $SkinName = "" Then $SkinName = StringLeft(GUICtrlRead($SkinList), StringLen(GUICtrlRead($SkinList)) - 4)
	ControlHide("", "", $SkinNameLabel)

	$EditPanel = GUICtrlCreateEdit($SkinName, 221, 93, 400, 35, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 17, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	Send("{END}")

	$SaveSkinName = GUICtrlCreateLabel("Save", 665, 101, 30, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SaveSkinName, "clickedSaveSkinName")

	$CancelSkinName = GUICtrlCreateLabel("Cancel", 710, 101, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelSkinName, "clickedCancelSkinName")

EndFunc   ;==>clickedSkinNameLabel

Func clickedSaveSkinName()
	GUICtrlSetData($SkinNameLabel, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Name", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinName)
	GUICtrlDelete($CancelSkinName)
	ControlShow("", "", $SkinNameLabel)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>clickedSaveSkinName

Func clickedCancelSkinName()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinName)
	GUICtrlDelete($CancelSkinName)
	ControlShow("", "", $SkinNameLabel)
	GUICtrlSetData($SkinNameLabel, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Name", ""))
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>clickedCancelSkinName

Func clickedSkinDescTextLabel()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$SkinDesc = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Description", "")
	ControlHide("", "", $SkinDescValueLabel)

	$EditPanel = GUICtrlCreateEdit($SkinDesc, 227, 162, 400, 25, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	Send("{END}")

	$SaveSkinDesc = GUICtrlCreateLabel("Save", 665, 163, 30, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SaveSkinDesc, "clickedSaveSkinDesc")

	$CancelSkinDesc = GUICtrlCreateLabel("Cancel", 710, 163, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelSkinDesc, "clickedCancelSkinDesc")
EndFunc   ;==>clickedSkinDescTextLabel

Func clickedSaveSkinDesc()
	GUICtrlSetData($SkinDescValueLabel, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Description", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinDesc)
	GUICtrlDelete($CancelSkinDesc)
	ControlShow("", "", $SkinDescValueLabel)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
	clickedSkinList()
EndFunc   ;==>clickedSaveSkinDesc

Func clickedCancelSkinDesc()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinDesc)
	GUICtrlDelete($CancelSkinDesc)
	GUICtrlSetData($SkinDescValueLabel, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Description", ""))
	ControlShow("", "", $SkinDescValueLabel)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>clickedCancelSkinDesc

Func clickedSkinInstrLabel()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$SkinInstr = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Instructions", "")
	ControlHide("", "", $SkinInstrEdit)

	$EditPanel = GUICtrlCreateEdit($SkinInstr, 227, 252, 400, 25, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	Send("{END}")

	$SaveSkinInstr = GUICtrlCreateLabel("Save", 665, 253, 30, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SaveSkinInstr, "ClickedSaveSkinInstr")

	$CancelSkinInstr = GUICtrlCreateLabel("Cancel", 710, 253, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelSkinInstr, "ClickedCancelSkinInstr")

EndFunc   ;==>clickedSkinInstrLabel

Func ClickedSaveSkinInstr()
	GUICtrlSetData($SkinInstrEdit, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Instructions", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinInstr)
	GUICtrlDelete($CancelSkinInstr)
	ControlShow("", "", $SkinInstrEdit)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
	clickedSkinList()
EndFunc   ;==>ClickedSaveSkinInstr

Func ClickedCancelSkinInstr()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinInstr)
	GUICtrlDelete($CancelSkinInstr)
	ControlShow("", "", $SkinInstrEdit)
	GUICtrlSetData($SkinInstrEdit, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Instructions", ""))
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>ClickedCancelSkinInstr

Func clickedEditTags()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$SkinTags = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Tags", "")
	ControlHide("", "", $SkinTagsEdit)

	$EditPanel = GUICtrlCreateEdit($SkinTags, 227, 347, 400, 25, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	Send("{END}")

	$SaveSkinTags = GUICtrlCreateLabel("Save", 665, 348, 30, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SaveSkinTags, "ClickedSaveSkinTags")

	$CancelSkinTags = GUICtrlCreateLabel("Cancel", 710, 348, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelSkinTags, "ClickedCancelSkinTags")
EndFunc   ;==>clickedEditTags

Func ClickedSaveSkinTags()
	GUICtrlSetData($SkinTagsEdit, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Tags", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinTags)
	GUICtrlDelete($CancelSkinTags)
	ControlShow("", "", $SkinTagsEdit)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
	clickedSkinList()
EndFunc   ;==>ClickedSaveSkinTags

Func ClickedCancelSkinTags()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveSkinTags)
	GUICtrlDelete($CancelSkinTags)
	ControlShow("", "", $SkinTagsEdit)
	GUICtrlSetData($SkinTagsEdit, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Tags", ""))
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>ClickedCancelSkinTags

Func clickedAuthorLabel()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$AuthorName = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Rainmeter", "Author", "")
	ControlHide("", "", $AuthorNameLabel)

	$EditPanel = GUICtrlCreateEdit($AuthorName, 276, 403, 200, 25, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	Send("{END}")

	$SaveAuthorName = GUICtrlCreateLabel("Save", 665, 404, 30, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SaveAuthorName, "ClickedSaveAuthorName")

	$CancelAuthorName = GUICtrlCreateLabel("Cancel", 710, 404, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelAuthorName, "ClickedCancelAuthorName")
EndFunc   ;==>clickedAuthorLabel

Func ClickedSaveAuthorName()
	GUICtrlSetData($AuthorName, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Rainmeter", "Author", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveAuthorName)
	GUICtrlDelete($CancelAuthorName)
	ControlShow("", "", $AuthorNameLabel)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
	clickedSkinList()
EndFunc   ;==>ClickedSaveAuthorName

Func ClickedCancelAuthorName()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveAuthorName)
	GUICtrlDelete($CancelAuthorName)
	ControlShow("", "", $AuthorNameLabel)
	GUICtrlSetData($AuthorName, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Rainmeter", "Author", ""))
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>ClickedCancelAuthorName


Func clickedVersionLabel()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$SkinVersion = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Version", "")
	ControlHide("", "", $VersionNameLabel)

	$EditPanel = GUICtrlCreateEdit($SkinVersion, 550, 403, 100, 25, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	Send("{END}")

	$SaveVersionName = GUICtrlCreateLabel("Save", 665, 404, 30, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SaveVersionName, "ClickedSaveVersionName")

	$CancelVersionName = GUICtrlCreateLabel("Cancel", 710, 404, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelVersionName, "ClickedCancelVersionName")
EndFunc   ;==>clickedVersionLabel

Func ClickedSaveVersionName()
	GUICtrlSetData($VersionNameLabel, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Version", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveVersionName)
	GUICtrlDelete($CancelVersionName)
	ControlShow("", "", $VersionNameLabel)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
	clickedSkinList()
EndFunc   ;==>ClickedSaveVersionName

Func ClickedCancelVersionName()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveVersionName)
	GUICtrlDelete($CancelVersionName)
	ControlShow("", "", $VersionNameLabel)
	GUICtrlSetData($VersionNameLabel, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Version", ""))
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>ClickedCancelVersionName

Func clickedLicenseLabel()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$SkinLicense = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "License", "")
	If $SkinLicense = "" Then $SkinLicense = "Creative Commons Attribution-Non-Commercial-Share Alike 3.0"
	ControlHide("", "", $LicenseNameLabel)

	$EditPanel = GUICtrlCreateEdit($SkinLicense, 280, 435, 370, 25, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	Send("{END}")

	$SaveLicenseName = GUICtrlCreateLabel("Save", 665, 436, 30, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SaveLicenseName, "ClickedSaveLicenseName")

	$CancelLicenseName = GUICtrlCreateLabel("Cancel", 710, 436, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelLicenseName, "ClickedCancelLicenseName")
EndFunc   ;==>clickedLicenseLabel

Func ClickedSaveLicenseName()
	GUICtrlSetData($LicenseNameLabel, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "License", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveLicenseName)
	GUICtrlDelete($CancelLicenseName)
	ControlShow("", "", $LicenseNameLabel)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
	clickedSkinList()
EndFunc   ;==>ClickedSaveLicenseName

Func ClickedCancelLicenseName()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SaveLicenseName)
	GUICtrlDelete($CancelLicenseName)
	ControlShow("", "", $LicenseNameLabel)
	GUICtrlSetData($LicenseNameLabel, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "License", ""))
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
EndFunc   ;==>ClickedCancelLicenseName

Func clickedPreviewLabel()
	If $Editing Then Return
	$Editing = True
	ControlHide("","",$PreviewBrowseLabel)
	ControlHide("","",$PreviewViewLabel)
	$CurrentIni = GUICtrlRead($SkinList)
	$SkinPreview = "" & IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Preview", "")
	ControlHide("", "", $PreviewNameLabel)

	$EditPanel = GUICtrlCreateEdit($SkinPreview, 282, 468, 345, 25, BitOR($ES_AUTOHSCROLL, $ES_WANTRETURN))
	GUICtrlSetBkColor($EditPanel, 0xFFFFFF)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetState($EditPanel, $GUI_FOCUS)
	;Send("{END}")

	$SavePreviewName = GUICtrlCreateLabel("Save", 665, 470, 50, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SavePreviewName, "ClickedSavePreviewName")

	$CancelPreviewName = GUICtrlCreateLabel("Cancel", 710, 470, 40, 20)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($CancelPreviewName, "ClickedCancelPreviewName")
EndFunc   ;==>clickedPreviewLabel

Func ClickedSavePreviewName()
	GUICtrlSetData($PreviewNameLabel, GUICtrlRead($EditPanel))
	IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Preview", GUICtrlRead($EditPanel))
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SavePreviewName)
	GUICtrlDelete($CancelPreviewName)
	ControlShow("", "", $PreviewNameLabel)
	ControlShow("","",$PreviewViewLabel)
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	$Editing = False
	clickedSkinList()
EndFunc   ;==>ClickedSavePreviewName

Func ClickedCancelPreviewName()
	GUICtrlDelete($EditPanel)
	GUICtrlDelete($SavePreviewName)
	GUICtrlDelete($CancelPreviewName)
	ControlShow("", "", $PreviewNameLabel)
	GUICtrlSetData($PreviewNameLabel, IniRead($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Preview", ""))
	GUICtrlSetState($SkinList, $GUI_FOCUS)
	ControlShow("","",$PreviewBrowseLabel)
	ControlShow("","",$PreviewViewLabel)
	$Editing = False
EndFunc   ;==>ClickedCancelPreviewName

Func clickedPreviewBrowseLabel()
	If $Editing Then Return
	$Editing = True
	$CurrentIni = GUICtrlRead($SkinList)
	$PreviewToLoad = FileOpenDialog("Open image file", $SkinPath & $SplitBigArray[4], "Images (*.jpg;*.png;*.bmp;*.ico)", 3)
	If $PreviewToLoad <> "" Then
		If StringLeft($PreviewToLoad,StringLen($SkinPath & $SplitBigArray[4])) = $SkinPath & $SplitBigArray[4] Then
			$PreviewToLoad = StringReplace($PreviewToLoad,$SkinPath & $SplitBigArray[4],"#CURRENTPATH#")
		EndIf
		If StringLeft($PreviewToLoad,StringLen($SkinPath)) = $SkinPath Then
			$PreviewToLoad = StringReplace($PreviewToLoad,$SkinPath,"#SKINSPATH#")
		EndIf
		IniWrite($SkinPath & $SplitBigArray[4] & $CurrentIni, "Metadata", "Preview", $PreviewToLoad)
	EndIf
	$Editing = False
	clickedSkinList()
	FileClose($PreviewToLoad)
	FileChangeDir ($ProgramPath & "Addons\RainBrowser")

EndFunc   ;==>clickedPreviewBrowseLabel

Func clickedPreviewViewLabel()
	If $PreviewGUI <> 0 Then GUIDelete($PreviewGUI)
	If $SkinPreview <> "" Then
		If StringInStr($SkinPreview, ":\") > 0 Then
			$SkinPreview = $SkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#SKINSPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#SKINSPATH#", $SkinPath)
			$SkinPreview = $NewSkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#CURRENTPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#CURRENTPATH#", $SkinPath & $SplitBigArray[4])
			$SkinPreview = $NewSkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#PROGRAMPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#PROGRAMPATH#", "..\..\")
			$SkinPreview = $NewSkinPreview
		ElseIf StringInStr(StringUpper($SkinPreview), "#ADDONSPATH#") > 0 Then
			$NewSkinPreview = StringReplace($SkinPreview, "#ADDONSPATH#", "..\..\Addons\")
			$SkinPreview = $NewSkinPreview
		Else
			$SkinPreview = $SkinPath & $SplitBigArray[4] & $SkinPreview
		EndIf
		_GDIPlus_Startup()
		$hImage = _GDIPlus_ImageLoadFromFile($SkinPreview)
		$w = _GDIPlus_ImageGetWidth($hImage)
		$h = _GDIPlus_ImageGetHeight($hImage)
		_GDIPlus_ImageSaveToFile($hImage, $WorkingDir & "preview.bmp")
		_GDIPlus_ImageDispose($hImage)
		_GDIPlus_Shutdown()

		if $h + 27 > @DesktopHeight Then
			$h = @DesktopHeight - 27
		EndIf
		if $w+ 10 > @DesktopWidth Then
			$w = @DesktopWidth - 10
		EndIf

		$PreviewGUI = GUICreate("Preview - Click to close", $w, $h + 27, -1, -1, BitOR($DS_MODALFRAME, $WS_CLIPSIBLINGS),-1, $MainForm)
		GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

		$PreviewImage = GUICtrlCreatePic($WorkingDir & "preview.bmp", 0, 0, $w, $h, -1, -1)
		GUICtrlSetOnEvent($PreviewImage, "clickedPreviewImage")
		GUISetState(@SW_SHOW,$PreviewGUI)
	EndIf
EndFunc   ;==>clickedPreviewViewLabel

Func clickedPreviewImage()
 	GUIDelete($PreviewGUI)
EndFunc   ;==>clickedPreviewImage

#cs
	===========================================================================================================
	Set upper right panel to logo image - Hide Metadata
	===========================================================================================================
#ce

Func _HideRightScreen($Which)
	$Preview = 0
	Switch $Which
		Case 1
			ControlHide("", "", $LoadLabel)
			ControlHide("", "", $EditLabel)
			ControlHide("", "", $RefreshLabel)
			ControlHide("", "", $DeadRefreshLabel)
			ControlHide("", "", $SkinSettingsLabel)
			ControlHide("", "", $DeadSkinSettingsLabel)
			ControlHide("", "", $BrowseFolderLabel)

		Case 2
			ControlHide("", "", $AuthorNameLabel)
			ControlHide("", "", $AuthorLabel)
			ControlHide("", "", $SuiteNameLabel)
			ControlHide("", "", $SkinNameLabel)
			ControlHide("", "", $SkinDescTextLabel)
			ControlHide("", "", $SkinDescValueLabel)
			ControlHide("", "", $SkinInstrLabel)
			ControlHide("", "", $SkinInstrEdit)
			ControlHide("", "", $SkinTagsLabel)
			ControlHide("", "", $SkinTagsEdit)
			ControlHide("", "", $VersionLabel)
			ControlHide("", "", $VersionNameLabel)
			ControlHide("", "", $LicenseLabel)
			ControlHide("", "", $LicenseNameLabel)
			ControlHide("", "", $PreviewLabel)
			ControlHide("", "", $PreviewNameLabel)
			ControlHide("", "", $PreviewBrowseLabel)
			ControlHide("", "", $PreviewViewLabel)

		Case 3
			ControlHide("", "", $LoadLabel)
			ControlHide("", "", $EditLabel)
			ControlHide("", "", $RefreshLabel)
			ControlHide("", "", $DeadRefreshLabel)
			ControlHide("", "", $SkinSettingsLabel)
			ControlHide("", "", $DeadSkinSettingsLabel)
			ControlHide("", "", $BrowseFolderLabel)
			ControlHide("", "", $AuthorNameLabel)
			ControlHide("", "", $AuthorLabel)
			ControlHide("", "", $SuiteNameLabel)
			ControlHide("", "", $SkinNameLabel)
			ControlHide("", "", $SkinDescTextLabel)
			ControlHide("", "", $SkinDescValueLabel)
			ControlHide("", "", $SkinInstrLabel)
			ControlHide("", "", $SkinInstrEdit)
			ControlHide("", "", $SkinTagsLabel)
			ControlHide("", "", $SkinTagsEdit)
			ControlHide("", "", $VersionLabel)
			ControlHide("", "", $VersionNameLabel)
			ControlHide("", "", $LicenseLabel)
			ControlHide("", "", $LicenseNameLabel)
			ControlHide("", "", $PreviewLabel)
			ControlHide("", "", $PreviewNameLabel)
			ControlHide("", "", $PreviewBrowseLabel)
			ControlHide("", "", $PreviewViewLabel)

	EndSwitch

EndFunc   ;==>_HideRightScreen

#cs
	===========================================================================================================
	Retrieve all configs and build treeveiw: $TreeSkins
	===========================================================================================================
#ce

Func _GetSkins()

	_GUICtrlTreeView_Destroy($TreeSkins)
	$TreeSkins = _GUICtrlTreeView_Create($MainForm, 15, 120, 180, 380, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT, $TVS_SHOWSELALWAYS), $WS_EX_CLIENTEDGE)
	If $CustomColors = 1 Then _GUICtrlTreeView_SetBkColor($TreeSkins, $TreeBackgroundColor)
	_WinAPI_SetFont($TreeSkins, $TreeFont)
	_GUICtrlTreeView_BeginUpdate($TreeSkins)

	$TempCount = 0
	$NewSkinArray = 0
	$SkinArray = 0
	$TempArray = 0
	$BigArray = 0
	$FileArray = 0

	Global $BigArray[1]
	Global $NewSkinArray[1]

	$SkinArray = _FileListToArrayXT($SkinPath, "*", 2, 1, True, "", 1)

	;Replace spaces in folder names with ChrW(65535) so idiotic _ArraySort works right
	For $a = 1 To $SkinArray[0]
		$SkinArray[$a] = StringReplace($SkinArray[$a], " ", ChrW(65535), 0)
	Next
	_ArraySort($SkinArray, 0, 1, 0)
	;Put spaces back
	For $a = 1 To $SkinArray[0]
		$SkinArray[$a] = StringReplace($SkinArray[$a], ChrW(65535), " ", 0)
	Next

	For $a = 1 To $SkinArray[0]
		$TempArray = _FileListToArrayXT($SkinPath & $SkinArray[$a], "*.ini", 1, 1, True, "Desktop.ini", 1)
		_ArraySort($TempArray, 0, 1)
		If IsArray($TempArray) Then
			For $b = 1 To $TempArray[0]
				$MetaCheck = IniReadSection($SkinPath & $SkinArray[$a] & "\" & $TempArray[$b], "Metadata")
				If Not IsArray($MetaCheck) Then
					$SectionsInIni = IniReadSectionNames($SkinPath & $SkinArray[$a] & "\" & $TempArray[$b])
					If IsArray($SectionsInIni) Then
						_FileReadToArray($SkinPath & $SkinArray[$a] & "\" & $TempArray[$b], $FileArray)
						If StringUpper($SectionsInIni[1]) = "RAINMETER" And $SectionsInIni[0] > 1 Then
							$iStart = _ArraySearch($FileArray, "[" & $SectionsInIni[2] & "]", 1, 0, 0, 0)
							$StartOfAddedMetadata = $iStart
						Else
							$iStart = _ArraySearch($FileArray, "[" & $SectionsInIni[1] & "]", 1, 0, 0, 0) - 1
							$StartOfAddedMetadata = $iStart
						EndIf

						If $StartOfAddedMetadata < 1 Then $StartOfAddedMetadata = 1

						_ArrayInsert($FileArray, $StartOfAddedMetadata, ";Metadata added by RainBrowser")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 1, ";http://rainmeter.net/RainCMS/?q=Rainmeter101_AnatomyOfASkin")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 2, "")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 3, "[Metadata]")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 4, "Name=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 5, "Config=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 6, "Description=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 7, "Instructions=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 8, "Version=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 9, "Tags=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 10, "License=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 11, "Variant=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 12, "Preview=")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 13, "")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 14, ";End of added Metadata")
						_ArrayInsert($FileArray, $StartOfAddedMetadata + 15, "")

						$FileArray[0] = $FileArray[0] + 15
						_FileWriteFromArray($SkinPath & $SkinArray[$a] & "\" & $TempArray[$b], $FileArray, 1)

					EndIf
				EndIf
			Next
			$TempCount = $TempCount + 1
			ReDim $NewSkinArray[$TempCount + 1]
			$NewSkinArray[$TempCount] = $SkinArray[$a] & "\"
			$NewSkinArray[0] = $TempCount
		EndIf
	Next

	For $a = 1 To $NewSkinArray[0]

		ReDim $BigArray[$a + 1]

		$SplitPath = StringSplit(StringLeft($NewSkinArray[$a], StringLen($NewSkinArray[$a]) - 1), "\")
		$SplitParentLoc = StringInStr($NewSkinArray[$a], "\", 0, -2)
		If $SplitParentLoc > 0 Then
			$SplitParent = StringLeft($NewSkinArray[$a], $SplitParentLoc)
			$SplitParentNode = _ArraySearch($NewSkinArray, $SplitParent, 0, $a - 1, 0, 0)
		Else
			$SplitParent = $NewSkinArray[$a]
			$SplitParentNode = $a
		EndIf
		$BigArray[$a] = $SplitPath[$SplitPath[0]] & "|" & $SplitParentNode & "|" & $SplitParent & "|" & $NewSkinArray[$a] & "|" & "0" & "|" & "0"
		$BigArray[0] = $a

	Next

	For $a = 1 To $BigArray[0]
		$SplitBig1 = StringSplit($BigArray[$a], "|")
		If $SplitBig1[2] = $a Then ;Is a root level folder
			$tvbNode = _GUICtrlTreeView_Add($TreeSkins, 0, $SplitBig1[1])
			$tvbParent = $tvbNode
			$BigArray[$a] = $SplitBig1[1] & "|" & $SplitBig1[2] & "|" & $SplitBig1[3] & "|" & $SplitBig1[4] & "|" & $tvbNode & "|" & $tvbParent
		Else
			$SplitBig2 = StringSplit($BigArray[$SplitBig1[2]], "|") ;Is a subfolder
			$tvbParent = $SplitBig2[5]
			$tvbNode = _GUICtrlTreeView_AddChild($TreeSkins, $tvbParent, $SplitBig1[1])
			$BigArray[$a] = $SplitBig1[1] & "|" & $SplitBig1[2] & "|" & $SplitBig1[3] & "|" & $SplitBig1[4] & "|" & $tvbNode & "|" & $tvbParent
		EndIf
	Next

	_GUICtrlTreeView_EndUpdate($TreeSkins)

	If $Running = 0 Then ControlShow("", "", $TreeSkins)

EndFunc   ;==>_GetSkins

#cs
	===========================================================================================================
	Retrieve all active configs and build treeveiw: $RunningSkins
	===========================================================================================================
#ce

Func _GetActive()

	_GUICtrlTreeView_Destroy($RunningSkins)
	$RunningSkins = _GUICtrlTreeView_Create($MainForm, 15, 120, 180, 380, $TVS_SHOWSELALWAYS, $WS_EX_CLIENTEDGE)
	If $CustomColors = 1 Then _GUICtrlTreeView_SetBkColor($RunningSkins, $TreeBackgroundColor)
	_WinAPI_SetFont($RunningSkins, $TreeFont)
	_GUICtrlTreeView_BeginUpdate($RunningSkins)

	For $a = 1 To $NewSkinArray[0]

		$ConfigNoSlash = StringLeft($NewSkinArray[$a], StringLen($NewSkinArray[$a]) - 1)
		$IsActiveConfig = IniRead($DataFolder & "Rainmeter.ini", $ConfigNoSlash, "Active", "0")
		If $IsActiveConfig <> "0" Then
			$idActive = _GUICtrlTreeView_Add($RunningSkins, 0, $ConfigNoSlash)
		EndIf
	Next

	_GUICtrlTreeView_EndUpdate($RunningSkins)

EndFunc   ;==>_GetActive

#cs
	===========================================================================================================
	Retrieve all tags and build treeveiw: $TagSkins
	MetaData(SkinNum,Config,ConfigPath,IniFileName,Name,Desc,Tags,Author,Version,License,Variant,Preview)
	===========================================================================================================
#ce

Func _GetTags()

	Dim $SQLTagArray[9999]
	Dim $SQLConfigPathArray[1]
	$q1Count = 1

	_GUICtrlTreeView_Destroy($TagSkins)

	$TagSkins = _GUICtrlTreeView_Create($MainForm, 15, 120, 180, 380, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT, $TVS_SHOWSELALWAYS, $TVS_NOTOOLTIPS), $WS_EX_CLIENTEDGE)
	If $CustomColors = 1 Then _GUICtrlTreeView_SetBkColor($TagSkins, $TreeBackgroundColor)
	_WinAPI_SetFont($TagSkins, $TreeFont)
	_GUICtrlTreeView_BeginUpdate($TagSkins)

	_ManageDatabase(2)
	_ManageDatabase(1)
	_PopulateDatabase()

	_SQLite_QueryReset($hQuery)
	_SQLite_Query(-1, "SELECT distinct Tags COLLATE NOCASE from Metadata where LENGTH(Tags) > 1 order by Tags;", $hQuery)

	While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
		$SQLTagArray[$q1Count] = $aRow[0]
		$SQLTagArray[0] = $q1Count
		$q1Count = $q1Count + 1
	WEnd
	ReDim $SQLTagArray[$q1Count]

	For $a = 1 To $SQLTagArray[0]
		$TagParent = _GUICtrlTreeView_Add($TagSkins, 0, $SQLTagArray[$a])
		$SQLTagArray[$a] = StringReplace($SQLTagArray[$a], "'", "''")
		_SQLite_QueryReset($hQuery)
		_SQLite_Query(-1, "SELECT Distinct ConfigPath from Metadata where UPPER(Tags) = UPPER('" & $SQLTagArray[$a] & "') order by UPPER(ConfigPath);", $hQuery)

		While _SQLite_FetchData($hQuery, $aRow) = $SQLITE_OK
			$aRow[0] = StringReplace($aRow[0], "''", "'")
			$TagChild = _GUICtrlTreeView_AddChild($TagSkins, $TagParent, $aRow[0])
		WEnd

	Next

	_GUICtrlTreeView_EndUpdate($TagSkins)

EndFunc   ;==>_GetTags

#cs
	===========================================================================================================
	Skin setttings: Transparency/Position/Draggable etc.
	===========================================================================================================
#ce

Func clickedSkinSettings()
	If $Editing Then Return
	$EditingSkinSettings = 1
	_HideRightScreen(2)
	GUISetState(@SW_SHOWNORMAL, $MainForm)
	GUICtrlSetState($SkinList, $GUI_DISABLE)
	GUICtrlSetState($LabelTags, $GUI_DISABLE)
	GUICtrlSetState($SkinList, $GUI_DISABLE)
	GUICtrlSetState($LoadLabel, $GUI_DISABLE)
	GUICtrlSetState($RefreshLabel, $GUI_DISABLE)
	GUICtrlSetState($SkinSettingsLabel, $GUI_DISABLE)
	GUICtrlSetState($BrowseFolderLabel, $GUI_DISABLE)
	GUICtrlSetState($EditLabel, $GUI_DISABLE)
	GUICtrlSetState($RefreshGlobalLabel, $GUI_DISABLE)
	GUICtrlSetState($RestartGlobalLabel, $GUI_DISABLE)
	GUICtrlSetState($BrowseGlobalLabel, $GUI_DISABLE)
	GUICtrlSetState($EditGlobalSettings, $GUI_DISABLE)

	If $Running = 1 Then
		$iConfigNameLabel = GUICtrlCreateLabel("Skin Settings for: " & _GUICtrlTreeView_GetText($RunningSkins, _GUICtrlTreeView_GetSelection($RunningSkins)), 230, 68, 400, 25)
	Else
		$iConfigNameLabel = GUICtrlCreateLabel("Skin Settings for: " & _GUICtrlTreeView_GetText($TreeSkins, _GUICtrlTreeView_GetSelection($TreeSkins)), 230, 68, 400, 25)
	EndIf
	GUICtrlSetFont($iConfigNameLabel, 12, 400, 0, "Segoe UI")

	$SettingsSaveLabel = GUICtrlCreateLabel("Apply", 665, 470, 50, 29)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SettingsSaveLabel, "clickedSettingsSave")

	$SettingsCancelLabel = GUICtrlCreateLabel("Return", 710, 470, 50, 29)
	GUICtrlSetFont(-1, 10, 400, 4, "Segoe UI")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetOnEvent($SettingsCancelLabel, "clickedSettingsCancel")

	#cs
		===========================================================================================================
		"AlwaysOnTop="
		===========================================================================================================
	#ce

	$iAlwaysOnTop = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AlwaysOnTop", "0")
	$iPositionLabel = GUICtrlCreateLabel("Front / Back Position", 260, 100, 150, 20)
	GUICtrlSetFont($iPositionLabel, 11, 400, 0, "Segoe UI")

	$StayTopMostRadio = GUICtrlCreateRadio("StayTopMost", 260, 125, 100, 20)
	GUICtrlSetFont($StayTopMostRadio, 10, 400, 0, "Segoe UI")
	$TopMostRadio = GUICtrlCreateRadio("TopMost", 260, 145, 100, 20)
	GUICtrlSetFont($TopMostRadio, 10, 400, 0, "Segoe UI")
	$NormalRadio = GUICtrlCreateRadio("Normal", 260, 165, 100, 20)
	GUICtrlSetFont($NormalRadio, 10, 400, 0, "Segoe UI")
	$BottomRadio = GUICtrlCreateRadio("Bottom", 260, 185, 100, 20)
	GUICtrlSetFont($BottomRadio, 10, 400, 0, "Segoe UI")
	$DesktopRadio = GUICtrlCreateRadio("On Desktop", 260, 205, 100, 20)
	GUICtrlSetFont($DesktopRadio, 10, 400, 0, "Segoe UI")

	Switch $iAlwaysOnTop
		Case "1"
			GUICtrlSetState($StayTopMostRadio, $GUI_CHECKED)
		Case "2"
			GUICtrlSetState($TopMostRadio, $GUI_CHECKED)
		Case "0"
			GUICtrlSetState($NormalRadio, $GUI_CHECKED)
		Case "-1"
			GUICtrlSetState($BottomRadio, $GUI_CHECKED)
		Case "-2"
			GUICtrlSetState($DesktopRadio, $GUI_CHECKED)
	EndSwitch

	#cs
		===========================================================================================================
		"LoadOrder="
		===========================================================================================================
	#ce

	$iLoadOrder = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "LoadOrder", "0")
	$OldiLoadOrder = $iLoadOrder
	$iLoadOrderLabel = GUICtrlCreateLabel("Load Order", 415, 178, 70, 20)
	GUICtrlSetFont($iLoadOrderLabel, 11, 400, 0, "Segoe UI")
	GUICtrlSetCursor($iLoadOrderLabel, 0)
	GUICtrlSetTip($iLoadOrderLabel, "Get HELP for Load Order", "")
	GUICtrlSetOnEvent($iLoadOrderLabel, "clickedLoadOrderHelp")
	$iLoadOrderEdit = GUICtrlCreateEdit($iLoadOrder, 415, 198, 70, 25, $ES_AUTOHSCROLL)
	GUICtrlSetBkColor($iLoadOrderEdit, 0xFFFFFF)
	GUICtrlSetFont($iLoadOrderEdit, 10, 400, 0, "Segoe UI")
	Send("{END}")

	#cs
		===========================================================================================================
		"WindowX="  "WindowY="  "AnchorX="  "AnchorY="
		===========================================================================================================
	#ce

	$iWindowX = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "WindowX", "0")
	$iWindowY = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "WindowY", "0")
	$OldiWindowX = $iWindowX
	$OldiWindowY = $iWindowY
	$iWindowXLabel = GUICtrlCreateLabel("WindowX", 260, 235, 74, 20)
	GUICtrlSetFont($iWindowXLabel, 11, 400, 0, "Segoe UI")
	GUICtrlSetCursor($iWindowXLabel, 0)
	GUICtrlSetTip($iWindowXLabel, "Get HELP for WindowX", "")
	GUICtrlSetOnEvent($iWindowXLabel, "clickedWindowXHelp")
	$iWindowXEdit = GUICtrlCreateEdit($iWindowX, 260, 255, 225, 25, $ES_AUTOHSCROLL)
	GUICtrlSetBkColor($iWindowXEdit, 0xFFFFFF)
	GUICtrlSetFont($iWindowXEdit, 10, 400, 0, "Segoe UI")
	Send("{END}")

	$iWindowYLabel = GUICtrlCreateLabel("WindowY", 260, 280, 74, 20)
	GUICtrlSetFont($iWindowYLabel, 11, 400, 0, "Segoe UI")
	GUICtrlSetCursor($iWindowYLabel, 0)
	GUICtrlSetTip($iWindowYLabel, "Get HELP for WindowY", "")
	GUICtrlSetOnEvent($iWindowYLabel, "clickedWindowYHelp")
	$iWindowYEdit = GUICtrlCreateEdit($iWindowY, 260, 300, 225, 25, $ES_AUTOHSCROLL)
	GUICtrlSetBkColor($iWindowYEdit, 0xFFFFFF)
	GUICtrlSetFont($iWindowYEdit, 10, 400, 0, "Segoe UI")
	Send("{END}")

	$iAnchorX = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorX", "")
	$iAnchorY = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorY", "")
	$iAnchorXLabel = GUICtrlCreateLabel("AnchorX", 260, 325, 74, 20)
	GUICtrlSetFont($iAnchorXLabel, 11, 400, 0, "Segoe UI")
	GUICtrlSetCursor($iAnchorXLabel, 0)
	GUICtrlSetTip($iAnchorXLabel, "Get HELP for AnchorX", "")
	GUICtrlSetOnEvent($iAnchorXLabel, "clickedAnchorHelp")
	$iAnchorXEdit = GUICtrlCreateEdit($iAnchorX, 260, 345, 225, 25, $ES_AUTOHSCROLL)
	GUICtrlSetBkColor($iAnchorXEdit, 0xFFFFFF)
	GUICtrlSetFont($iAnchorXEdit, 10, 400, 0, "Segoe UI")
	Send("{END}")

	$iAnchorYLabel = GUICtrlCreateLabel("AnchorY", 260, 370, 74, 20)
	GUICtrlSetFont($iAnchorYLabel, 11, 400, 0, "Segoe UI")
	GUICtrlSetCursor($iAnchorYLabel, 0)
	GUICtrlSetTip($iAnchorYLabel, "Get HELP for AnchorY", "")
	GUICtrlSetOnEvent($iAnchorYLabel, "clickedAnchorHelp")
	$iAnchorYEdit = GUICtrlCreateEdit($iAnchorY, 260, 390, 225, 25, $ES_AUTOHSCROLL)
	GUICtrlSetBkColor($iAnchorYEdit, 0xFFFFFF)
	GUICtrlSetFont($iAnchorYEdit, 10, 400, 0, "Segoe UI")
	Send("{END}")

	#cs
		===========================================================================================================
		Transparency
		===========================================================================================================
	#ce

	$iAlphaValue = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AlphaValue", "255")
	$iAlphaValueLabel = GUICtrlCreateLabel("Percent Transparent", 550, 100, 200, 20)
	GUICtrlSetFont($iAlphaValueLabel, 11, 400, 0, "Segoe UI")
	$iAlphaValueSlider = GUICtrlCreateSlider(547, 127, 200, 20, BitOR($TBS_BOTTOM, $TBS_TOOLTIPS), Default)
	If $CustomColors = 1 Then GUICtrlSetBkColor($iAlphaValueSlider, $MainBackgroundColor)
	GUICtrlSetLimit($iAlphaValueSlider, 100, 0)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 10)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 20)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 30)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 40)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 50)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 60)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 70)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 80)
	_GUICtrlSlider_SetTic($iAlphaValueSlider, 90)
	$iAlphaValueTicsLabel = GUICtrlCreateLabel("0   10   20   30   40   50   60  70   80  90   100", 553, 145, 210, 20)
	GUICtrlSetFont($iAlphaValueTicsLabel, 8, 400, 0, "Segoe UI")
	$iAlphaPercentage = 100 - Int(($iAlphaValue / 255) * 100)
	GUICtrlSetData($iAlphaValueSlider, $iAlphaPercentage)

	#cs
		===========================================================================================================
		Hide / FadeIn / FadeOut / Fade Duration
		===========================================================================================================
	#ce

	$iHideFadeLabel = GUICtrlCreateLabel("Hide / Fade Setings", 550, 265, 220, 20)
	GUICtrlSetFont($iHideFadeLabel, 11, 400, 0, "Segoe UI")
	;GUICtrlSetColor($iHideFadeLabel, $LightText)
	$iHideOnMouseOver = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "HideOnMouseOver", "0")
	$iFadeDuration = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "FadeDuration", "250")
	GUIStartGroup()
	$iHideOnMouseOverRadio = GUICtrlCreateRadio("HIDE on Mouse Over", 550, 290, 170, 20)
	GUICtrlSetFont($iHideOnMouseOverRadio, 10, 400, 0, "Segoe UI")
	$iFadeInRadio = GUICtrlCreateRadio("Fade IN on Mouse Over", 550, 310, 170, 20)
	GUICtrlSetFont($iFadeInRadio, 10, 400, 0, "Segoe UI")
	$iFadeOutRadio = GUICtrlCreateRadio("Fade OUT on Mouse Over", 550, 330, 170, 20)
	GUICtrlSetFont($iFadeOutRadio, 10, 400, 0, "Segoe UI")
	$iNoFadeHideRadio = GUICtrlCreateRadio("NO Fade / Hide Effect", 550, 355, 170, 20)
	GUICtrlSetFont($iNoFadeHideRadio, 10, 400, 0, "Segoe UI")

	Switch $iHideOnMouseOver
		Case "0"
			GUICtrlSetState($iNoFadeHideRadio, $GUI_CHECKED)
		Case "1"
			GUICtrlSetState($iHideOnMouseOverRadio, $GUI_CHECKED)
		Case "2"
			GUICtrlSetState($iFadeInRadio, $GUI_CHECKED)
		Case "3"
			GUICtrlSetState($iFadeOutRadio, $GUI_CHECKED)
	EndSwitch

	$iFadeDurationLabel = GUICtrlCreateLabel("Fade Duration (Fast to Slow)", 550, 180, 200, 20)
	GUICtrlSetFont($iFadeDurationLabel, 11, 400, 0, "Segoe UI")
	$iFadeDurationSlider = GUICtrlCreateSlider(547, 208, 200, 20, BitOR($TBS_BOTTOM, $TBS_TOOLTIPS), Default)
	If $CustomColors = 1 Then GUICtrlSetBkColor($iFadeDurationSlider, $MainBackgroundColor)
	GUICtrlSetLimit($iFadeDurationSlider, 255, 0)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 25)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 50)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 75)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 100)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 125)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 150)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 175)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 200)
	_GUICtrlSlider_SetTic($iFadeDurationSlider, 225)
	$iFadeDurationTicsLabel = GUICtrlCreateLabel("0    25  50   75  100 125 150 175 200 225 255", 553, 228, 210, 20)
	GUICtrlSetFont($iFadeDurationTicsLabel, 8, 400, 0, "Segoe UI")
	GUICtrlSetData($iFadeDurationSlider, $iFadeDuration)

	#cs
		===========================================================================================================
		Save Position / Snap to Edges / Keep on Screen / Draggable / Click Through
		===========================================================================================================
	#ce
	$iSavePosition = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "SavePosition", "1")
	$iSnapEdges = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "SnapEdges", "1")
	$iKeepOnScreen = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "KeepOnScreen", "0")
	$iDraggable = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "Draggable", "1")
	$iClickThrough = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "ClickThrough", "0")

	$iSavePositionCheck = GUICtrlCreateCheckbox(" Save Position", 390, 430, 115, 20)
	GUICtrlSetFont($iSavePositionCheck, 10, 400, 0, "Segoe UI")
	If $iSavePosition = 1 Then GUICtrlSetState($iSavePositionCheck, $GUI_CHECKED)

	$iSnapEdgesCheck = GUICtrlCreateCheckbox(" Snap to Edges", 390, 450, 115, 20)
	GUICtrlSetFont($iSnapEdgesCheck, 10, 400, 0, "Segoe UI")
	If $iSnapEdges = 1 Then GUICtrlSetState($iSnapEdgesCheck, $GUI_CHECKED)

	$iKeepOnScreenCheck = GUICtrlCreateCheckbox(" Keep on Screen", 260, 470, 115, 20)
	GUICtrlSetFont($iKeepOnScreenCheck, 10, 400, 0, "Segoe UI")
	If $iKeepOnScreen = 1 Then GUICtrlSetState($iKeepOnScreenCheck, $GUI_CHECKED)

	$iDraggableCheck = GUICtrlCreateCheckbox(" Draggable", 260, 430, 115, 20)
	GUICtrlSetFont($iDraggableCheck, 10, 400, 0, "Segoe UI")
	If $iDraggable = 1 Then GUICtrlSetState($iDraggableCheck, $GUI_CHECKED)

	$iClickThroughCheck = GUICtrlCreateCheckbox(" Click Through", 260, 450, 115, 20)
	GUICtrlSetFont($iClickThroughCheck, 10, 400, 0, "Segoe UI")
	If $iClickThrough = 1 Then GUICtrlSetState($iClickThroughCheck, $GUI_CHECKED)

	GUICtrlSetState($iConfigNameLabel, $GUI_FOCUS)

EndFunc   ;==>clickedSkinSettings


#cs
	===========================================================================================================
	Help for Load Order
	===========================================================================================================
#ce

Func clickedLoadOrderHelp()
	MsgBox(64, "Help for Load Order", "LoadOrder" & @CRLF & @CRLF & "This determines the order in which the configs are loaded.  Values can be positive or negative.  Configs will load starting with the one with the lowest value for LoadOrder, ending with the highest.  Configs loaded first are below those loaded last, for example: Three configs having 'LoadOrder=-1', 'LoadOrder=2' and 'LoadOrder=5' would load the configs in that order, with the config with 'LoadOrder=-1' appearing beneath the one with 'LoadOrder=2' which is in turn beneath the config containing 'LoadOrder=5'.  If two configs have the same value for 'LoadOrder', they are then loaded in alphabetical order.  'LoadOrder' must be set manually in 'Rainmeter.ini' by selecting 'Edit Settings...' from the context menu, or by using the 'Skin Settings' button in the RainBrowser addon." & @CRLF & @CRLF & "NOTE: The value of 'LoadOrder' has no bearing on what the position of the config is, ie: 'On Desktop', 'Normal, 'Topmost', etc.  Configs in these positions will continue to appear in the same manner, with 'LoadOrder' only affecting how skins in the same position interact with each other.  That is to say, configs set to 'Topmost' will always appear above configs set to 'Normal', but two configs in 'Topmost' will layer themselves according to their 'LoadOrder' value.")
EndFunc   ;==>clickedLoadOrderHelp

#cs
	===========================================================================================================
	Help for WindowX, WindowY, AnchorX, AnchorY
	===========================================================================================================
#ce

Func clickedWindowXHelp()
	MsgBox(64, "Help for WindowX", "WindowX" & @CRLF & @CRLF & "X-position of the meter window in pixels or percentage if % is used." & @CRLF & @CRLF & "If an R is added then the position is relative to the right edge of the screen instead of the left." & @CRLF & @CRLF & "By default the position is relative to the primary screen. You can override this with @n where n is 0 to 32 and denotes which screen to position the meter on (1-32) or the virtual desktop (0). The screen selection applies to both WindowX and WindowY unless changed in WindowY." & @CRLF & @CRLF & "WindowY has no effect on WindowX.")
EndFunc   ;==>clickedWindowXHelp

Func clickedWindowYHelp()
	MsgBox(64, "Help for WindowY", "WindowY" & @CRLF & @CRLF & "Y-position of the meter window in pixels or percentage if % is used." & @CRLF & @CRLF & "If a B is added then the position is relative to the bottom edge of the screen instead of the top." & @CRLF & @CRLF & "By default the position is relative to the primary screen. You can override this with @n where n is 0 to 32 and denotes which screen to position the meter on (1-32) or the virtual desktop (0). The screen selection applies to both WindowX and WindowY unless changed in WindowY." & @CRLF & @CRLF & "WindowY has no effect on WindowX.")
EndFunc   ;==>clickedWindowYHelp

Func clickedAnchorHelp()
	MsgBox(64, "AnchorX and AnchorY", "AnchorX and AnchorY" & @CRLF & @CRLF & "By default WindowX & WindowY control the position of the upper left corner of the meter window. AnchorX and AnchorY allow that anchor position to be changed." & @CRLF & @CRLF & "The Anchor can be defined in pixels from the upper left corner of the window or as a percentage of the meter window if % is used." & @CRLF & @CRLF & "If a R or B respectively is added then the possition is relative to the right or bottom edge of the window." & @CRLF & @CRLF & "As an example, by setting WindowX, WindowY, AnchorX and AnchorY all to 50% the meter window will be truly centered in the primary monitor regardless of screen resolution or aspect ratio.")
EndFunc   ;==>clickedAnchorHelp

#cs
	===========================================================================================================
	Clicked "Cancel" on Skin Settings
	===========================================================================================================
#ce

Func clickedSettingsCancel()
	GUICtrlDelete($iConfigNameLabel)
	GUICtrlDelete($SettingsSaveLabel)
	GUICtrlDelete($SettingsDividerLabel)
	GUICtrlDelete($SettingsCancelLabel)
	GUICtrlDelete($iPositionLabel)
	GUICtrlDelete($PositionGroup)
	GUICtrlDelete($PositionGroup)
	GUICtrlDelete($StayTopMostRadio)
	GUICtrlDelete($TopMostRadio)
	GUICtrlDelete($NormalRadio)
	GUICtrlDelete($BottomRadio)
	GUICtrlDelete($DesktopRadio)
	GUICtrlDelete($iLoadOrderLabel)
	GUICtrlDelete($iLoadOrderEdit)
	GUICtrlDelete($iWindowXLabel)
	GUICtrlDelete($iWindowXEdit)
	GUICtrlDelete($iWindowYLabel)
	GUICtrlDelete($iWindowYEdit)
	GUICtrlDelete($iAnchorXLabel)
	GUICtrlDelete($iAnchorXEdit)
	GUICtrlDelete($iAnchorYLabel)
	GUICtrlDelete($iAnchorYEdit)
	GUICtrlDelete($iAlphaValueLabel)
	GUICtrlDelete($iAlphaValueSlider)
	GUICtrlDelete($iAlphaValueTicsLabel)
	GUICtrlDelete($iHideFadeLabel)
	GUICtrlDelete($iHideOnMouseOverRadio)
	GUICtrlDelete($iFadeInRadio)
	GUICtrlDelete($iFadeOutRadio)
	GUICtrlDelete($iNoFadeHideRadio)
	GUICtrlDelete($iFadeDurationLabel)
	GUICtrlDelete($iFadeDurationSlider)
	GUICtrlDelete($iFadeDurationTicsLabel)
	GUICtrlDelete($iSavePositionCheck)
	GUICtrlDelete($iSnapEdgesCheck)
	GUICtrlDelete($iKeepOnScreenCheck)
	GUICtrlDelete($iDraggableCheck)
	GUICtrlDelete($iClickThroughCheck)


	GUICtrlSetState($SkinList, $GUI_ENABLE)
	GUICtrlSetState($LabelTags, $GUI_ENABLE)
	GUICtrlSetState($SkinList, $GUI_ENABLE)
	GUICtrlSetState($LoadLabel, $GUI_ENABLE)
	GUICtrlSetState($RefreshLabel, $GUI_ENABLE)
	GUICtrlSetState($SkinSettingsLabel, $GUI_ENABLE)
	GUICtrlSetState($BrowseFolderLabel, $GUI_ENABLE)
	GUICtrlSetState($EditLabel, $GUI_ENABLE)
	GUICtrlSetState($RefreshGlobalLabel, $GUI_ENABLE)
	GUICtrlSetState($RestartGlobalLabel, $GUI_ENABLE)
	GUICtrlSetState($BrowseGlobalLabel, $GUI_ENABLE)
	GUICtrlSetState($EditGlobalSettings, $GUI_ENABLE)
	$EditingSkinSettings = 0
	clickedSkinList()
EndFunc   ;==>clickedSettingsCancel

#cs
	===========================================================================================================
	Clicked "Apply" on Skin Settings
	===========================================================================================================
#ce

Func clickedSettingsSave()
	GUICtrlSetState($SettingsSaveLabel, $GUI_DISABLE)
	If GUICtrlRead($StayTopMostRadio) = 1 Then $nAlwaysOnTop = "1"
	If GUICtrlRead($TopMostRadio) = 1 Then $nAlwaysOnTop = "2"
	If GUICtrlRead($NormalRadio) = 1 Then $nAlwaysOnTop = "0"
	If GUICtrlRead($BottomRadio) = 1 Then $nAlwaysOnTop = "-1"
	If GUICtrlRead($DesktopRadio) = 1 Then $nAlwaysOnTop = "-2"
	IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AlwaysOnTop", $nAlwaysOnTop)

	$nLoadOrder = GUICtrlRead($iLoadOrderEdit)
	If $nLoadOrder = "" Then $nLoadOrder = "0"
	If $OldiLoadOrder <> $nLoadOrder Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "LoadOrder", $nLoadOrder)
	EndIf

	$nWindowX = GUICtrlRead($iWindowXEdit)
	If $nWindowX = "" Then $nWindowX = "0"
	If $OldiWindowX <> $nWindowX Then IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "WindowX", $nWindowX)
	$nWindowY = GUICtrlRead($iWindowYEdit)
	If $nWindowY = "" Then $nWindowY = "0"
	If $OldiWindowY <> $nWindowY Then IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "WindowY", $nWindowY)

	$nAnchorX = GUICtrlRead($iAnchorXEdit)
	If $nAnchorX <> "" Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorX", $nAnchorX)
	Else
		IniDelete($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorX")
	EndIf
	$nAnchorY = GUICtrlRead($iAnchorYEdit)
	If $nAnchorY <> "" Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorY", $nAnchorY)
	Else
		IniDelete($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorY")
	EndIf

	$nAlphaPercentage = GUICtrlRead($iAlphaValueSlider)
	$nAlphaValue = Int(255 - (255 * ($nAlphaPercentage / 100)))
	IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AlphaValue", $nAlphaValue)
	If GUICtrlRead($iNoFadeHideRadio) = 1 Then $nHideOnMouseOver = "0"
	If GUICtrlRead($iHideOnMouseOverRadio) = 1 Then $nHideOnMouseOver = "1"
	If GUICtrlRead($iFadeInRadio) = 1 Then $nHideOnMouseOver = "2"
	If GUICtrlRead($iFadeOutRadio) = 1 Then $nHideOnMouseOver = "3"
	IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "HideOnMouseOver", $nHideOnMouseOver)
	$nFadeDuration = GUICtrlRead($iFadeDurationSlider)
	IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "FadeDuration", $nFadeDuration)
	$nSavePosition = GUICtrlRead($iSavePositionCheck)
	If $nSavePosition = 1 Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "SavePosition", "1")
	Else
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "SavePosition", "0")
	EndIf
	$nSnapEdges = GUICtrlRead($iSnapEdgesCheck)
	If $nSnapEdges = 1 Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "SnapEdges", "1")
	Else
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "SnapEdges", "0")
	EndIf
	$nKeepOnScreen = GUICtrlRead($iKeepOnScreenCheck)
	If $nKeepOnScreen = 1 Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "KeepOnScreen", "1")
	Else
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "KeepOnScreen", "0")
	EndIf
	$nDraggable = GUICtrlRead($iDraggableCheck)
	If $nDraggable = 1 Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "Draggable", "1")
	Else
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "Draggable", "0")
	EndIf
	$nClickThrough = GUICtrlRead($iClickThroughCheck)
	If $nClickThrough = 1 Then
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "ClickThrough", "1")
	Else
		IniWrite($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "ClickThrough", "0")
	EndIf

	clickedRefresh()
	If $OldiLoadOrder <> $nLoadOrder Then
		clickedRefreshAll()
	EndIf
	Sleep(200)

	$iWindowX = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "WindowX", "0")
	$iWindowY = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "WindowY", "0")
	$iAnchorX = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorX", "")
	$iAnchorY = IniRead($DataFolder & "Rainmeter.ini", StringLeft($SplitBigArray[4], StringLen($SplitBigArray[4]) - 1), "AnchorY", "")
	GUICtrlSetData($iWindowXEdit, $iWindowX)
	GUICtrlSetData($iWindowYEdit, $iWindowY)
	GUICtrlSetData($iAnchorXEdit, $iAnchorX)
	GUICtrlSetData($iAnchorYEdit, $iAnchorY)

	GUICtrlSetState($SettingsSaveLabel, $GUI_ENABLE)

EndFunc   ;==>clickedSettingsSave

#cs
	===========================================================================================================
	Open and close SQLite datasbase for Metadata
	===========================================================================================================
#ce

Func _ManageDatabase($ManageCode)

	If $ManageCode = 1 Then
		_SQLite_Startup()
		_SQLite_Open() ; Create memory database
		_SQLite_Exec(-1, "CREATE TABLE MetaData (SkinNum,Config,ConfigPath,IniFileName,Name,Desc,Tags,Author,Version,License,Variant,Preview);")
	ElseIf $ManageCode = 2 Then
		_SQLite_Exec(-1, "DROP TABLE MetaData;")
		_SQLite_Close()
		_SQLite_Shutdown()
	Else

	EndIf

EndFunc   ;==>_ManageDatabase

#cs
	===========================================================================================================
	Read .ini files and insert data into metadata database
	===========================================================================================================
#ce

Func _PopulateDatabase()

	Global $TempArray

	_SQLite_Exec(-1, "DELETE from MetaData;")

	$TempArray = _FileListToArrayXT($SkinPath, "*.ini", 1, 1, True, "Desktop.ini", 1)
	_ArraySort($TempArray, 0, 1)

	For $a = 1 To $TempArray[0]

		Dim $szDrive, $szDir, $szFName, $szExt
		$TempArray1 = _PathSplit($TempArray[$a], $szDrive, $szDir, $szFName, $szExt)
		$tConfig = StringLeft($TempArray1[2], StringLen($TempArray1[2]) - 1)
		$tPath = $TempArray1[2]
		$tSkinFile = $TempArray1[3] & $TempArray1[4]
		$SectionsInIni = IniReadSectionNames($SkinPath & $TempArray[$a])

		If IsArray($SectionsInIni) Then

			$tName = IniRead($SkinPath & $TempArray[$a], "Metadata", "Name", "")
			$tDescription = IniRead($SkinPath & $TempArray[$a], "Metadata", "Description", "")
			$tVersion = IniRead($SkinPath & $TempArray[$a], "Metadata", "Version", "")
			$tLicense = IniRead($SkinPath & $TempArray[$a], "Metadata", "License", "")
			$tVariant = IniRead($SkinPath & $TempArray[$a], "Metadata", "Variant", "")
			$tPreview = IniRead($SkinPath & $TempArray[$a], "Metadata", "Preview", "")
			$tAuthor = IniRead($SkinPath & $TempArray[$a], "Rainmeter", "Author", "")
			$tTags = IniRead($SkinPath & $TempArray[$a], "Metadata", "Tags", "")

			$tConfig = StringReplace($tConfig, "'", "''")
			$tPath = StringReplace($tPath, "'", "''")
			$tSkinFile = StringReplace($tSkinFile, "'", "''")
			$tName = StringReplace($tName, "'", "''")
			$tDescription = StringReplace($tDescription, "'", "''")
			$tVersion = StringReplace($tVersion, "'", "''")
			$tLicense = StringReplace($tLicense, "'", "''")
			$tVariant = StringReplace($tVariant, "'", "''")
			$tPreview = StringReplace($tPreview, "'", "''")
			$tAuthor = StringReplace($tAuthor, "'", "''")
			$tTags = StringReplace($tTags, "'", "''")

			$tTagsArray = StringSplit($tTags, " | ", 1)
			If IsArray($tTagsArray) Then
				For $b = 1 To $tTagsArray[0]
					_SQLite_Exec(-1, "INSERT INTO MetaData(SkinNum,Config,ConfigPath,IniFileName,Name,Desc,Tags,Author,Version,License,Variant,Preview) VALUES ('" & $a & "','" & $tConfig & "','" & $tPath & "','" & $tSkinFile & "','" & $tName & "','" & $tDescription & "','" & $tTagsArray[$b] & "','" & $tAuthor & "','" & $tVersion & "','" & $tLicense & "','" & $tVariant & "','" & $tPreview & "');")
				Next
			Else
				_SQLite_Exec(-1, "INSERT INTO MetaData(SkinNum,Config,ConfigPath,IniFileName,Name,Desc,Tags,Author,Version,License,Variant,Preview) VALUES ('" & $a & "','" & $tConfig & "','" & $tPath & "','" & $tSkinFile & "','" & $tName & "','" & $tDescription & "','" & $tTags & "','" & $tAuthor & "','" & $tVersion & "','" & $tLicense & "','" & $tVariant & "','" & $tPreview & "');")
			EndIf

		EndIf

	Next

EndFunc   ;==>_PopulateDatabase

#cs
	===========================================================================================================
	End of RainBrowser code
	===========================================================================================================
#ce
