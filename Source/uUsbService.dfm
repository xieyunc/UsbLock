object UsbService: TUsbService
  OldCreateOrder = False
  DisplayName = 'USB'#35774#22791#35774#32622#24037#20855
  OnContinue = ServiceContinue
  OnExecute = ServiceExecute
  OnPause = ServicePause
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 179
  Width = 299
  object tmr1: TTimer
    Enabled = False
    Interval = 3000
    OnTimer = tmr1Timer
    Left = 80
    Top = 32
  end
end
