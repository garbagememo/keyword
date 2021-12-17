UNIT uCommand;
INTERFACE
USES SysUtils,Classes;

var
   CmdStrList : TStringList;

procedure InitCmdStr;

IMPLEMENTATION

procedure InitCmdStr;
BEGIN
   CmdStrList:=TStringList.Create;  

   CmdStrList.Add('AND');
   CmdStrList.Add('ARRAY');
   CmdStrList.Add('BEGIN');
   CmdStrList.Add('BOOLEAN');
   CmdStrList.Add('BYTE');
   CmdStrList.Add('CASE');
   CmdStrList.Add('CHAR');
   CmdStrList.Add('CHR');
   CmdStrList.Add('CLASS');
   CmdStrList.Add('CONST');
   CmdStrList.Add('CONSTRUCTOR');
   CmdStrList.Add('DO');
   CmdStrList.Add('ELSE');
   CmdStrList.Add('END');
   CmdStrList.Add('EXCEPT');
   CmdStrList.Add('EXIT');
   CmdStrList.Add('FALSE');
   CmdStrList.Add('FOR');
   CmdStrList.Add('FUNCTION');
   CmdStrList.Add('GOTO');
   CmdStrList.Add('HALT');
   CmdStrList.Add('IF');
   CmdStrList.Add('IMPLEMENTATION');
   CmdStrList.Add('IN');
   CmdStrList.Add('INTEGER');
   CmdStrList.Add('INTERFACE');
   CmdStrList.Add('LABEL');
   CmdStrList.Add('LONGINT');
   CmdStrList.Add('NEW');
   CmdStrList.Add('NIL');
   CmdStrList.Add('NOT');
   CmdStrList.Add('OBJECT');
   CmdStrList.Add('OF');
   CmdStrList.Add('OR');
   CmdStrList.Add('POINTER');
   CmdStrList.Add('PRIVATE');
   CmdStrList.Add('PROCEDURE');
   CmdStrList.Add('PROGRAM');
   CmdStrList.Add('PROTECTED');
   CmdStrList.Add('PUBLIC');
   CmdStrList.Add('READ');
   CmdStrList.Add('READLN');
   CmdStrList.Add('RECORD');
   CmdStrList.Add('REPEAT');
   CmdStrList.Add('SINGLE');
   CmdStrList.Add('SUCC');
   CmdStrList.Add('THEN');
   CmdStrList.Add('TO');
   CmdStrList.Add('TRY');
   CmdStrList.Add('TYPE');
   CmdStrList.Add('UNIT');
   CmdStrList.Add('UNTIL');
   CmdStrList.Add('USES');
   CmdStrList.Add('VAR');
   CmdStrList.Add('WHILE');
   CmdStrList.Add('WITH');
   CmdStrList.Add('WRITE');
   CmdStrList.Add('WRITELN');
END;
BEGIN
END.
