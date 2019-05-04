unit PwdFunUnit;

interface

uses
  SysUtils,Windows,Dialogs,Forms;

const
  C1Key = 12674; //   C1 = 52845;
  C2Key = 35891; //   C2 = 22719;
  XXXKey = 'xlinuxx';  //

//-----------对字符串进行加密和解密的极好的函数----------------
Function EncryptionEngine(Src:String; Key:String; Encrypt : Boolean):string;
function EnCrypt(Sour: String):String; //对上一函数的两个引用,加密
function DeCrypt(Sour: String):String; //解密

function SetLocalSysTime(const newTime:TDateTime):Boolean; //设置本地系统时间

function EncryptStr(const S: string; Key: Word): string; //这两个是我自已写的有点烂，不用了
function DecryptStr(const S: string; Key: Word): string;

function NumToUpper (const je: Real): string;   //小写金额转换为大写金额
function NumToUpper2(const je: Real): string;
function NumToUpper3(const je: Real): string;

implementation

//-----------对字符串进行加密和解密的极好的函数----------------
Function EncryptionEngine(Src:String; Key:String; Encrypt : Boolean):string;
var
   //idx         :Integer;
   KeyLen      :Integer;
   KeyPos      :Integer;
   offset      :Integer;
   dest        :string;
   SrcPos      :Integer;
   SrcAsc      :Integer;
   TmpSrcAsc   :Integer;
   Range       :Integer;

begin
  try
     if Src='' then
     begin
       Result := '';
       Exit;
     end;

     KeyLen:=Length(Key);
     if KeyLen = 0 then key:='xlinuxx';
     KeyPos:=0;
     //SrcPos:=0;
     //SrcAsc:=0;
     Range:=256;
     if Encrypt then
     begin
          Randomize;
          offset:=Random(Range);
          dest:=format('%1.2x',[offset]);
          for SrcPos := 1 to Length(Src) do
          begin
               SrcAsc:=(Ord(Src[SrcPos]) + offset) MOD 255;
               if KeyPos < KeyLen then KeyPos:= KeyPos + 1 else KeyPos:=1;
               SrcAsc:= SrcAsc xor Ord(Key[KeyPos]);
               dest:=dest + format('%1.2x',[SrcAsc]);
               offset:=SrcAsc;
          end;
     end
     else
     begin
          offset:=StrToInt('$'+ copy(src,1,2));
          SrcPos:=3;
          repeat
                SrcAsc:=StrToInt('$'+ copy(src,SrcPos,2));
                if KeyPos < KeyLen Then KeyPos := KeyPos + 1 else KeyPos := 1;
                TmpSrcAsc := SrcAsc xor Ord(Key[KeyPos]);
                if TmpSrcAsc <= offset then
                     TmpSrcAsc := 255 + TmpSrcAsc - offset
                else
                     TmpSrcAsc := TmpSrcAsc - offset;
                dest := dest + chr(TmpSrcAsc);
                offset:=srcAsc;
                SrcPos:=SrcPos + 2;
          until SrcPos >= Length(Src);
     end;
     Result:=Dest;
  except
    Result := '';
  end;
end;

function   EqLenCrypt(const   Src:   String;   Key:   Word;Encrypt:Boolean):String;
var
    i:Integer;
    b:Byte;
    mc:Char;
    Map,Map0:array[0..255]of   Char;
begin
    for   i:=0   to   255   do
        Map[i]:=Char(i);
    for   i:=127   downto   2   do   //根据Key生成映射表
    begin
        b:=Byte(Key   mod   (i-1))+1;
        mc:=Map[i];
        Map[i]:=Map[b];
        Map[b]:=mc;

        b:=Byte(Key   mod   (i-1))+128;
        mc:=Map[i+127];
        Map[i+127]:=Map[b];
        Map[b]:=mc;
    end;
    if   not   Encrypt   then
    begin   //用于解密的逆映射表
        Move(Map[0],Map0[0],SizeOf(Map));
        for   i:=0   to   255   do
            Map[Byte(Map0[i])]:=Char(i);
    end;
    SetLength(Result,Length(Src));
    for   i:=1   to   Length(Src)   do
        Result[i]:=Map[Byte(Src[i])];
end;

////////////////////////////////////////////
// -----------   加密函数 -----------     //
//                                        //
////////////////////////////////////////////
function EnCrypt(Sour: String):String;
begin
  Result := EncryptionEngine(Sour,XXXKey,True);
  //Result := EqLenCrypt(Sour,110,True);
end;

////////////////////////////////////////////
// -----------   解密函数 -----------     //
//                                        //
////////////////////////////////////////////
function DeCrypt(Sour: String):String;
begin
  Result := EncryptionEngine(Sour,XXXKey,False);
  //Result := EqLenCrypt(Sour,110,False);
end;

