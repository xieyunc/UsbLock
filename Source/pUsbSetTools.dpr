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
  Application.Title := 'USB端口保护工具';
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
