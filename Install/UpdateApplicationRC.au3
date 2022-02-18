#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=n
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include <File.au3>

; ==================================================================
; This is a part of the Rainmeter build process.  It is called by
; UpdateRevision.py to set the version numbers in the Application.rc
; file.
;
; This must reside in \Install and must be run while you are
; in that folder.
;
; It reads \Library\Rainmeter.h to get the Major and Minor
; Version numbers.  It then reads revision-number.h which
; is set earlier in the build by Build.py with the
; current Revision number.
;
; It then changes the Application.rc file with the current
; revision numbers.
;
; Note: This will FAIL if you are doing a "release" version
; and do not change Rainmeter.h, Application.rc and Build.py
; with the new Major and Minor Version numbers in the SVN prior
; to doing the build.
; ==================================================================

$HeaderRainmeterFile = FileOpen("..\Library\Rainmeter.h", 0)

If $HeaderRainmeterFile = -1 Then
	MsgBox("16","UpdateApplicationRC.exe", "Unable to open file:" & @CRLF & @CRLF & "..\Library\Rainmeter.h" & @CRLF & @CRLF & "Cannot retrieve MAJOR/MINOR version numbers")
	Exit
EndIf

While 1
	$MajorMinorVersionLine = FileReadLine($HeaderRainmeterFile)
	If @error = -1 Then ExitLoop
	If StringInStr($MajorMinorVersionLine, "#define RAINMETER_VERSION MAKE_VER(") > 0 Then
		$MajorVersion = StringMid($MajorMinorVersionLine,36,1)
		$Minor1Version = StringMid($MajorMinorVersionLine,39,1)
		$Minor2Version = StringMid($MajorMinorVersionLine,42,1)
	EndIf
Wend

FileClose($HeaderRainmeterFile)

$HeaderRevisionFile = FileOpen("..\revision-number.h", 0)

If $HeaderRevisionFile = -1 Then
	MsgBox("16","UpdateApplicationRC.exe", "Unable to open file:" & @CRLF & @CRLF & "..\revision-number.h" & @CRLF & @CRLF & "Cannot retrieve CURRENT revision number")
	Exit
EndIf

While 1
	$RevisionLine = FileReadLine($HeaderRevisionFile)
	If @error = -1 Then ExitLoop
	If StringInStr($RevisionLine, "const int revision_number = ") > 0 Then
		$NewRevisionNumber = StringMid($RevisionLine, 29, StringLen($RevisionLine)-29)
	EndIf
Wend

FileClose($HeaderRevisionFile)

$ApplicationRCFile = FileOpen("..\Application\Application.rc", 0)

If $ApplicationRCFile = -1 Then
	MsgBox("16","UpdateApplicationRC.exe", "Unable to open file:" & @CRLF & @CRLF & "..\Application\Application.rc" & @CRLF & @CRLF & "Cannot retrieve OLD revision number")
	Exit
EndIf

While 1
	$RevisionLine = FileReadLine($ApplicationRCFile)
	If @error = -1 Then ExitLoop
	If StringInStr($RevisionLine, " FILEVERSION 1,3,0,") > 0 Then
		$OldRevisionNumber = StringMid($RevisionLine, 20, StringLen($RevisionLine)-19)
	EndIf
Wend

FileClose($ApplicationRCFile)

$ApplicationRCFile = "..\Application\Application.rc"

$retval = _ReplaceStringInFile($ApplicationRCFile, " FILEVERSION 1,3,0," & $OldRevisionNumber, " FILEVERSION 1,3,0," & $NewRevisionNumber)
if $retval = -1 then
    msgbox(0, "ERROR", "The pattern could not be replaced in file: " & $ApplicationRCFile & " Error: " & @error)
    exit
EndIf

$retval = _ReplaceStringInFile($ApplicationRCFile, " PRODUCTVERSION 1,3,0," & $OldRevisionNumber, " PRODUCTVERSION 1,3,0," & $NewRevisionNumber)
if $retval = -1 then
    msgbox(0, "ERROR", "The pattern could not be replaced in file: " & $ApplicationRCFile & " Error: " & @error)
    exit
EndIf

$retval = _ReplaceStringInFile($ApplicationRCFile, "VALUE " & chr(34) & "FileVersion" & chr(34) & ", " & Chr(34) & $MajorVersion & ", " & $Minor1Version & ", " & $Minor2Version & ", " & $OldRevisionNumber & chr(34), "VALUE " & chr(34) & "FileVersion" & chr(34) & ", " & Chr(34) & $MajorVersion & ", " & $Minor1Version & ", " & $Minor2Version & ", " & $NewRevisionNumber & chr(34))
if $retval = -1 then
    msgbox(0, "ERROR", "The pattern could not be replaced in file: " & $ApplicationRCFile & " Error: " & @error)
    exit
EndIf

$retval = _ReplaceStringInFile($ApplicationRCFile, "VALUE " & chr(34) & "ProductVersion" & chr(34) & ", " & Chr(34) & $MajorVersion & ", " & $Minor1Version & ", " & $Minor2Version & ", " & $OldRevisionNumber & chr(34), "VALUE " & chr(34) & "ProductVersion" & chr(34) & ", " & Chr(34) & $MajorVersion & ", " & $Minor1Version & ", " & $Minor2Version & ", " & $NewRevisionNumber & chr(34))
if $retval = -1 then
    msgbox(0, "ERROR", "The pattern could not be replaced in file: " & $ApplicationRCFile & " Error: " & @error)
    exit
EndIf

Exit