unit iccalc;

interface

const
  MAX_STACK_SIZE = 32;

  CH_LETTER : integer = $01; CH_DIGIT  : integer = $02;
  CH_SEPARAT: integer = $04; CH_SYMBOL : integer = $08;
  CH_QUOTE  : integer = $10; CH_UNKNOWN: integer = $7E;
  CH_FINAL  : integer = $7F;

{$ALIGN OFF}
type
  { ThqStrMap }

  ThqStrMap = record
    FCount, FCapacity : Integer;
    FExtraLen, FRecordLen : Integer;
    FDoDuplicate : Integer;
    FList : pointer;
  end;
  PhqStrMap = ^ThqStrMap;

  { ThqLexer }

  {$Z4}
  ThqTokenType = (
    TOK_ERROR, TOK_NONE, TOK_FINAL, TOK_INT, TOK_FLOAT, TOK_SYMBOL,
    TOK_NAME, TOK_STRING );
  {$Z1}

  TCharTypeTable = array[0..255] of integer;
  PCharTypeTable = ^TCharTypeTable;

  TSymbolRec = record
    Sym : array[0..3] of char;
    Len, Index, More : Shortint;
  end;
  TSymbolTable = array [0..255] of TSymbolRec;
  PSymbolTable = ^TSymbolTable;

  ThqLexer = record
    // input params
    SS            : PChar;
    CharTypeTable : PCharTypeTable;
    SymTable      : PSymbolTable;
    NoIntegers    : Integer;
    cssn          : Integer;
    ComEnd        : PChar;
    // output params
    Name          : PChar;
    NameLen       : Integer;
    ExtValue      : double;
    IntValue      : Integer;
    PrevTokenType : ThqTokenType;
    CharType      : byte;
  end;
  PhqLexer = ^ThqLexer;

  { ThqMathParser }

type
  TParamSearchFunc = function ( str : PChar; len : Integer; var value : double;
                                param : pointer ) : integer; cdecl;

  ThqMathParser = record
    Parameters : PhqStrMap;
    ExtFunctions : PhqStrMap;
    MoreParams : TParamSearchFunc;
    ParamFuncParam : pointer;
    // ... - we do not need other members
  end;
  PhqMathParser = ^ThqMathParser;
{$ALIGN ON}

// hqStrMap

function Strmap_Create( extrabytes, dup : Integer ): PhqStrMap; cdecl;
function Strmap_CreateFromChain( extrabytes : Integer; strchain : PChar; data : pointer ): PhqStrMap; cdecl;
procedure StrMap_Destroy( strmap : PhqStrMap ); cdecl;

procedure StrMap_AddString( strmap : PhqStrMap; str : PChar; data : pointer ); cdecl;
procedure StrMap_AddStrLen( strmap : PhqStrMap; str : PChar; len : Integer; data : pointer ); cdecl;
procedure StrMap_ShrinkMem( strmap : PhqStrMap ); cdecl;
procedure StrMap_Trim( strmap : PhqStrMap; NewCount : Integer ); cdecl;
procedure StrMap_TrimClear( strmap : PhqStrMap; NewCount : Integer ); cdecl;
procedure StrMap_SetCapacity( strmap : PhqStrMap; NewCapacity : Integer ); cdecl;
function StrMap_IndexOf( strmap : PhqStrMap; str : PChar; var data : Pointer ): Integer; cdecl;
function StrMap_LenIndexOf( strmap : PhqStrMap; str : PChar; len : Integer; var data : Pointer ): Integer; cdecl;
function StrMap_GetString( strmap : PhqStrMap; index : Integer; var len : Integer; var data : Pointer ): PChar; cdecl;

// hqLexer

function Lexer_SetParseString( lexer : PhqLexer; str : PChar ): Integer; cdecl;
function Lexer_GetNextToken( lexer : PhqLexer ) : ThqTokenType; cdecl;
function Lexer_GetCurrentPos( lexer : PhqLexer ): PChar; cdecl;

// hqMathParser

function MathParser_Create( MoreLetters : PChar ) : PhqMathParser; cdecl;
procedure MathParser_Destroy( parser : PhqMathParser ); cdecl;
function MathParser_Parse( parser : PhqMathParser; Formula : PChar; var dresult : double ) : PChar; cdecl;

// misc

