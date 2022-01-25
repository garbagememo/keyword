program nKWD;
{$H+}{$MODE objfpc}
{$modeswitch advancedrecords}
USES SysUtils,Classes,uCommand,getopts;

{
$20,$9:space;
$21..$29,$3a..$40:mark;
$30..$39:numeral;
$41..$5a:ALPHABET;
$5b..$5e,$60:mark;
$5f:underscore;
$61..$7a:alphabet;
$80,,$ff:UTF8;
}

type
  TokenReaderRecord=RECORD
    CurSt:String;
    CurStLength:integer;
    SideEffectCh:Char;
    cPos:integer;
    LineCounter:integer;
    isUTF8:boolean;
    inCommentFlag,SlashCommentFlag,ParenCommentFlag,BracketCommentFlag:Boolean;
    procedure ClearCommentFlag;
    procedure SetSt(st_:string);
    function isEnd:boolean;//cPOSが行末だったらtrueを返す
    function isComment:boolean;
    function ReplaceKeyword(st:string):string;
    function FetchStr:String;
  END;


procedure TokenReaderRecord.ClearCommentFlag;
BEGIN
  InCommentFlag:=FALSE;SlashCommentFlag:=FALSE;ParenCommentFlag:=FALSE;BracketCommentFlag:=FALSE;
  isUTF8:=TRUE;
  LineCounter:=1;
END;

//UTF8は文頭にCPの2byteがつく・・・多分
procedure TokenReaderRecord.SetSt(st_:string);
begin
  CurSt:=st_;
  CurStLength:=Length(CurSt);
  cPos:=1;
  IF SlashCommentFlag THEN BEGIN
    inCommentFlag:=FALSE;
    SlashCommentFlag:=FALSE;
  END;
  IF InCommentFlag=FALSE THEN BEGIN
    ParenCommentFlag:=FALSE;
    BracketCommentFlag:=FALSE;
  END;
  IF LineCounter=1 THEN BEGIN
//UTFの場合、文字列にUTF識別子がついているのでそれを削除
    while  CurSt[1]>#$80 DO Delete(CurSt,1,1);
    CurStLength:=Length(CurSt);
  END;
  Inc(LineCounter);
end;

function TokenReaderRecord.isEnd:boolean;//cPOSが行末だったらtrueを返す
BEGIN
  IF CurStLength<cPOS THEN result:=true ELSE result:=FALSE;
END;

function TokenReaderRecord.isComment:boolean;
var
  ch,NextCh:char;
BEGIN
  isComment:=inCommentFlag;
  ch:=CurSt[cPos];SideEffectCh:=#0;
  IF CurStLength>=cPos+1 THEN NextCh:=CurSt[cPos+1] ELSE NextCh:=#0;
  IF inCommentFlag THEN BEGIN (**コメント終わりかどうか？if**)
    IF ParenCommentFlag THEN BEGIN
      IF (ch='*') and(NextCh=')' ) THEN BEGIN
          ParenCommentFlag:=FALSE;
          isComment:=FALSE;
          SideEffectCh:='*';inc(cPos);
      END;
    END;
    IF BracketCommentFlag THEN BEGIN
      IF ch='}' THEN BEGIN
        isComment:=FALSE;
        BracketCommentFlag:=FALSE;
      END;
    END;
  END
  ELSE BEGIN(**コメントかどうか？**)
    IF (ch='(') and (NextCh='*') THEN BEGIN
      isComment:=TRUE;ParenCommentFlag:=TRUE;
    END;
    IF ch='{' THEN BEGIN
      isComment:=TRUE;BracketCommentFlag:=TRUE;
    END;
    IF (ch='/') and (NextCh='/') THEN BEGIN
      isComment:=TRUE;SlashCommentFlag:=TRUE;
    END;
  END;
END;

function TokenReaderRecord.ReplaceKeyword(st:string):string;
var
  i:integer;
BEGIN
  for i:=0 to CmdStrList.count-1 do begin
    IF UpperCase(st)=CmdStrList[i] THEN BEGIN
      result:=CmdStrList[i] ;exit;
    END;
  end;
  result:=st;
END;


FUNCTION TokenReaderRecord.FetchStr:String;
var
  ch:char;
  kStr,wStr:String;
BEGIN
  wStr:='';
  IF CurStLength<=0 THEN BEGIN
    FetchStr:='';
    exit;
  END;
  while isEnd=FALSE DO BEGIN
    WHILE NOT(CurSt[cPos] IN ['A'..'Z','_','a'..'z']) AND (isEnd=FALSE) DO BEGIN
      inCommentFlag:=isComment;//*)の扱いが問題あるが・・・
      IF SideEffectCh<>#0 THEN wStr:=wStr+SideEffectCh;
      wStr:=wStr+CurSt[cPos];inc(cPos);
    END;

    kStr:='';
    WHILE (CurSt[cPos] IN ['A'..'Z','_','a'..'z']) AND (isEnd=FALSE) DO BEGIN
      kStr:=kStr+CurSt[cPos];inc(cPos);
    END;
    IF inCommentFlag=FALSE THEN kStr:=ReplaceKeyword(kStr);
    wStr:=wStr+kStr;
  END;
  FetchStr:=wStr;
END;

var
  Line:String;
  oLine:String;
  fp,oFp:Text;
  c:char;
  OFN:String;
  TokenReader:TokenReaderRecord;
  Info:TSearchRec;
  isUTF8,isOutFile:Boolean;
BEGIN
  InitCmdStr;
  isUTF8:=TRUE;isOutFile:=FALSE;
  c:=#0;
  REPEAT
    c:=getopt('o:e:');
    CASE c OF
      'o': BEGIN
        OFN:=OptArg;
        isOutFile:=TRUE;
        assign(oFp,OFN);rewrite(oFp);
      END;
      'e':BEGIN
        IF UpperCase(OptArg)='S' THEN BEGIN
          isUTF8:=FALSE;
        END;
      END;
    END; { case }
  UNTIL c=endofoptions;

  if optind<=paramcount then begin
    writeln(' Arg=',ParamStr(OptInd) );
    FindFirst(ParamStr(OptInd),faAnyFile,Info);
    repeat
      IF (Info.Attr and faDirectory)<>faDirectory THEN BEGIN
        writeln(' Assign Name=',Info.name);

        assign(fp,Info.Name); reset(fp);
        TokenReader.ClearCommentFlag;
        TokenReader.isUTF8:=isUTF8;
        while EOF(fp)=FALSE DO BEGIN
          ReadLN(fp,LINE);   
          oLine:=LINE;
          TokenReader.SetSt(oLine);
          oLine:=TokenReader.FetchStr;
          writeln(oLINE);
          IF isOutFile THEN Writeln(oFp,oLine);
        END;
        close(fp);
        IF isOutFile THEN close(oFp);

      END;
    until FindNext(Info)<>0;
    FindClose(Info);
  end;
END.
