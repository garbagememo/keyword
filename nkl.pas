program nKWD;
{$H+}{$MODE objfpc}
{$modeswitch advancedrecords}
uses SysUtils,Classes,uCommand,getopts;

const
  LowerFlag:boolean=true;
type
  TokenReaderRecord=record
    CurSt:String;
    CurStLength:integer;
    SideEffectCh:char;
    cPos:integer;
    LineCounter:integer;
    isUTF8:boolean;
    inCommentFlag,SlashCommentFlag,ParenCommentFlag,BracketCommentFlag:boolean;
    LiteralFlag:boolean;
    procedure ClearCommentFlag;
    procedure SetSt(st_:string);
    function isEnd:boolean;//cPOSが行末だったらtrueを返す
    function isStringData:boolean;
    function ReplaceKeyword(st:string):string;
    function FetchStr:String;
  end;
var
  ReplaceFlag:boolean;

procedure TokenReaderRecord.ClearCommentFlag;
begin
  InCommentFlag:=false;
  SlashCommentFlag:=false;ParenCommentFlag:=false;BracketCommentFlag:=false;
  LiteralFlag:=false;
  isUTF8:=TRUE;
  LineCounter:=1;
end;

//UTF8は文頭にCPの識別子＋2byteがつく・・・多分
procedure TokenReaderRecord.SetSt(st_:string);
begin
  CurSt:=st_;
  CurStLength:=Length(CurSt);
  cPos:=1;
  if SlashCommentFlag then begin
    inCommentFlag:=false;
    SlashCommentFlag:=false;
  end;
  if InCommentFlag=false then begin
    ParenCommentFlag:=false;
    BracketCommentFlag:=false;
  end;
  if LineCounter=1 then begin
//UTFの場合、文字列にUTF識別子がついているのでそれを削除・・・だと思う
    while  CurSt[1]>#$80 do Delete(CurSt,1,1);
    CurStLength:=Length(CurSt);
  end;
  Inc(LineCounter);
end;

function TokenReaderRecord.isEnd:boolean;//cPOSが行末だったらtrueを返す
begin
  if CurStLength<cPOS then result:=true else result:=false;
end;

function TokenReaderRecord.isStringData:boolean;
var
  ch,NextCh:char;
begin
  result:=inCommentFlag;
  ch:=CurSt[cPos];SideEffectCh:=#0;
  if CurStLength>=cPos+1 then NextCh:=CurSt[cPos+1] else NextCh:=#0;
  if inCommentFlag then begin (**コメント終わりかどうか？if**)
    if ParenCommentFlag then begin
      if (ch='*') and(NextCh=')' ) then begin
          ParenCommentFlag:=false;
          result:=false;
          SideEffectCh:='*';inc(cPos);
      end;
    end;
    if BracketCommentFlag then begin
      if ch='}' then begin
        result:=false;
        BracketCommentFlag:=false;
      end;
    end;
    if LiteralFlag then begin
      if ch=#$27 then begin
        result:=false;
        LiteralFlag:=false;
      end;
    end;
  end
  else begin(**コメントかどうか？**)
    if (ch='(') and (NextCh='*') then begin
      result:=TRUE;ParenCommentFlag:=TRUE;
    end;
    if ch='{' then begin
      result:=TRUE;BracketCommentFlag:=TRUE;
    end;
    if ch=#$27 then begin
      result:=true;LiteralFlag:=TRUE;
    end;
    if (ch='/') and (NextCh='/') then begin
      result:=TRUE;SlashCommentFlag:=TRUE;
    end;
  end;
end;

function TokenReaderRecord.ReplaceKeyword(st:string):string;
var
  i:integer;
begin
  for i:=0 to CmdStrList.count-1 do begin
    if UpperCase(st)=CmdStrList[i] then begin
      if LowerFlag then
	result:=LowerCase(CmdStrList[i])
      else
	result:=CmdStrList[i] ;
      exit;
    end;
  end;
  result:=st;
end;


function TokenReaderRecord.FetchStr:String;
var
  ch:char;
  kStr,wStr:String;
begin
  wStr:='';
  if CurStLength<=0 then begin
    FetchStr:='';
    exit;
  end;
  while isEnd=false do begin
    while not(CurSt[cPos] in ['A'..'Z','_','a'..'z']) and (isEnd=false) do begin
      inCommentFlag:=isStringData;//*)の扱いが問題あるが・・・
      if SideEffectCh<>#0 then wStr:=wStr+SideEffectCh;
      wStr:=wStr+CurSt[cPos];inc(cPos);
    end;

    kStr:='';
    while (CurSt[cPos] in ['A'..'Z','_','a'..'z']) and (isEnd=false) do begin
      kStr:=kStr+CurSt[cPos];inc(cPos);
    end;
    if inCommentFlag=false then kStr:=ReplaceKeyword(kStr);
    wStr:=wStr+kStr;
  end;
  FetchStr:=wStr;
end;

var
  Line:String;
  oLine:String;
  ArgStr:string;
  fp,oFp:Text;
  c:char;
  OFN,tempFN:String;
  TokenReader:TokenReaderRecord;
  Info:TSearchRec;
  isUTF8,isDispCode,isSelfMatch:boolean;
  oLineList:TStringList;
  i:integer;
begin
  replaceFlag:=false;
  tempFN:='temp.tmp';
  InitCmdStr;
  isUTF8:=TRUE;isDispCode:=false;isSelfMatch:=false;
  c:=#0;
  repeat
    c:=getopt('e:mor');
    case c of
      'r':begin
	    ReplaceFlag:=TRUE;
	  end;
      'o': begin
        isDispCode:=TRUE;
           end;
      'm':begin
            isSelfMatch:=true;
      end;
      'e':begin
        if UpperCase(OptArg)='S' then begin
          isUTF8:=false;
        end;
      end;
      '?':begin
        writeln('ussage');
        writeln('nkl [option] FileName');
        writeln('-r replace file (else output TEMP.TMP');
        writeln('-o disp souce screen');
        writeln('-m .pas //unix shell complete * so ');
        writeln('-e s change shift-jis mode.not implement');
      end;
    end; { case }
  until c=endofoptions;

  if optind<=paramcount then begin
    ArgStr:=ParamStr(OptInd);
    if isSelfMatch then ArgStr:='*'+ArgStr;
    writeln(' Arg=',ArgStr );
    FindFirst(ArgStr,faAnyFile,info);
    repeat
      if (Info.Attr and faDirectory)<>faDirectory then begin
        writeln(' Assign Name=',Info.name);
        assign(fp,Info.Name); reset(fp);
        if ReplaceFlag then oFN:=Info.name else oFN:=tempFN;
        oLineList:=TStringList.Create;
        TokenReader.ClearCommentFlag;
        TokenReader.isUTF8:=isUTF8;
        while EOF(fp)=false do begin
          readln(fp,LINE);   
          oLine:=LINE;
          TokenReader.SetSt(oLine);
          oLine:=TokenReader.FetchStr;
          if isDispCode then writeln(oLINE);
          oLineList.add(oLINE);
        end;(*while*);
        close(fp);

        assign(oFp,oFN);rewrite(oFp);
        for i:=0 to oLineList.count-1 do begin
          writeln(oFp,oLineList[i]);
        end;
        close(oFp);
      end;
    until FindNext(Info)<>0;
    FindClose(Info);
  end;
end.

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

