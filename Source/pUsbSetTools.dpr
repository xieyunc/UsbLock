program pUsbSetTools;

uses
  Forms,
  uMain in 'uMain.pas' {frmMain},
  PwdFunUnit in 'PwdFunUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.ShowMainForm := False;
  Application.Title := 'USB�˿ڱ�������';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
