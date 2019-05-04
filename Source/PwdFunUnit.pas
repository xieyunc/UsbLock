unit PwdFunUnit;

interface

uses
  SysUtils,Windows,Dialogs,Forms;

const
  C1Key = 12674; //   C1 = 52845;
  C2Key = 35891; //   C2 = 22719;
  XXXKey = 'xlinuxx';  //

//-----------���ַ������м��ܺͽ��ܵļ��õĺ���----------------
Function EncryptionEngine(Src:String; Key:String; Encrypt : Boolean):string;
function EnCrypt(Sour: String):String; //����һ��������������,����
function DeCrypt(Sour: String):String; //����

function SetLocalSysTime(const newTime:TDateTime):Boolean; //���ñ���ϵͳʱ��

function EncryptStr(const S: string; Key: Word): string; //��������������д���е��ã�������
function DecryptStr(const S: string; Key: Word): string;

function NumToUpper (const je: Real): string;   //Сд���ת��Ϊ��д���
function NumToUpper2(const je: Real): string;
function NumToUpper3(const je: Real): string;

implementation

//-----------���ַ������м��ܺͽ��ܵļ��õĺ���----------------
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
    for   i:=127   downto   2   do   //����Key����ӳ���
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
    begin   //���ڽ��ܵ���ӳ���
        Move(Map[0],Map0[0],SizeOf(Map));
        for   i:=0   to   255   do
            Map[Byte(Map0[i])]:=Char(i);
    end;
    SetLength(Result,Length(Src));
    for   i:=1   to   Length(Src)   do
        Result[i]:=Map[Byte(Src[i])];
end;

////////////////////////////////////////////
// -----------   ���ܺ��� -----------     //
//                                        //
////////////////////////////////////////////
function EnCrypt(Sour: String):String;
begin
  Result := EncryptionEngine(Sour,XXXKey,True);
  //Result := EqLenCrypt(Sour,110,True);
end;

////////////////////////////////////////////
// -----------   ���ܺ��� -----------     //
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
var     // ����
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
var    // ����
  I : Integer;
begin
  Result := S;
  for I := 1 to Length(S) do
   begin
    Result[I] := Char(Byte(S[I]) xor (Key shr 8));
    Key := (Byte(S[I]) + Key) * C1Key + C2Key;
   end;
end;

function SetLocalSysTime(const newTime:TDateTime):Boolean; //���ñ���ϵͳʱ��
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
  const s1: String = '��Ҽ��������½��ƾ�';
        s2: String = '�ֽ�Ԫʰ��Ǫ��ʰ��Ǫ��ʰ��Ǫ��';
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
    dx := '��';
    mmje := -mmje;
  end;
  s := Format('%.0f', [mmje*100]);
  Len := Length(s);
  for i := 1 to Len do
    dx := dx + Copy(s1, (Ord(s[i]) - Ord('0'))*2 + 1, 2) + Copy(s2, (Len - i)*2 + 1, 2);
    dx := StrTran(StrTran(StrTran(StrTran(StrTran(dx, '��Ǫ', '��'), '���', '��'), '��ʰ', '��'), '���', '��'), '���', '��');
    dx := StrTran(StrTran(StrTran(StrTran(StrTran(dx, '����', '��'), '����', '��'), '����', '��'), '����', '��'), '��Ԫ', 'Ԫ');
  if dx = '��' then
    Result := '��Ԫ��'
  else
    Result := StrTran(StrTran(dx, '����', '����'), '����', '��');
end;

function NumToUpper2(const je: Real): string;    //���Ե����ڣ����ҿ����������Χ
const
  cNum: WideString = '��Ҽ��������½��ƾ�--��Ǫ��ʰ��Ǫ��ʰ��Ǫ��ʰԪ�Ƿ�';
  cCha:array[0..1, 0..12]of string =
         (( '��Ԫ','��ʰ','���','��Ǫ','����','����','����','������','����','����','����','����','��Ԫ'),
          ( 'Ԫ','��','��','��','��','��','��','��','��','��','��','��','Ԫ'));
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
   if pos('���',result)=0
     then Result := StringReplace(Result, '���', '��', [rfReplaceAll])
     else Result := StringReplace(Result, '���','��', [rfReplaceAll]);
   Result := StringReplace(Result, '���','', [rfReplaceAll]);
end;

function NumToUpper3(const je:Real):string;
const
  sHZ='��Ҽ��������½��ƾ��ֽ�Ԫʰ��Ǫ��ʰ��Ǫ��';
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



