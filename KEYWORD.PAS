PROGRAM KeyWord;

USES  DOS,SysUtils;
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
    MaxCommand         : Word;    (*対象コマンド数*)
    DF_Name,SF_Name : String;  (*対象ファイル名*)
    D_Flag,C_Flag,K_Flag,      (*ダッシュの中、コメント内無変換用*)
    CS_Flag,CE_Flag : BOOLEAN; (*コメントの始めと終わり用*)
    ReadTextBufHeap : POINTER; (**テキストバッファ用**)
    WriteTextBufHeap : POINTER; (**テキストバッファ用**)
    ViewOn:BOOLEAN;

PROCEDURE Window(a,b,c,d:BYTE);
BEGIN
END;

PROCEDURE Initialize;
(*大域変数、画面等の初期化*)
BEGIN
  D_Flag  := FALSE;  C_Flag := FALSE;   K_Flag := FALSE;
  CS_Flag := FALSE;  CE_Flag := FALSE;
  WRITELN('Keyword Converter');
  WRITE('Ver ',Version);
  WRITELN('     by A.Matsumoto');
  WRITELN;
END; { of Initialize }



FUNCTION UpCaseStr(Str:String) : String;
VAR i : BYTE;
BEGIN
  FOR i:=1 TO Length(Str) DO   Str[i] := UpCase(Str[i]);
  UpCaseStr := Str;
END; { of UpCaseStr }


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
  FSPLIT(Paramstr(0),DSN,NSN,ESN);
  ASSIGN(CmdFile,DSN+CommandFileName);
  {$I-}
    Reset(CmdFile);
  {$I+}
  IF IoResult<>0 THEN BEGIN
    WRITELN('コマンドファイルがありません。');
    WRITELN('COMMAND.MY をセットして下さい。');
    WRITELN(^g,'プログラムの実行を中断します。');
    HALT(1);
  END; { if }
  WRITELN('コマンドファイルを読み込み中です。');
  MaxCommand:=1;
  i:=1;
  WHILE NOT(EOF(CmdFile)) DO BEGIN
    READLN(CmdFile,NewCmd[i]);
    IF Length(NewCmd[i])>0 THEN BEGIN
        Inc(i);
    END;
  END;
  MaxCommand:=i-1;
  WRITELN('コマンド数：',MaxCommand);
  FOR i:=1 TO MaxCommand DO   OldCmd[i] := UpCaseStr(NewCmd[i]);
  Close(CmdFile);
  WRITELN('コマンドファイルを読み込みました。');
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
  IF D_Flag OR C_Flag OR K_Flag THEN
    EXIT;                        (*コメントまたは表示文なら無視する*)
  temp_Str := word_Str;
  temp_str := UpCaseStr(temp_str);
  i := 1;    j := MaxCommand;
  REPEAT
    k := (i+j) Div 2;
    IF OldCmd[k]<=temp_Str THEN i := SUCC(k);
    IF OldCmd[k]>=temp_Str THEN j := Pred(k);
  UNTIL i>j;
  IF temp_Str=OldCmd[k] THEN   word_Str :=NewCmd[k];
END; (* of Transfer *)


PROCEDURE Check_D_C(CH : CHAR);
(*コメントや表示文についてのチェック
*)
BEGIN
  CASE CH OF
    '{' : IF NOT(D_Flag) AND NOT(C_Flag) THEN K_Flag := True;
    '}' : IF NOT(D_Flag) AND NOT(C_Flag) THEN K_Flag := FALSE;
   '''' : BEGIN
            IF NOT(D_Flag) AND NOT(C_Flag) AND NOT(K_Flag) THEN BEGIN
              D_Flag  := True;
              CS_Flag := FALSE;                          { start ' }
            END { if }
            ELSE IF D_Flag THEN   D_Flag := FALSE;       { end '   }
          END; { of ' }
    '(' : IF NOT(C_Flag) AND NOT(D_Flag) AND NOT(K_Flag) THEN
            CS_Flag := True;
    '*' : BEGIN
            IF CS_Flag THEN  BEGIN
              C_Flag  := True;
              CS_Flag := FALSE;
            END { if }
            ELSE IF C_Flag THEN   CE_Flag := True; { end of comment }
          END; { of * }
    ')' : IF CE_Flag THEN BEGIN
            C_Flag  := FALSE;
            CE_Flag := FALSE;
          END; { of ) }
    ELSE BEGIN
      CS_Flag := FALSE;
      CE_Flag := FALSE;
    END; { case else }
  END; { of case }
END; (* of Check_D_C *)


PROCEDURE Pick_Word(Line : String);
(*単語を切り出し、キーワードについての変換を行う
*)
VAR k_Word,temp_Str : String;
    i,w_len         : Word;
BEGIN
  w_len := Length(Line);
  i := 1;
  WHILE i<=w_len DO BEGIN
    k_Word   := '';
    temp_Str := '';
    WHILE (NOT(UpCase(Line[i]) IN ['A'..'Z','_'])) AND (i<=w_len) DO BEGIN
      Check_D_C(Line[i]);
      temp_Str := temp_Str + Line[i];  (*キーワードではないもの*)
      Inc(i);
    END; (* wend *)
    IF CS_Flag OR CE_Flag THEN BEGIN   (*コメントのチェックフラグのリセット*)
      CS_Flag := FALSE;
      CE_Flag := FALSE;
    END; { if }
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
        repeat
            Initialize;
            ReplaceToken(Info.Name);
            WRITELN('Replace File Name=',Info.name);
        UNTIL FindNext(Info)<>0;
    END;
        
END. (* of main *)
