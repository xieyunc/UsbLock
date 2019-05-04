unit uUSBDeviceSet;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,Registry, ComCtrls, CnClasses, CnTrayIcon,
  CnAAFont, CnAACtrls, Menus ,IniFiles;

const
  MB_TIMEDOUT = 32000;
type
    TUSBDeviceSet = class(TForm)
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    btn_Set: TButton;
    StatusBar1: TStatusBar;
    CnTrayIcon1: TCnTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    CnAALabel1: TCnAALabel;
    N3: TMenuItem;
    CnAALinkLabel1: TCnAALinkLabel;
    Panel1: TPanel;
    PopupMenu2: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    tmr1: TTimer;
    procedure btn_SetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CnTrayIcon1Click(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
    function  GetUSBCurState:string;

    function  GetManagerPwd:string;
    function  SetManagerPwd(const sPwd:string):Boolean;
    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    function  GetLocalUSBDisk:string;
    procedure ProcessUSB;
  public
    { Public declarations }
  end;

var
  USBDeviceSet: TUSBDeviceSet;
  function MessageBoxTimeOut(hWnd: HWND; lpText: PChar; lpCaption: PChar; uType: UINT; wLanguageId: WORD; dwMilliseconds: DWORD): Integer; stdcall; external user32 name 'MessageBoxTimeoutA';

implementation
uses PwdFunUnit,ShutDownComputerUnit;

{$R *.dfm}
function GetUSBStartState:Integer; //��ȡUSB����/���õ�״̬
//3:����  4:����
var
  Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  with Reg do
  begin
    RootKey:=HKEY_LOCAL_MACHINE;
    if OpenKey('\SYSTEM\CurrentControlSet\Services\USBSTOR',True) and ValueExists('Start') then
    begin
      Result := ReadInteger('Start');
    end;
    Reg.CloseKey;
    Reg.Free;
  end;
end;

function GetUSBWriteProtectState:Integer; //��ȡUSBд����״̬
//0:�ɶ���д  1:ֻ��Ȩ��
var
  Reg:TRegistry;
begin
  Reg:=TRegistry.Create;
  with Reg do
  begin
    RootKey:=HKEY_LOCAL_MACHINE;
    if OpenKey('\SYSTEM\CurrentControlset\control\StorageDevicePolicies',True) and ValueExists('WriteProtect') then
    begin
      Result := ReadInteger('WriteProtect');
    end;
    Reg.CloseKey;
    Reg.Free;
  end;
end;

function SetUSBStartState(const iState:Integer):Boolean;
//iState 0:USB��дȨ��   1:USBֻ��Ȩ��
//       3:����USB�豸   4:����USB�豸
var
  Reg: TRegistry;
  sKey,sReg:string;
  iKeyValue:Integer;
begin
  Reg := TRegistry.Create;
  if not Reg.OpenKey('\SYSTEM\CurrentControlset\Control\StorageDevicePolicies',False) then
  begin
    if Reg.OpenKey('\SYSTEM\CurrentControlset\Control', True) then
    begin
      Reg.CreateKey('StorageDevicePolicies');
    end;
  end;
  Reg := TRegistry.Create;
  sKey := 'Start';
  sReg := '\SYSTEM\CurrentControlSet\Services\USBSTOR'; //��ֹ������USB

  iKeyValue := iState;

  //�޸� _LOCAL_MACHINE;
  //iKeyValue 3:����USB�豸   4:����USB�豸
  Reg.RootKey :=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey(sReg,True) then
    Reg.WriteInteger(sKey,iKeyValue);

  //MessageBox(0, '���óɹ��������ʹ�ã���', 'ϵͳ��ʾ', MB_OK +
  //  MB_ICONINFORMATION + MB_TOPMOST);
  Result := True;
  GetUSBStartState;
end;

function SetUSBWriteProtectState(const iState:Integer):Boolean;
//iState 0:USB��дȨ��   1:USBֻ��Ȩ��
//       3:����USB�豸   4:����USB�豸
var
  Reg: TRegistry;
  sKey,sReg:string;
  iKeyValue:Integer;
begin
  Reg := TRegistry.Create;
  if not Reg.OpenKey('\SYSTEM\CurrentControlset\Control\StorageDevicePolicies',False) then
  begin
    if Reg.OpenKey('\SYSTEM\CurrentControlset\Control', True) then
    begin
      Reg.CreateKey('StorageDevicePolicies');
    end;
  end;
  Reg := TRegistry.Create;
  sKey := 'WriteProtect';
  sReg := '\SYSTEM\CurrentControlset\Control\StorageDevicePolicies';//д����

  iKeyValue := iState;

  //�޸� _LOCAL_MACHINE;
  //iKeyValue 0:USB��дȨ��   1:USBֻ��Ȩ��
  Reg.RootKey :=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey(sReg,True) then
    Reg.WriteInteger(sKey,iKeyValue);

  Result := True;
  GetUSBStartState;
end;

function SetUSBStop:Boolean; //ͣ��USB�豸
begin
  Result := SetUSBStartState(4);
end;

function SetUSBStart:Boolean; //����USB�豸
begin
  Result := SetUSBStartState(3);
end;

function SetUSBReadOnly:Boolean; //����USBֻ��
begin
  Result := SetUSBWriteProtectState(1);
end;

function SetUSBReadWrite:Boolean; //����USB��д
begin
  Result := SetUSBWriteProtectState(0);
end;


procedure TUSBDeviceSet.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Self.Showing then
  begin
    CanClose := False;
    Self.Hide;
  end;
end;

procedure TUSBDeviceSet.FormCreate(Sender: TObject);
var
  sMsg:string;
begin
  SetUSBStop;//����USB
  if GetLocalUSBDisk<>'' then
  begin
    sMsg :='ϵͳ��⵽��U�̲��룡';
    sMsg := sMsg + '�̷�Ϊ��'+GetLocalUSBDisk+'�̣���';
    CnTrayIcon1.BalloonHint('ϵͳ��ʾ',sMsg,btInfo);
    tmr1.Enabled := True;
  end else
    tmr1.Enabled := False;
end;

procedure TUSBDeviceSet.FormShow(Sender: TObject);
begin
  StatusBar1.SimpleText := 'USB��ǰ״̬��'+GetUSBCurState;
end;

function TUSBDeviceSet.GetLocalUSBDisk: string;
var
  buf:array [0..max_path-1] of char;
  m_result:integer;
  i:integer;
  str_temp:string;
begin
  Result := '';
  m_result:=getlogicaldrivestrings(max_path,buf);
  for i:=0 to (m_result div 4) do
  begin
    str_temp:=string(buf[i*4]+buf[i*4+1]+buf[i*4+2]);
    if getdrivetype(pchar(str_temp)) = drive_removable then
    begin
      Result := str_temp;
      //showmessage(str_temp+'��Ϊu��') ;
      //listbox1.items.add(str_temp) ;
    end;
  end;
end;

function TUSBDeviceSet.GetManagerPwd: string;
var
  fn:string;
  sPath: array [0..255] of Char;
begin
  GetWindowsDirectory(@sPath,40);  //�õ�Windows��ϵͳĿ¼
  fn := sPath+'USBSet.ini';
  with TIniFile.Create(fn) do
  begin
    Result := ReadString('USBSET','PASSWORD','');
    if Result = '' then
      Result := 'jszx_2011'
    else
      Result := DeCrypt(Result);
    Free;
  end;
end;

function TUSBDeviceSet.GetUSBCurState:string;
var
  sHint:string;
begin
  if GetUSBStartState=4 then
  begin
    sHint := 'USB�豸�ѽ���';
    CheckBox1.Checked := True;
  end else
  begin
    sHint := 'USB�豸������';
    CheckBox1.Checked := False;
  end;

  if GetUSBWriteProtectState=1 then
  begin
    sHint := sHint+'��Ȩ��Ϊֻ����';
    CheckBox2.Checked := True;
  end else
  begin
    sHint := sHint+'��Ȩ��Ϊ��д��';
    CheckBox2.Checked := False;
  end;
  Result := sHint;
  CnTrayIcon1.BalloonHint('ϵͳ��ʾ',sHint,btInfo);
end;

procedure TUSBDeviceSet.MenuItem1Click(Sender: TObject);
begin
  Self.Hide;
end;

procedure TUSBDeviceSet.MenuItem3Click(Sender: TObject);
begin
  Self.Hide;
  Self.Close;
end;

procedure TUSBDeviceSet.N1Click(Sender: TObject);
var
  s:string;
begin
  if not InputQuery('���ȷ��','����������� �� ',s) then Exit;
  if s<>GetManagerPwd then
  begin
    Application.MessageBox('��û���޸�Ȩ�ޣ�','����',MB_OK+MB_ICONSTOP);
    Exit;
  end else
    Self.Show;
end;

procedure TUSBDeviceSet.N2Click(Sender: TObject);
begin
  Close;
end;

procedure TUSBDeviceSet.N4Click(Sender: TObject);
var
  s:string;
begin
  if not InputQuery('�������','������������ �� ',s) then Exit;
  if s='' then Exit;
  if SetManagerPwd(s) then
    MessageBox(Handle, '���������޸ĳɹ������μ������룡��', 'ϵͳ��ʾ', MB_OK
      + MB_ICONINFORMATION + MB_TOPMOST);
end;

procedure TUSBDeviceSet.ProcessUSB;
begin
  try
    tmr1.Enabled := False;
    if (GetUSBStartState=4) and (GetLocalUSBDisk<>'') then //�������U�̣����Ѵ�U��
    begin
      MessageBoxTimeOut(Application.Handle,'ϵͳ������Ϊ������ʹ��U�̣�3���Ӻ��������ػ�����',
        'ϵͳ��ʾ', MB_OK + MB_ICONWARNING + MB_TOPMOST,0,3000);
      ShutDownComputer;
    end;
  finally
    tmr1.Enabled := True;
  end;
end;

function TUSBDeviceSet.SetManagerPwd(const sPwd: string): Boolean;
var
  fn:string;
  sPath: array [0..255] of Char;
begin
  GetWindowsDirectory(@sPath,40);  //�õ�Windows��ϵͳĿ¼
  fn := sPath+'USBSet.ini';
  with TIniFile.Create(fn) do
  begin
    WriteString('USBSET','PASSWORD',EnCrypt(sPwd));
    Result := True;
    Free;
  end;
end;

procedure TUSBDeviceSet.tmr1Timer(Sender: TObject);
begin
  ProcessUSB;
end;

procedure TUSBDeviceSet.WMDeviceChange(var Msg: TMessage);
var
  myMsg : String;
begin
  Case Msg.WParam of
    32768:
    begin
      tmr1.Enabled := True;
      myMsg :='ϵͳ��⵽��U�̲��룡';
      if GetLocalUSBDisk<>'' then
        myMsg := myMsg + '�̷�Ϊ��'+GetLocalUSBDisk+'�̣���';
      CnTrayIcon1.BalloonHint('ϵͳ��ʾ',myMsg,btInfo);
    end;
    32772:
    begin
      tmr1.Enabled := False;
      myMsg :='ϵͳ��⵽U�̱��γ���';
      CnTrayIcon1.BalloonHint('ϵͳ��ʾ',myMsg,btInfo);
    end;
  end;
end;

procedure TUSBDeviceSet.Button4Click(Sender: TObject);
begin
  Close;
end;


procedure TUSBDeviceSet.CnTrayIcon1Click(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  GetUSBCurState;
end;

procedure TUSBDeviceSet.btn_SetClick(Sender: TObject);
var
  Reg: TRegistry;
  s,s1,s2,reg1,reg2,sMsg:string;
begin
{
  if not InputQuery('���ȷ��','����������� �� ',s) then Exit;
  if s<>GetManagerPwd then
  begin
    Application.MessageBox('��û���޸�Ȩ�ޣ�','����',MB_OK+MB_ICONSTOP);
    Exit;
  end;
}

  if CheckBox1.Checked=True then
    SetUSBStop//����USB
  else
    SetUSBStart;//����USB
  if CheckBox2.Checked=True then
    SetUSBReadOnly //USBд����
  else
    SetUSBReadWrite;//����USBд����

  StatusBar1.SimpleText := 'USB��ǰ״̬��'+GetUSBCurState;

  MessageBox(Handle, '���óɹ��������ʹ�ã���', 'ϵͳ��ʾ', MB_OK +
    MB_ICONINFORMATION + MB_TOPMOST);

  if GetLocalUSBDisk<>'' then
  begin
    sMsg :='ϵͳ��⵽��U�̲��룡';
    sMsg := sMsg + '�̷�Ϊ��'+GetLocalUSBDisk+'�̣���';
    ProcessUSB;
  end;
end;

end.
