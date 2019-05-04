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

function TfrmMain.GetUSBCurState:string;
var
  sHint:string;
begin
  //if USBIsStop then
  if ServiceRunning('UsbService') and USBIsStop then
  begin
    sHint := 'USB�˿��ѽ���';
    CheckBox1.Checked := True;
    lbl_Hint.Font.Color := clRed;
  end else
  begin
    sHint := 'USB�˿�������';
    CheckBox1.Checked := False;
    lbl_Hint.Font.Color := clBlue;
  end;

  Result := sHint;
  lbl_Hint.Caption := '(��ǰ״̬��'+sHint+')';
  CnTrayIcon1.BalloonHint('ϵͳ��ʾ',sHint,btInfo);
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
  if not InputQuery('���ȷ��','����������� �� ',s) then Exit;
  if s<>GetManagerPwd then
  begin
    Application.MessageBox('��û���޸�Ȩ�ޣ�','����',MB_OK+MB_ICONSTOP);
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
  if not InputQuery('�������','������������ �� ',s) then Exit;
  if s='' then Exit;
  if SetManagerPwd(s) then
    MessageBox(Handle, '���������޸ĳɹ������μ������룡��', 'ϵͳ��ʾ', MB_OK
      + MB_ICONINFORMATION + MB_TOPMOST);
end;

function TfrmMain.SetManagerPwd(const sPwd: string): Boolean;
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

procedure TfrmMain.WMDeviceChange(var Msg: TMessage);
var
  myMsg : String;
begin
  Case Msg.WParam of
    32768:
    begin
      myMsg :='ϵͳ��⵽��U�̲��룡';
      if GetLocalUSBDisk<>'' then
        myMsg := myMsg + '�̷�Ϊ��'+GetLocalUSBDisk+'�̣���';
      CnTrayIcon1.BalloonHint('ϵͳ��ʾ',myMsg,btInfo);
    end;
    32772:
    begin
      myMsg :='ϵͳ��⵽U�̱��γ���';
      CnTrayIcon1.BalloonHint('ϵͳ��ʾ',myMsg,btInfo);
    end;
  end;
end;

procedure TfrmMain.btn_UninstallClick(Sender: TObject);
var
  sDir,fn:string;
begin
  if MessageBox(Handle, 'ȷ��Ҫж��USB�˿����÷����𣿡�', 'ϵͳ��ʾ',
    MB_YESNO + MB_ICONQUESTION + MB_DEFBUTTON2 + MB_TOPMOST) = IDNO then
  begin
    Exit;
  end;

  sDir := ExtractFilePath(ParamStr(0));
  fn := ExtractFilePath(ParamStr(0))+'pUsbSetService.exe';
  Screen.Cursor := crHourGlass;
  try
    //SetUSBStart;//����USB
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
        MessageBox(Handle, PAnsiChar('�����ļ�'+fn+'�����ڣ���������ԣ���'),
          'ϵͳ��ʾ', MB_OK + MB_ICONSTOP + MB_TOPMOST);
    end;
    if ServiceUninstalled('UsbService') then
      MessageBox(Handle, '�����ɹ�������ϵͳ�ѳɹ�ж�أ���', 'ϵͳ��ʾ', MB_OK +
        MB_ICONINFORMATION + MB_TOPMOST)
    else
      MessageBox(Handle, '����ʧ�ܣ�����ϵͳ��ж��ʧ�ܣ���', 'ϵͳ��ʾ', MB_OK +
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
    if CheckBox1.Checked=True then //SetUSBStop;//����USB
    begin
      if ServiceUninstalled('UsbService') then
      begin
        if FileExists(fn) then
        begin
          ShellExecute(0,'open',PAnsiChar(fn),' /install',PAnsiChar(sDir),SW_HIDE);
          Sleep(3000);
        end else
          MessageBox(Handle, PAnsiChar('�����ļ�'+fn+'�����ڣ���������ԣ���'),
            'ϵͳ��ʾ', MB_OK + MB_ICONSTOP + MB_TOPMOST);
      end;
      //SetUSBStop;//����USB
      if ServiceStopped('UsbService') then
      begin
        ShellExecute(0,'open',PAnsiChar('net'),' start UsbService',nil,SW_HIDE);
        Sleep(3000);
      end;
    end else //SetUSBStart;//����USB
    begin
      //SetUSBStart;//����USB
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
          MessageBox(Handle, PAnsiChar('�����ļ�'+fn+'�����ڣ���������ԣ���'),
            'ϵͳ��ʾ', MB_OK + MB_ICONSTOP + MB_TOPMOST);
      end;
    end;

    GetUSBCurState;

    MessageBox(Handle, '�����ɹ�����ǰ���ù�������Ч����', 'ϵͳ��ʾ', MB_OK +
      MB_ICONINFORMATION + MB_TOPMOST);
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