function IsEngWin1251RusName( Str : PChar ) : integer; cdecl;
procedure InitCharTypeTable( var CharTypeTable : TCharTypeTable; CharTypes : Integer ); cdecl;
procedure TypeTableAddChars( var CharTypeTable : TCharTypeTable; Symbols : PChar; CharType : Integer ); cdecl;
procedure PrepareSymTable( var SymTable : TSymbolTable; symbols : PChar ); cdecl;

function PCharLen2Str( str : PChar; len : Integer ): string;

implementation

const
  ccalc = 'ccalc.dll';

function Strmap_Create( extrabytes, dup : Integer ): PhqStrMap; cdecl; external ccalc name 'Strmap_Create';
function Strmap_CreateFromChain( extrabytes : Integer; strchain : PChar; data : pointer ): PhqStrMap; cdecl; external ccalc name 'Strmap_CreateFromChain';
procedure StrMap_Destroy( strmap : PhqStrMap ); cdecl; external ccalc name 'StrMap_Destroy';
procedure StrMap_AddString( strmap : PhqStrMap; str : PChar; data : pointer ); cdecl; external ccalc name 'StrMap_AddString';
procedure StrMap_AddStrLen( strmap : PhqStrMap; str : PChar; len : Integer; data : pointer ); cdecl; external ccalc name 'StrMap_AddStrLen';
procedure StrMap_ShrinkMem( strmap : PhqStrMap ); cdecl; external ccalc name 'StrMap_ShrinkMem';
procedure StrMap_Trim( strmap : PhqStrMap; NewCount : Integer ); cdecl; external ccalc name 'StrMap_Trim';
procedure StrMap_TrimClear( strmap : PhqStrMap; NewCount : Integer ); cdecl; external ccalc name 'StrMap_TrimClear';
procedure StrMap_SetCapacity( strmap : PhqStrMap; NewCapacity : Integer ); cdecl; external ccalc name 'StrMap_SetCapacity';
function StrMap_IndexOf( strmap : PhqStrMap; str : PChar; var data : Pointer ): Integer; cdecl; external ccalc name 'StrMap_IndexOf';
function StrMap_LenIndexOf( strmap : PhqStrMap; str : PChar; len : Integer; var data : Pointer ): Integer; cdecl; external ccalc name 'StrMap_LenIndexOf';
function StrMap_GetString( strmap : PhqStrMap; index : Integer; var len : Integer; var data : Pointer ): PChar; cdecl; external ccalc name 'StrMap_GetString';

procedure InitCharTypeTable( var CharTypeTable : TCharTypeTable; CharTypes : Integer ); cdecl; external ccalc name 'InitCharTypeTable';
procedure TypeTableAddChars( var CharTypeTable : TCharTypeTable; Symbols : PChar; CharType : Integer ); cdecl; external ccalc name 'TypeTableAddChars';
procedure PrepareSymTable( var SymTable : TSymbolTable; symbols : PChar ); cdecl; external ccalc name 'PrepareSymTable';

function Lexer_SetParseString( lexer : PhqLexer; str : PChar ): Integer; cdecl; external ccalc name 'Lexer_SetParseString';
function Lexer_GetNextToken( lexer : PhqLexer ) : ThqTokenType; cdecl; external ccalc name 'Lexer_GetNextToken';
function Lexer_GetCurrentPos( lexer : PhqLexer ): PChar; cdecl; external ccalc name 'Lexer_GetCurrentPos';

function MathParser_Create( MoreLetters : PChar ) : PhqMathParser; cdecl; external ccalc name 'MathParser_Create';
procedure MathParser_Destroy( parser : PhqMathParser ); cdecl; external ccalc name 'MathParser_Destroy';
function MathParser_Parse( parser : PhqMathParser; Formula : PChar; var dresult : double ) : PChar; cdecl; external ccalc name 'MathParser_Parse';

function IsEngWin1251RusName( Str : PChar ) : integer; cdecl; external ccalc name 'IsEngWin1251RusName';

{function StrNDup( str : PChar; len : Integer ): PChar;
begin
  result := malloc( len+1 );
  strncpy( result, str, len );
  result[len] := #0;
end;}

function PCharLen2Str( str : PChar; len : Integer ): string;
var
  ch : char;
begin
  ch := str[ len ];
  str[ len ] := #0;
  result := str;
  str[ len ] := ch;
end;

end.
