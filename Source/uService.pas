unit uService;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs;

type
  TService1 = class(TService)
    procedure ServiceContinue(Sender: TService; var Continued: Boolean);
    procedure ServiceExecute(Sender: TService);
    procedure ServicePause(Sender: TService; var Paused: Boolean);
    procedure ServiceShutdown(Sender: TService);
    procedure ServiceStart(Sender: TService; var Started: Boolean);
    procedure ServiceStop(Sender: TService; var Stopped: Boolean);
  private
    { Private declarations }
  public
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  Service1: TService1;

implementation
uses uMain;
{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  Service1.Controller(CtrlCode);
end;

function TService1.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TService1.ServiceContinue(Sender: TService; var Continued: Boolean);
begin
  while not Terminated   do
  begin
    Sleep(10);
    ServiceThread.ProcessRequests(False);
  end;
end;

procedure TService1.ServiceExecute(Sender: TService);
begin
  while not Terminated   do
  begin
    Sleep(10);
    ServiceThread.ProcessRequests(False);
  end;
end;

procedure TService1.ServicePause(Sender: TService; var Paused: Boolean);
begin
  Paused := True;
end;

procedure TService1.ServiceShutdown(Sender: TService);
begin
  gbCanClose := True;
  FrmMain.Free;
  Status := csStopped;
  ReportStatus();
end;

procedure TService1.ServiceStart(Sender: TService; var Started: Boolean);
begin
  Started := True;
  Svcmgr.Application.CreateForm(TFrmMain,FrmMain);
  gbCanClose   :=   False;
  FrmMain.Hide;
end;

procedure TService1.ServiceStop(Sender: TService; var Stopped: Boolean);
begin
  Stopped := True;
  gbCanClose := True;
  FrmMain.Free;
end;

end.
