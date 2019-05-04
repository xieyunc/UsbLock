unit uUsbService;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs,
  ExtCtrls, Registry, IniFiles;

type
  TUsbService = class(TService)
    tmr1: TTimer;
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceExecute(Sender: TService);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
    procedure WMDeviceChange(var Msg: TMessage); message WM_DEVICECHANGE;
    procedure ProcessUSB;
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  UsbService: TUsbService;
  function MessageBoxTimeOut(hWnd: HWND; lpText: PChar; lpCaption: PChar; uType: UINT; wLanguageId: WORD; dwMilliseconds: DWORD): Integer; stdcall; external user32 name 'MessageBoxTimeoutA';

implementation
uses ShutDownComputerUnit,uUsbStateSet;
{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  UsbService.Controller(CtrlCode);
end;

function TUsbService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TUsbService.ProcessUSB;
begin
  try
    tmr1.Enabled := False;
    if UsbIsStop and (GetLocalUSBDisk<>'') then //�������U�̣����Ѵ�U��
    begin
      //MessageBoxTimeOut(0,'ϵͳ������Ϊ������ʹ��U�̣�3���Ӻ��������ػ�����',
      //  'ϵͳ��ʾ', MB_OK + MB_ICONWARNING + MB_TOPMOST,0,3000);
      //ShowMessage('ϵͳ������Ϊ������ʹ��U�̣�3���Ӻ��������ػ�����');
      SaveLog('ProcessUSB:׼���ػ�');
      ShutDownComputer;
    end;
  finally
    tmr1.Enabled := True;
  end;

end;

procedure TUsbService.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
  while not Terminated   do
  begin
    Sleep(10);
    ServiceThread.ProcessRequests(False);
  end;
end;

procedure TUsbService.ServiceExecute(Sender: TService);
begin
  while not Terminated   do
  begin
    Sleep(10);
    ServiceThread.ProcessRequests(False);
  end;
end;

procedure TUsbService.ServicePause(Sender: TService; var Paused: Boolean);
begin
  Paused := True;
end;

procedure TUsbService.ServiceShutdown(Sender: TService);
begin
  //gbCanClose := True;
  //FrmMain.Free;
  Status := csStopped;
  ReportStatus();
end;

procedure TUsbService.ServiceStart(Sender: TService; var Started: Boolean);
begin
  Started := True;
  SetUSBStop;
  //tmr1.Enabled := True;
  ProcessUSB;
  //Svcmgr.Application.CreateForm(TFrmMain,FrmMain);
  //Application.CreateForm(TFrmMain,FrmMain);
  //gbCanClose := False;
  //frmMain.Hide;
end;

procedure TUsbService.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  Stopped := True;
  SetUSBStart;
  tmr1.Enabled := False;
  //gbCanClose := True;
  //FrmMain.Free;
end;

procedure TUsbService.tmr1Timer(Sender: TObject);
begin
  ProcessUSB;
end;

procedure TUsbService.WMDeviceChange(var Msg: TMessage);
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
      //CnTrayIcon1.BalloonHint('ϵͳ��ʾ',myMsg,btInfo);
    end;
    32772:
    begin
      tmr1.Enabled := False;
      myMsg :='ϵͳ��⵽U�̱��γ���';
      //CnTrayIcon1.BalloonHint('ϵͳ��ʾ',myMsg,btInfo);
    end;
  end;
  if myMsg<>'' then
    SaveLog(myMsg);
end;

end.
