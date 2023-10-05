PROGRAM Replacer;
{$MODE objfpc}{$H+}
{$INLINE ON}
USES  DOS,SysUtils;

CONST
  SrcStr='[Anime Land] Godzilla';
  RepStr='Gozilla';
  //スペースがあるので直接書き換えるか
  //設定ファイルを読み込む形に最終的にはするべき
  BeginBetweenChar='[(';
  EndBetweenChar='])';

    
VAR
  ExtString,OrgStr,DestStr:String;

function DeleteHeadTailSpace(InStr:string):string;
begin
  DestStr:=InStr;
  while DestStr[1]=' ' do begin
    delete(DestStr,1,1);
  end;
  while DestStr[length(DestStr)-1-Length(ExtString)]=' ' do begin
    delete(DestStr,length(DestStr)-1-Length(ExtString),1);
  end;
  result:=DestStr;
end;

function ReplaceStr(InStr:string):string;
var
  RepCount:integer;
begin
  DestStr:=InStr;
  RepCount:=pos(SrcStr,DestStr);
  if RepCount>0 then begin
    delete(DestStr,RepCount,Length(SrcStr));
    Insert(RepStr,DestStr,RepCount);
  end;
  result:=DestStr;
end;

function BetweenSeparetDelete(InStr:String):string;
var
  BSCPos:integer;
  EndPos:integer;
  cc:integer;
begin
  DestStr:=InStr;
  for cc:=1 to 2 do begin
    BSCPos:=pos(BeginBetweenChar[cc],DestStr);
    EndPos:=pos(EndBetweenChar[cc],DestStr);
    while (endpos-BSCPos)>0 do begin
      delete(DestStr,BSCPos,EndPos-BSCPos+1);
      BSCPos:=pos(BeginBetweenChar[cc],DestStr);
      EndPos:=pos(EndBetweenChar[cc],DestStr);
    end;
  end;(*for*)
  result:=DestStr;

end;

VAR
  St:string;
  WorkSt:string;
  Info:TSearchRec;
BEGIN     (* of main *)
  IF ParamCount<1 THEN 
    WRITELN('Don''t Exist Argument')
  ELSE BEGIN
    ExtString:=ParamStr(1);
    St:='*.'+ExtString;
    FindFirst(St,AnyFile,Info);
    REPEAT
      WorkSt:=Info.name;
      WorkSt:=ReplaceStr(WorkSt);
      WorkSt:=BetweenSeparetDelete(WorkSt);
      WorkSt:=DeleteHeadTailSpace(WorkSt);
            WRITELN('Replace File Name=',Info.name);
            writeln(' is Rename=',WorkSt);
//      assign(OrgFile,Info.Name);
//      close(OrgFile);
      RenameFile(Info.name,WorkSt);
    UNTIL FindNext(Info)<>0;
  END;
        
END. (* of main *)
