SetCompressor /FINAL /SOLID lzma

Function GetFontName
	Exch $R0
	Push $R1
	Push $R2

	System::Call *(i${NSIS_MAX_STRLEN})i.R1
	System::Alloc ${NSIS_MAX_STRLEN}
	Pop $R2
	System::Call gdi32::GetFontResourceInfoW(wR0,iR1,iR2,i1)i.R0
	${If} $R0 == 0
		StrCpy $R0 error
	${Else}
		System::Call *$R2(&w${NSIS_MAX_STRLEN}.R0)
	${EndIf}
	System::Free $R1
	System::Free $R2

	Pop $R2
	Pop $R1
	Exch $R0
FunctionEnd

Function ReadINIFileKeys
	Exch $R0 ;INI file to write
	Exch
	Exch $R1 ;INI file to read
	Push $R2
	Push $R3
	Push $R4 ;uni var
	Push $R5 ;uni var
	Push $R6 ;last INI section

	SetShellVarContext all
	CopyFiles /SILENT $R1 "$APPDATA\Rainstaller\KeepVar.txt"
	FileOpen $R2 "$APPDATA\Rainstaller\KeepVar.txt" r

Loop:
	FileRead $R2 $R3   ;get next line into R3
	IfErrors Exit

	${TrimNewLines} "$R3" $R3

	StrCmp $R3 "" Loop   ;if blank line, skip

	StrCpy $R4 $R3 1   ;get first char into R4
	StrCmp $R4 ";" Loop   ;check it for ; and skip line if so
	StrCmp $R4 "#" Loop   ;check it for # and skip line if so

	StrCpy $R4 $R3 "" -1   ;get last char of line into R4
	StrCmp $R4 "]" 0 +6     ;if last char is ], parse section name, else jump to parse key/value
	StrCpy $R6 $R3 -1   ;get all except last char
	StrLen $R4 $R6     ;get str length
	IntOp $R4 $R4 - 1    ;subtract one from length
	StrCpy $R6 $R6 "" -$R4   ;copy all but first char to trim leading [, placing the section name in R6
	Goto Loop

	Push "="  ;push delimiting char
	Push $R3
	Call SplitFirstStrPart
	Pop $R4
	Pop $R5

	Push $R4
	Call Trim
	Pop $R4

	ReadINIStr $0 $R0 $R6 $R4
	StrCmp $0 "" 0 +3
	ClearErrors
	Goto +2
	WriteINIStr $R1 $R6 $R4 $0

	Goto Loop
	
Exit:
	FileClose $R2
	Delete "$APPDATA\Rainstaller\KeepVar.txt"

	Pop $R6
	Pop $R5
	Pop $R4
	Pop $R3
	Pop $R2
	Pop $R1
	Pop $R0
FunctionEnd

Function SplitFirstStrPart
	Exch $R0
	Exch
	Exch $R1
	Push $R2
	Push $R3
	StrCpy $R3 $R1
	StrLen $R1 $R0
	IntOp $R1 $R1 + 1
loop:
	IntOp $R1 $R1 - 1
	StrCpy $R2 $R0 1 -$R1
	StrCmp $R1 0 exit0
	StrCmp $R2 $R3 exit1 loop
exit0:
	StrCpy $R1 ""
	Goto exit2
exit1:
	IntOp $R1 $R1 - 1
	StrCmp $R1 0 0 +3
	StrCpy $R2 ""
	Goto +2
	StrCpy $R2 $R0 "" -$R1
	IntOp $R1 $R1 + 1
	StrCpy $R0 $R0 -$R1
	StrCpy $R1 $R2
exit2:
	Pop $R3
	Pop $R2
	Exch $R1 ;rest
	Exch
	Exch $R0 ;first
FunctionEnd

Function Trim
	Exch $R1 ; Original string
	Push $R2

Loop:
	StrCpy $R2 "$R1" 1
	StrCmp "$R2" " " TrimLeft
	StrCmp "$R2" "$\r" TrimLeft
	StrCmp "$R2" "$\n" TrimLeft
	StrCmp "$R2" "$\t" TrimLeft
	GoTo Loop2

TrimLeft:
	StrCpy $R1 "$R1" "" 1
	Goto Loop

Loop2:
	StrCpy $R2 "$R1" 1 -1
	StrCmp "$R2" " " TrimRight
	StrCmp "$R2" "$\r" TrimRight
	StrCmp "$R2" "$\n" TrimRight
	StrCmp "$R2" "$\t" TrimRight
	GoTo Done

TrimRight:
	StrCpy $R1 "$R1" -1
	Goto Loop2

Done:
	Pop $R2
	Exch $R1
FunctionEnd

Var ShowAll

Function TrimText
	Exch $R0 ; char
	Exch
	Exch $R1 ; length
	Exch 2
	Exch $R2 ; text
	Push $R3
	Push $R4

	StrLen $R3 $R2
	IntCmp $R3 $R1 Done Done
	
	StrCpy $ShowAll "show all.."
	StrCpy $R2 $R2 $R1

	StrCpy $R3 0
		IntOp $R3 $R3 + 1
		StrCpy $R4 $R2 1 -$R3
		StrCmp $R4 "" Done
		StrCmp $R4 $R0 0 -3

		IntOp $R3 $R3 + 1
		StrCpy $R4 $R2 1 -$R3
		StrCmp $R4 "" Done
		StrCmp $R4 $R0 -3

		IntOp $R3 $R3 - 1
		StrCpy $R2 $R2 -$R3
		StrCpy $R2 $R2...

Done:
	StrCpy $R0 $R2
	Pop $R4
	Pop $R3
	Pop $R2
	Pop $R1
	Exch $R0 ; output
FunctionEnd

!macro TrimText Text Length Char Var
Push "${Text}"
Push "${Length}"
Push "${Char}"
	Call TrimText
Pop "${Var}"
!macroend
!define TrimText "!insertmacro TrimText"