{
function EnCrypt(Sour: String):String;
begin
  Result := EncryptStr(Sour,110);
end;

function DeCrypt(Sour: String):String;
begin
  Result := DecryptStr(Sour,110);
end;
}

function EncryptStr(const S: string; Key: Word): string;
var     // 加密
  I : Integer;
begin
  Result := S;
  for I := 1 to Length(S) do
   begin
    Result[I] := Char(Byte(S[I]) xor (Key shr 8));
    Key := (Byte(Result[I]) + Key) * C1Key + C2Key;
   end;
end;

function DecryptStr(const S: string; Key: Word): string;
var    // 解密
  I : Integer;
begin
  Result := S;
  for I := 1 to Length(S) do
   begin
    Result[I] := Char(Byte(S[I]) xor (Key shr 8));
    Key := (Byte(S[I]) + Key) * C1Key + C2Key;
   end;
end;

function SetLocalSysTime(const newTime:TDateTime):Boolean; //设置本地系统时间
var
  MyTime:TsystemTime;
begin
  FillChar(MyTime,sizeof(MyTime),#0);
  MyTime.wYear := StrToInt(FormatDateTime('yyyy', newTime));
  MyTime.wMonth := StrToInt(FormatDateTime('mm', newTime));
  MyTime.wDay := StrToInt(FormatDateTime('dd', newTime));
  MyTime.wHour := StrToInt(FormatDateTime('hh', newTime));
  MyTime.wMinute := StrToInt(FormatDateTime('nn', newTime));
  MyTime.wSecond := StrToInt(FormatDateTime('ss', newTime));
  Result := SetLocalTime(MyTime);
  //Result := SetSystemTime(MyTime);
end;

function NumToUpper(const je: Real): string;
  const s1: String = '零壹贰叁肆伍陆柒捌玖';
        s2: String = '分角元拾佰仟万拾佰仟亿拾佰仟万';
  function StrTran(const S, S1, S2: String): String;
  begin
    Result := StringReplace(S, S1, S2, [rfReplaceAll]);
  end;
var
  s, dx: String;
  i, Len: Integer;
  mmje: Real;
begin
  mmje := je;
  if mmje < 0 then
  begin
    dx := '负';
    mmje := -mmje;
  end;
  s := Format('%.0f', [mmje*100]);
  Len := Length(s);
  for i := 1 to Len do
    dx := dx + Copy(s1, (Ord(s[i]) - Ord('0'))*2 + 1, 2) + Copy(s2, (Len - i)*2 + 1, 2);
    dx := StrTran(StrTran(StrTran(StrTran(StrTran(dx, '零仟', '零'), '零佰', '零'), '零拾', '零'), '零角', '零'), '零分', '整');
    dx := StrTran(StrTran(StrTran(StrTran(StrTran(dx, '零零', '零'), '零零', '零'), '零亿', '亿'), '零万', '万'), '零元', '元');
  if dx = '整' then
    Result := '零元整'
  else
    Result := StrTran(StrTran(dx, '亿万', '亿零'), '零整', '整');
end;

function NumToUpper2(const je: Real): string;    //可以到万亿，并且可以随便扩大范围
const
  cNum: WideString = '零壹贰叁肆伍陆柒捌玖--万仟佰拾亿仟佰拾万仟佰拾元角分';
  cCha:array[0..1, 0..12]of string =
         (( '零元','零拾','零佰','零仟','零万','零亿','亿万','零零零','零零','零万','零亿','亿万','零元'),
          ( '元','零','零','零','万','亿','亿','零','零','万','亿','亿','元'));
var
  i : Integer;
  sNum,sTemp : WideString;
begin
   result :='';
   sNum := Format('%15d',[round(je * 100)]);
   for i := 0 to 14 do
   begin
     stemp := copy(snum,i+1,1);
     if stemp=' ' then continue
     else result := result + cNum[strtoint(stemp)+1] + cNum[i+13];
   end;
   for i:= 0 to 12 do
   Result := StringReplace(Result, cCha[0,i], cCha[1,i], [rfReplaceAll]);
   if pos('零分',result)=0
     then Result := StringReplace(Result, '零角', '零', [rfReplaceAll])
     else Result := StringReplace(Result, '零角','整', [rfReplaceAll]);
   Result := StringReplace(Result, '零分','', [rfReplaceAll]);
end;

function NumToUpper3(const je:Real):string;
const
  sHZ='零壹贰叁肆伍陆柒捌玖分角元拾佰仟万拾佰仟亿';
var
   sje,dx:string;
   j:integer;
begin
   dx:='';
   sje := FloatToStr(Round(je*100));
   for j:=length(sje) downto 1 do
     dx := dx+sHZ[(strtoint(sje[Length(sje)-j+1])+1)*2-1]+
           sHZ[(strtoint(sje[Length(sje)-j+1])+1)*2]+sHZ[(10+j)*2-1]+sHZ[(10+j)*2];
   Result := dx;
end;

end.



