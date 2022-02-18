; #FUNCTION# ===========================================================================================
; Name:             _FileListToArrayXT
; Description:      Lists files and\or folders in specified path(s) (Similar to using Dir with the /B Switch)
;                   additional features: multi-path, multi-filter, multi-exclude-filter, path format options, recursive search
; Syntax:           _FileListToArrayXT([$sPath = @ScriptDir, [$sFilter = "*", [$iRetItemType, [$bRecursive = False, [$sExclude = "", [$iRetFormat = 1]]]]]])
; Parameter(s):     $sPath = optional: Search path(s), semicolon delimited (default: @ScriptDir)
;                            (Example: "C:\Tmp;D:\Temp")
;                   $sFilter = optional: Search filter(s), semicolon delimited . Wildcards allowed. (default: "*")
;                              (Example: "*.exe;*.txt")
;                   $iRetItemType = Include in search: 0 = Files and Folder, 1 = Files Only, 2 = Folders Only
;                   $iRetPathType = Returned element format: 0 = file/folder name only, 1 = relative path, 2 = full path
;                   $bRecursive = optional: True: recursive search including all subdirectories
;                                           False (default): search only in specified folder
;                   $sExclude = optional: Exclude filter(s), semicolon delimited. Wildcards allowed.
;                               (Example: "Unins*" will remove all files/folders that begin with "Unins")
;                   $iRetFormat =  optional: return format
;                                  0 = one-dimensional array, 0-based
;                                  1 = one-dimensional array, 1-based (default)
;                                  2 = String ( "|" delimited)
; Requirement(s):   AutoIt Version 3.3.1.1 or newer
; Return Value(s):  on success: 1-based or 0-based array or string (dependent on $iRetFormat)
;                   If no path is found, @error and @extended are set to 1, returns empty string
;                   If no filter is found, @error and @extended are set to 2, returns empty string
;                   If $iRetFormat is invalid, @error and @extended are set to 3, returns empty string
;                   If no data is found, @error and @extended are set to 4, returns empty string
; Author(s):        Half the AutoIt Community
; ====================================================================================================
Func _FileListToArrayXT($sPath = @ScriptDir, $sFilter = "*", $iRetItemType = 0, $iRetPathType = 0, $bRecursive = False, $sExclude = "", $iRetFormat = 1)
  Local $hSearchFile, $sFile, $sFileList, $sWorkPath, $sRetPath, $iRootPathLen, $iPCount, $iFCount, $fDirFlag

  ;[check and prepare parameters]
  ;---------------
  If $sPath = -1 Or $sPath = Default Then $sPath = @ScriptDir
  ;strip leading/trailing spaces and semi-colons, all adjacent semi-colons, and spaces surrounding semi-colons
  $sPath = StringRegExpReplace(StringRegExpReplace($sPath, "(\s*;\s*)+", ";"), "\A;|;\z", "")
  ;check that at least one path is set
  If $sPath = "" Then Return SetError(1, 1, "")
  ;-----
  If $sFilter = -1 Or $sFilter = Default Then $sFilter = "*"
  ;prepare filter
  ;strip leading/trailing spaces and semi-colons, all adjacent semi-colons, and spaces surrounding semi-colons
  $sFilter = StringRegExpReplace(StringRegExpReplace($sFilter, "(\s*;\s*)+", ";"), "\A;|;\z", "")
  ;check for invalid chars or that at least one filter is set
  If StringRegExp($sFilter, "[\\/><:\|]|(?s)\A\s*\z") Then Return SetError(2, 2, "")
  If $bRecursive Then
    ;Convert $sFilter for Regular Expression
    $sFilter = StringRegExpReplace($sFilter, '([\Q\.+[^]$(){}=!\E])', '\\$1')
    $sFilter = StringReplace($sFilter, "?", ".")
    $sFilter = StringReplace($sFilter, "*", ".*?")
    $sFilter = "(?i)\A(" & StringReplace($sFilter, ";", "$|") & "$)" ;case-insensitive, convert ';' to '|', match from first char, terminate strings
    ;$sFilter = "(?i)\A" & StringReplace($sFilter, ";", "|") & "\z"
  EndIf
  ;-----
  If $iRetItemType <> "1" And $iRetItemType <> "2" Then $iRetItemType = "0"
  ;-----
  If $iRetPathType <> "1" And $iRetPathType <> "2" Then $iRetPathType = "0"
  ;-----
  $bRecursive = ($bRecursive = "1")
  ;-----
  If $sExclude = -1 Or $sExclude = Default Then $sExclude = ""
  If $sExclude Then
    ;prepare $sExclude
    ;strip leading/trailing spaces and semi-colons, all adjacent semi-colons, and spaces surrounding semi-colons
    $sExclude = StringRegExpReplace(StringRegExpReplace($sExclude, "(\s*;\s*)+", ";"), "\A;|;\z", "")
    ;Convert $sExclude for Regular Expression
    $sExclude = StringRegExpReplace($sExclude, '([\Q\.+[^]$(){}=!\E])', '\\$1')
    $sExclude = StringReplace($sExclude, "?", ".")
    $sExclude = StringReplace($sExclude, "*", ".*?")
    $sExclude = "(?i)\A(" & StringReplace($sExclude, ";", "$|") & "$)" ;case-insensitive, convert ';' to '|', match from first char, terminate strings
    ;$sExclude = "(?i)\A" & StringReplace($sExclude, ";", "|") & "\z"
  EndIf
  ;-----
  ;If $iRetFormat <> "0" And $iRetFormat <> "2" Then $iRetFormat = "1"
  If Not ($iRetItemType = 0 Or $iRetItemType = 1 Or $iRetItemType = 2) Then Return SetError(3, 3, "")
  ;---------------
  ;[/check and prepare parameters]

  ;---------------

  Local $aPath = StringSplit($sPath, ';', 1) ;paths array
  Local $aFilter = StringSplit($sFilter, ';', 1) ;filters array

  ;---------------

  If $bRecursive Then ;different handling for recursion (strategy: unfiltered search for all items and filter unwanted)

    If $sExclude Then ;different handling dependent on $sExclude parameter is set or not

      For $iPCount = 1 To $aPath[0] ;Path loop
        $sPath = StringRegExpReplace($aPath[$iPCount], "[\\/]+\z", "") & "\" ;ensure exact one trailing slash
        If Not FileExists($sPath) Then ContinueLoop
        $iRootPathLen = StringLen($sPath) - 1

        Local $aPathStack[1024] = [1, $sPath]

        While $aPathStack[0] > 0
          $sWorkPath = $aPathStack[$aPathStack[0]]
          $aPathStack[0] -= 1
          ;-----
          $hSearchFile = FileFindFirstFile($sWorkPath & '*')
          If @error Then ContinueLoop
          ;-----
          Switch $iRetPathType
            Case 2 ;full path
              $sRetPath = $sWorkPath
            Case 1 ;relative path
              $sRetPath = StringTrimLeft($sWorkPath, $iRootPathLen + 1)
          EndSwitch
          ;-----
          Switch $iRetItemType
            Case 1
              While True ;Files only
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                $fDirFlag = @extended
                If $fDirFlag Then
                  $aPathStack[0] += 1
                  If UBound($aPathStack) <= $aPathStack[0] Then ReDim $aPathStack[UBound($aPathStack) * 2]
                  $aPathStack[$aPathStack[0]] = $sWorkPath & $sFile & "\"
                  ContinueLoop
                EndIf
                If StringRegExp($sFile, $sExclude) Then ContinueLoop
                If StringRegExp($sFile, $sFilter) Then
                  $sFileList &= $sRetPath & $sFile & "|"
                EndIf
              WEnd
            Case 2
              While True ;Folders only
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                $fDirFlag = @extended
                If StringRegExp($sFile, $sExclude) Then ContinueLoop
                If $fDirFlag Then
                  $aPathStack[0] += 1
                  If UBound($aPathStack) <= $aPathStack[0] Then ReDim $aPathStack[UBound($aPathStack) * 2]
                  $aPathStack[$aPathStack[0]] = $sWorkPath & $sFile & "\"
                  If StringRegExp($sFile, $sFilter) Then
                    $sFileList &= $sRetPath & $sFile & "|"
                  EndIf
                EndIf
              WEnd
            Case Else
              While True ;Files and Folders
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                $fDirFlag = @extended
                If StringRegExp($sFile, $sExclude) Then ContinueLoop
                If $fDirFlag Then
                  $aPathStack[0] += 1
                  If UBound($aPathStack) <= $aPathStack[0] Then ReDim $aPathStack[UBound($aPathStack) * 2]
                  $aPathStack[$aPathStack[0]] = $sWorkPath & $sFile & "\"
                EndIf
                If StringRegExp($sFile, $sFilter) Then
                  $sFileList &= $sRetPath & $sFile & "|"
                EndIf
              WEnd
          EndSwitch
          ;-----
        WEnd

        FileClose($hSearchFile)

      Next ;$iPCount - next path

    Else ;If Not $sExclude

      For $iPCount = 1 To $aPath[0] ;Path loop
        $sPath = StringRegExpReplace($aPath[$iPCount], "[\\/]+\z", "") & "\" ;ensure exact one trailing slash
        If Not FileExists($sPath) Then ContinueLoop
        $iRootPathLen = StringLen($sPath) - 1

        Local $aPathStack[1024] = [1, $sPath]

        While $aPathStack[0] > 0
          $sWorkPath = $aPathStack[$aPathStack[0]]
          $aPathStack[0] -= 1
          ;-----
          $hSearchFile = FileFindFirstFile($sWorkPath & '*')
          If @error Then ContinueLoop
          ;-----
          Switch $iRetPathType
            Case 2 ;full path
              $sRetPath = $sWorkPath
            Case 1 ;relative path
              $sRetPath = StringTrimLeft($sWorkPath, $iRootPathLen + 1)
          EndSwitch
          ;-----
          Switch $iRetItemType
            Case 1
              While True ;Files only
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                If @extended Then
                  $aPathStack[0] += 1
                  If UBound($aPathStack) <= $aPathStack[0] Then ReDim $aPathStack[UBound($aPathStack) * 2]
                  $aPathStack[$aPathStack[0]] = $sWorkPath & $sFile & "\"
                  ContinueLoop
                EndIf
                If StringRegExp($sFile, $sFilter) Then
                  $sFileList &= $sRetPath & $sFile & "|"
                EndIf
              WEnd
            Case 2
              While True ;Folders only
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                If @extended Then
                  $aPathStack[0] += 1
                  If UBound($aPathStack) <= $aPathStack[0] Then ReDim $aPathStack[UBound($aPathStack) * 2]
                  $aPathStack[$aPathStack[0]] = $sWorkPath & $sFile & "\"
                  If StringRegExp($sFile, $sFilter) Then
                    $sFileList &= $sRetPath & $sFile & "|"
                  EndIf
                EndIf
              WEnd
            Case Else
              While True ;Files and Folders
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                If @extended Then
                  $aPathStack[0] += 1
                  If UBound($aPathStack) <= $aPathStack[0] Then ReDim $aPathStack[UBound($aPathStack) * 2]
                  $aPathStack[$aPathStack[0]] = $sWorkPath & $sFile & "\"
                EndIf
                If StringRegExp($sFile, $sFilter) Then
                  $sFileList &= $sRetPath & $sFile & "|"
                EndIf
              WEnd
          EndSwitch
          ;-----
        WEnd

        FileClose($hSearchFile)

      Next ;$iPCount - next path

    EndIf ;If $sExclude

  Else ;If Not $bRecursive (strategy: filtered search for items)

    If $sExclude Then ;different handling dependent on $sExclude parameter is set or not

      For $iPCount = 1 To $aPath[0] ;Path loop

        $sPath = StringRegExpReplace($aPath[$iPCount], "[\\/]+\z", "") & "\" ;ensure exact one trailing slash
        If Not FileExists($sPath) Then ContinueLoop
        ;-----
        Switch $iRetPathType
          Case 2 ;full path
            $sRetPath = $sPath
          Case 1 ;relative path
            $sRetPath = ""
        EndSwitch

        For $iFCount = 1 To $aFilter[0] ;filter loop
          ;-----
          $hSearchFile = FileFindFirstFile($sPath & $aFilter[$iFCount])
          If @error Then ContinueLoop
          ;-----
          Switch $iRetItemType
            Case 1 ;files Only
              While True
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                If @extended Then ContinueLoop ;bypass folder
                ;check for exclude files
                If StringRegExp($sFile, $sExclude) Then ContinueLoop
                $sFileList &= $sRetPath & $sFile & "|"
              WEnd
            Case 2 ;folders Only
              While True
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                If @extended Then ;bypass file
                  ;check for exclude folder
                  If StringRegExp($sFile, $sExclude) Then ContinueLoop
                  $sFileList &= $sRetPath & $sFile & "|"
                EndIf
              WEnd
            Case Else ;files and folders
              While True
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                ;check for exclude files/folder
                If StringRegExp($sFile, $sExclude) Then ContinueLoop
                $sFileList &= $sRetPath & $sFile & "|"
              WEnd
          EndSwitch
          FileClose($hSearchFile)
        Next ;$iFCount - next filter

      Next ;$iPCount - next path

    Else ;If Not $sExclude

      For $iPCount = 1 To $aPath[0] ;Path loop

        $sPath = StringRegExpReplace($aPath[$iPCount], "[\\/]+\z", "") & "\" ;ensure exact one trailing slash
        If Not FileExists($sPath) Then ContinueLoop
        ;-----
        Switch $iRetPathType
          Case 2 ;full path
            $sRetPath = $sPath
          Case 1 ;relative path
            $sRetPath = ""
                EndSwitch

        For $iFCount = 1 To $aFilter[0] ;filter loop
          ;-----
          $hSearchFile = FileFindFirstFile($sPath & $aFilter[$iFCount])
          If @error Then ContinueLoop
          ;-----
          Switch $iRetItemType
            Case 1 ;files Only
              While True
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                If @extended Then ContinueLoop ;bypass folder
                $sFileList &= $sRetPath & $sFile & "|"
              WEnd
            Case 2 ;folders Only
              While True
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                If @extended Then ;bypass file
                  $sFileList &= $sRetPath & $sFile & "|"
                EndIf
              WEnd
            Case Else ;files and folders
              While True
                $sFile = FileFindNextFile($hSearchFile)
                If @error Then ExitLoop
                $sFileList &= $sRetPath & $sFile & "|"
              WEnd
          EndSwitch
          FileClose($hSearchFile)
        Next ;$iFCount - next filter

      Next ;$iPCount - next path

    EndIf ;If $sExclude

  EndIf ;If $bRecursive

  ;---------------

  ;set according return value
  If $sFileList Then
    Switch $iRetFormat
      Case 2 ;return a delimited string
        Return StringTrimRight($sFileList, 1)
      Case 0 ;return a 0-based array
        Return StringSplit(StringTrimRight($sFileList, 1), "|", 2)
      Case Else ;return a 1-based array
        Return StringSplit(StringTrimRight($sFileList, 1), "|", 1)
    EndSwitch
  Else
    Return SetError(4, 4, "")
  EndIf

EndFunc   ;==>_FileListToArrayXT
