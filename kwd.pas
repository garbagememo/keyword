PROGRAM KeyWord;

USES  DOS,SysUtils,uCommand;
CONST 
    Version = '2.4    1989/07/15';
    Cmd_Limit =1499;          (*コマンドリストの最大値 64K以内*)

    Cyan=10;yellow=5;
    red=7;Green=7;white=2;
    NoReverse=0;
    Reverse=1;
    NoBlink=2;
    CommandFileName='command.my';
    
VAR 
    OldCmd,NewCmd : ARRAY[1..Cmd_Limit] OF String; (*コマンドリスト*)
    Souce,Destination    : Text;    (*対象ファイル用ファイル変数*)
    MaxCommand           : Word;    (*対象コマンド数*)
    DF_Name,SF_Name      : String;  (*対象ファイル名*)
    D_Flag,C_Flag,K_Flag : BOOLEAN; (*ダッシュの中、コメント内無変換用*)
    WS_Flag              : BOOLEAN; (*ダブルスラッシュコメント用*)
    ViewOn:BOOLEAN;


PROCEDURE Initialize;
(*大域変数、画面等の初期化*)
BEGIN
  D_Flag  := FALSE;  C_Flag := FALSE;   K_Flag := FALSE;
  WS_Flag:=FALSE;
  WRITELN('Keyword Converter');
  WRITE('Ver ',Version);
  WRITELN('     by A.Matsumoto');
  WRITELN;
END; { of Initialize }



PROCEDURE Set_Command;
(*コマンドリストにコマンドをファイルから読み込む
*)
VAR i,check  : LONGINT;
    CmdFile : Text;
    temp_Str : String[4];
    DSN:DirStr;NSN:NameStr;ESN:ExtStr;
BEGIN
   FOR i:=1 TO Cmd_Limit DO BEGIN
      OldCmd[i] := '';
      NewCmd[i] := '';
   END; { for i }
   InitCmdStr;
   for i:=1 to CmdStrList.Count DO BEGIN
      NewCmd[i]:=UpperCase(CmdStrList[i-1]);
   end;
   MaxCommand:=CmdStrList.Count;
   WRITELN('Command Number：',MaxCommand);
   FOR i:=1 TO MaxCommand DO   OldCmd[i] := UpperCase(NewCmd[i]);
  
   WRITELN('Command Setup Done!');
END; (* of Set_Command *)


PROCEDURE Prepare;
BEGIN
    Assign(Souce,SF_Name);
    Reset(Souce);
    
    Assign(Destination,'K_TEMP');    (*一時書き込みファイルの指定*)
    ReWrite(Destination);
    
    IF IoResult<>0 THEN BEGIN
        WRITELN('ファイルが見つからないか、何か別にエラーが発生しました。');
        WRITELN(^g,'プログラムの実行を中断します。');
        {$I-}
          Erase(Destination);
        {$I+}
        HALT(1);
    END; { if }
END; { of Prepare }


PROCEDURE Transfer(VAR word_Str : String);
(*わたされた単語がキーワードなら変換する
*)
VAR temp_Str : String;
    i,j,k    : Word;
BEGIN
  IF (Pos('_',word_Str)<>0) OR (Length(word_Str)=1) THEN
    EXIT;
  IF D_Flag OR C_Flag OR K_Flag OR WS_Flag THEN
    EXIT;                        (*コメントまたは表示文なら無視する*)
  temp_Str := word_Str;
  temp_str := UpperCase(temp_str);
  i := 1;    j := MaxCommand;
  FOR i:=1 TO MaxCommand DO BEGIN
    IF OldCmd[i]=temp_Str THEN BEGIN
       word_Str :=NewCmd[i];
       EXIT;
    END;
  END;
END; (* of Transfer *)


