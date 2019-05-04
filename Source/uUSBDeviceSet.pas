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
function GetUSBStartState:Integer; //获取USB禁用/启用的状态
//3:启用  4:禁用
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

function GetUSBWriteProtectState:Integer; //获取USB写保护状态
//0:可读可写  1:只读权限
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
//iState 0:USB读写权限   1:USB只读权限
//       3:启用USB设备   4:禁用USB设备
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
  sReg := '\SYSTEM\CurrentControlSet\Services\USBSTOR'; //禁止、启用USB

  iKeyValue := iState;

  //修改 _LOCAL_MACHINE;
  //iKeyValue 3:启用USB设备   4:禁用USB设备
  Reg.RootKey :=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey(sReg,True) then
    Reg.WriteInteger(sKey,iKeyValue);

  //MessageBox(0, '设置成功，请放心使用！　', '系统提示', MB_OK +
  //  MB_ICONINFORMATION + MB_TOPMOST);
  Result := True;
  GetUSBStartState;
end;

function SetUSBWriteProtectState(const iState:Integer):Boolean;
//iState 0:USB读写权限   1:USB只读权限
//       3:启用USB设备   4:禁用USB设备
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
  sReg := '\SYSTEM\CurrentControlset\Control\StorageDevicePolicies';//写保护

  iKeyValue := iState;

  //修改 _LOCAL_MACHINE;
  //iKeyValue 0:USB读写权限   1:USB只读权限
  Reg.RootKey :=HKEY_LOCAL_MACHINE;
  if Reg.OpenKey(sReg,True) then
    Reg.WriteInteger(sKey,iKeyValue);

  Result := True;
  GetUSBStartState;
end;

function SetUSBStop:Boolean; //停用USB设备
begin
  Result := SetUSBStartState(4);
end;

function SetUSBStart:Boolean; //启用USB设备
begin
  Result := SetUSBStartState(3);
end;

function SetUSBReadOnly:Boolean; //设置USB只读
begin
  Result := SetUSBWriteProtectState(1);
end;

function SetUSBReadWrite:Boolean; //设置USB读写
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
  SetUSBStop;//禁用USB
  if GetLocalUSBDisk<>'' then
  begin
    sMsg :='系统检测到有U盘插入！';
    sMsg := sMsg + '盘符为：'+GetLocalUSBDisk+'盘！　';
    CnTrayIcon1.BalloonHint('系统提示',sMsg,btInfo);
    tmr1.Enabled := True;
  end else
    tmr1.Enabled := False;
end;

procedure TUSBDeviceSet.FormShow(Sender: TObject);
begin
  StatusBar1.SimpleText := 'USB当前状态：'+GetUSBCurState;
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
      //showmessage(str_temp+'盘为u盘') ;
      //listbox1.items.add(str_temp) ;
    end;
  end;
end;

function TUSBDeviceSet.GetManagerPwd: string;
var
  fn:string;
  sPath: array [0..255] of Char;
begin
  GetWindowsDirectory(@sPath,40);  //得到Windows的系统目录
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
    sHint := 'USB设备已禁用';
    CheckBox1.Checked := True;
  end else
  begin
    sHint := 'USB设备已启用';
    CheckBox1.Checked := False;
  end;

  if GetUSBWriteProtectState=1 then
  begin
    sHint := sHint+'，权限为只读！';
    CheckBox2.Checked := True;
  end else
  begin
    sHint := sHint+'，权限为读写！';
    CheckBox2.Checked := False;
  end;
  Result := sHint;
  CnTrayIcon1.BalloonHint('系统提示',sHint,btInfo);
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
  if not InputQuery('身份确认','输入管理密码 ： ',s) then Exit;
  if s<>GetManagerPwd then
  begin
    Application.MessageBox('您没有修改权限！','警告',MB_OK+MB_ICONSTOP);
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
  if not InputQuery('密码管理','请输入新密码 ： ',s) then Exit;
  if s='' then Exit;
  if SetManagerPwd(s) then
    MessageBox(Handle, '管理密码修改成功！请牢记新密码！　', '系统提示', MB_OK
      + MB_ICONINFORMATION + MB_TOPMOST);
end;

procedure TUSBDeviceSet.ProcessUSB;
begin
  try
    tmr1.Enabled := False;
    if (GetUSBStartState=4) and (GetLocalUSBDisk<>'') then //如果禁用U盘，且已打开U盘
    begin
      MessageBoxTimeOut(Application.Handle,'系统被设置为不允许使用U盘！3秒钟后计算机将关机！　',
        '系统提示', MB_OK + MB_ICONWARNING + MB_TOPMOST,0,3000);
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
  GetWindowsDirectory(@sPath,40);  //得到Windows的系统目录
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
      myMsg :='系统检测到有U盘插入！';
      if GetLocalUSBDisk<>'' then
        myMsg := myMsg + '盘符为：'+GetLocalUSBDisk+'盘！　';
      CnTrayIcon1.BalloonHint('系统提示',myMsg,btInfo);
    end;
    32772:
    begin
      tmr1.Enabled := False;
      myMsg :='系统检测到U盘被拔出！';
      CnTrayIcon1.BalloonHint('系统提示',myMsg,btInfo);
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
  if not InputQuery('身份确认','输入管理密码 ： ',s) then Exit;
  if s<>GetManagerPwd then
  begin
    Application.MessageBox('您没有修改权限！','警告',MB_OK+MB_ICONSTOP);
    Exit;
  end;
}

  if CheckBox1.Checked=True then
    SetUSBStop//禁用USB
  else
    SetUSBStart;//启用USB
  if CheckBox2.Checked=True then
    SetUSBReadOnly //USB写保护
  else
    SetUSBReadWrite;//解锁USB写保护

  StatusBar1.SimpleText := 'USB当前状态：'+GetUSBCurState;

  MessageBox(Handle, '设置成功，请放心使用！　', '系统提示', MB_OK +
    MB_ICONINFORMATION + MB_TOPMOST);

  if GetLocalUSBDisk<>'' then
  begin
    sMsg :='系统检测到有U盘插入！';
    sMsg := sMsg + '盘符为：'+GetLocalUSBDisk+'盘！　';
    ProcessUSB;
  end;
end;

end.
