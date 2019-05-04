unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls,Registry, ComCtrls, CnClasses, CnTrayIcon,
  CnAAFont, CnAACtrls, Menus ,IniFiles, ShellAPI, StatusBarEx;

const
  MB_TIMEDOUT = 32000;
type
    TfrmMain = class(TForm)
    CheckBox1: TCheckBox;
    btn_Set: TButton;
    StatusBarEx1: TStatusBarEx;
    CnTrayIcon1: TCnTrayIcon;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    CnAALabel1: TCnAALabel;
    N3: TMenuItem;
    Panel1: TPanel;
    PopupMenu2: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    CnAALinkLabel1: TCnAALinkLabel;
    lbl_Hint: TLabel;
    btn_Uninstall: TButton;
    procedure btn_SetClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure CnTrayIcon1Click(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure N4Click(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure btn_UninstallClick(Sender: TObject);
  private
    { Private declarations }
    function  GetUSBCurState:string;

    function  GetManagerPwd:string;
    function  SetManagerPwd(const sPwd:string):Boolean;
    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
  public
    { Public declarations }
  end;

var
  gbCanClose:Boolean;
  frmMain: TfrmMain;
  //function MessageBoxTimeOut(hWnd: HWND; lpText: PChar; lpCaption: PChar; uType: UINT; wLanguageId: WORD; dwMilliseconds: DWORD): Integer; stdcall; external user32 name 'MessageBoxTimeoutA';

implementation
uses uUsbStateSet,PwdFunUnit,ShutDownComputerUnit;

{$R *.dfm}

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if Self.Showing then
  begin
    CanClose := False;
    Self.Hide;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  gbCanClose := False;
  //if ServiceUninstalled('UsbService') then
  //  ShellExecute(0,'open',PAnsiChar('pUsbSetService'),' /install',nil,SW_HIDE);
  //if ServiceStopped('UsbService') then
  //  ShellExecute(0,'open',PAnsiChar('net'),' start UsbService',nil,SW_HIDE);
  GetUSBCurState;
end;

procedure TfrmMain.FormHide(Sender: TObject);
begin
  GetUSBCurState;
end;

function TfrmMain.GetManagerPwd: string;
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

function TfrmMain.GetUSBCurState:string;
var
  sHint:string;
begin
  //if USBIsStop then
  if ServiceRunning('UsbService') and USBIsStop then
  begin
    sHint := 'USB端口已禁用';
    CheckBox1.Checked := True;
    lbl_Hint.Font.Color := clRed;
  end else
  begin
    sHint := 'USB端口已启用';
    CheckBox1.Checked := False;
    lbl_Hint.Font.Color := clBlue;
  end;

  Result := sHint;
  lbl_Hint.Caption := '(当前状态：'+sHint+')';
  CnTrayIcon1.BalloonHint('系统提示',sHint,btInfo);
end;

procedure TfrmMain.MenuItem1Click(Sender: TObject);
begin
  Self.Hide;
end;

procedure TfrmMain.MenuItem3Click(Sender: TObject);
begin
  Self.Hide;
  Self.Close;
end;

procedure TfrmMain.N1Click(Sender: TObject);
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

procedure TfrmMain.N2Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.N4Click(Sender: TObject);
var
  s:string;
begin
  if not InputQuery('密码管理','请输入新密码 ： ',s) then Exit;
  if s='' then Exit;
  if SetManagerPwd(s) then
    MessageBox(Handle, '管理密码修改成功！请牢记新密码！　', '系统提示', MB_OK
      + MB_ICONINFORMATION + MB_TOPMOST);
end;

function TfrmMain.SetManagerPwd(const sPwd: string): Boolean;
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

procedure TfrmMain.WMDeviceChange(var Msg: TMessage);
var
  myMsg : String;
begin
  Case Msg.WParam of
    32768:
    begin
      myMsg :='系统检测到有U盘插入！';
      if GetLocalUSBDisk<>'' then
        myMsg := myMsg + '盘符为：'+GetLocalUSBDisk+'盘！　';
      CnTrayIcon1.BalloonHint('系统提示',myMsg,btInfo);
    end;
    32772:
    begin
      myMsg :='系统检测到U盘被拔出！';
      CnTrayIcon1.BalloonHint('系统提示',myMsg,btInfo);
    end;
  end;
end;

procedure TfrmMain.btn_UninstallClick(Sender: TObject);
var
  sDir,fn:string;
begin
  if MessageBox(Handle, '确定要卸载USB端口设置服务吗？　', '系统提示',
    MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2 + MB_TOPMOST) = IDNO then
  begin
    Exit;
  end;

  sDir := ExtractFilePath(ParamStr(0));
  fn := ExtractFilePath(ParamStr(0))+'pUsbSetService.exe';
  Screen.Cursor := crHourGlass;
  try
    //SetUSBStart;//禁用USB
    if ServiceRunning('UsbService') then
    begin
      ShellExecute(0,'open',PAnsiChar('net'),' stop UsbService',nil,SW_HIDE);
      Sleep(3000);
    end;

    if not ServiceUninstalled('UsbService') then
    begin
      if FileExists(fn) then
      begin
        ShellExecute(0,'open',PAnsiChar(fn),' /uninstall',PAnsiChar(sDir),SW_HIDE);
        Sleep(3000);
      end else
        MessageBox(Handle, PAnsiChar('服务文件'+fn+'不存在，请检查后重试！　'),
          '系统提示', MB_OK + MB_ICONSTOP + MB_TOPMOST);
    end;
    if ServiceUninstalled('UsbService') then
      MessageBox(Handle, '操作成功，服务系统已成功卸载！　', '系统提示', MB_OK +
        MB_ICONINFORMATION + MB_TOPMOST)
    else
      MessageBox(Handle, '操作失败，服务系统已卸载失败！　', '系统提示', MB_OK +
        MB_ICONERROR + MB_TOPMOST);
  finally
    GetUSBCurState;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmMain.Button4Click(Sender: TObject);
begin
  Close;
end;


procedure TfrmMain.CnTrayIcon1Click(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  GetUSBCurState;
end;

procedure TfrmMain.btn_SetClick(Sender: TObject);
var
  sDir,fn:string;
begin
  sDir := ExtractFileDir(ParamStr(0));
  fn := ExtractFilePath(ParamStr(0))+'pUsbSetService.exe';
  Screen.Cursor := crHourGlass;
  try
    if CheckBox1.Checked=True then //SetUSBStop;//启用USB
    begin
      if ServiceUninstalled('UsbService') then
      begin
        if FileExists(fn) then
        begin
          ShellExecute(0,'open',PAnsiChar(fn),' /install',PAnsiChar(sDir),SW_HIDE);
          Sleep(3000);
        end else
          MessageBox(Handle, PAnsiChar('服务文件'+fn+'不存在，请检查后重试！　'),
            '系统提示', MB_OK + MB_ICONSTOP + MB_TOPMOST);
      end;
      //SetUSBStop;//启用USB
      if ServiceStopped('UsbService') then
      begin
        ShellExecute(0,'open',PAnsiChar('net'),' start UsbService',nil,SW_HIDE);
        Sleep(3000);
      end;
    end else //SetUSBStart;//禁用USB
    begin
      //SetUSBStart;//禁用USB
      if ServiceRunning('UsbService') then
      begin
        ShellExecute(0,'open',PAnsiChar('net'),' stop UsbService',nil,SW_HIDE);
        Sleep(3000);
      end;

      if not ServiceUninstalled('UsbService') then
      begin
        if FileExists(fn) then
        begin
          ShellExecute(0,'open',PAnsiChar(fn),' /uninstall',PAnsiChar(sDir),SW_HIDE);
          Sleep(3000);
        end else
          MessageBox(Handle, PAnsiChar('服务文件'+fn+'不存在，请检查后重试！　'),
            '系统提示', MB_OK + MB_ICONSTOP + MB_TOPMOST);
      end;
    end;

    GetUSBCurState;

    MessageBox(Handle, '操作成功，当前设置功能已生效！　', '系统提示', MB_OK +
      MB_ICONINFORMATION + MB_TOPMOST);
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