PROCEDURE Check_D_C(CH,NextCh : CHAR);
(*コメントや表示文についてのチェック
*)
BEGIN
  CASE CH OF
    '{' : IF NOT(D_Flag) AND NOT(C_Flag) THEN K_Flag := True;
    '}' : IF NOT(D_Flag) AND NOT(C_Flag) THEN K_Flag := FALSE;
   '''' : BEGIN
      IF NOT(D_Flag) AND NOT(C_Flag) AND NOT(K_Flag) AND NOT(WS_Flag) THEN BEGIN
         D_Flag  := True;
      END { if }
      ELSE IF D_Flag THEN D_Flag := FALSE; { end '   }
    END; { of ' }
    '(' : BEGIN
      IF NOT(C_Flag) AND NOT(D_Flag) AND NOT(K_Flag) and (NextCh='*') THEN C_Flag:=TRUE;
    END;{ of ( }
    '*' : BEGIN
      IF C_Flag and Not(WS_FLAG) and ( NextCh=')') THEN  C_Flag:=FALSE;
    END;{of *}
    '/' : IF NextCh='/' THEN BEGIN
      WS_Flag:=TRUE;
    END;// case of //{} OF (*of*) of
  END; { of case }
END; (* of Check_D_C *)


PROCEDURE Pick_Word(Line : String);
(*単語を切り出し、キーワードについての変換を行う
*)
VAR k_Word,temp_Str : String;
    i,w_len         : Word;
BEGIN
  IF WS_Flag THEN WS_Flag:=FALSE;   (*コメントのチェックフラグのリセット*)
  w_len := Length(Line);
  i := 1;
  WHILE i<=w_len DO BEGIN
    k_Word   := '';
    temp_Str := '';
    WHILE (NOT(UpCase(Line[i]) IN ['A'..'Z','_'])) AND (i<=w_len) DO BEGIN
      IF i<w_len THEN
        Check_D_C(Line[i],Line[i+1])
      ELSE
        Check_D_C(Line[i],#0);
      temp_Str := temp_Str + Line[i];  (*キーワードではないもの*)
      Inc(i);
    END; (* wend *)
    WRITE(Destination,temp_Str);            (*Not KeyWord*)
    
    IF ViewOn THEN WRITE(temp_Str);
    WHILE (UpCase(Line[i]) IN ['A'..'Z','_','0'..'9']) AND (i<=w_len) DO BEGIN
      k_Word := k_Word + Line[i];   (*キーワードかもしれないもの*)
      Inc(i);
    END; { wend }
    Transfer(k_Word);               (*キーワードならば変換されて戻ってくる*)
    WRITE(Destination,k_Word);           (*KeyWord or Word*)
    IF ViewOn THEN WRITE(k_Word);
  END; (* of while *)
  WRITELN(Destination);
  IF ViewOn THEN WRITELN; (*CR & LF*)
END; (* of Pick_Word *)


PROCEDURE ReplaceToken(FN:String);
VAR Line : String;
BEGIN
  SF_Name:=FN;
  DF_Name:=FN;
  Prepare;

  WHILE NOT(Eof(Souce)) DO BEGIN  (* Main LooP *)
    READLN(Souce,Line);
    Pick_Word(Line);      (*単語を切り出し、キーワードについて変換する*)
  END; { wend }

  Close(Souce);
  Close(Destination);
  {$i-}
  IF SF_Name=DF_Name THEN
    Erase(Souce);      (*同じ名前ならば古い方を捨てる*)
  {$i+}
  ReName(Destination,DF_Name); (*TEMPから変換する*)
END;

VAR
    st:string;
    Info:TSearchRec;
BEGIN     (* of main *)
    Set_Command;
    IF ParamCount<1 THEN 
        WRITELN('Don''t Exist Argument')
    ELSE BEGIN
        IF ParamStr(2)='View' THEN ViewOn:=TRUE ELSE ViewOn:=FALSE;
        St:=ParamStr(1);
        FindFirst(St,AnyFile,Info);
        REPEAT
            Initialize;
            ReplaceToken(Info.Name);
            WRITELN('Replace File Name=',Info.name);
        UNTIL FindNext(Info)<>0;
    END;
        
END. (* of main *)
