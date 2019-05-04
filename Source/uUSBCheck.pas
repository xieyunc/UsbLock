Unit uUSBCheck;
Interface
Uses
  Windows, SysUtils, Classes, Messages, Forms;

Type
  PDevBroadcastHdr = ^DEV_BROADCAST_HDR;
  DEV_BROADCAST_HDR = Packed Record
    dbch_size: DWORD;
    dbch_devicetype: DWORD;
    dbch_reserved: DWORD;
  End;

  PDevBroadcastDeviceInterface = ^DEV_BROADCAST_DEVICEINTERFACE;
  DEV_BROADCAST_DEVICEINTERFACE = Record
    dbcc_size: DWORD;
    dbcc_devicetype: DWORD;
    dbcc_reserved: DWORD;
    dbcc_classguid: TGUID;
    dbcc_name: short;
  End;

  TUSB = Class(TObject)
  private
    FWindowHandle: HWND;
    FOnUSBArrival: TNotifyEvent;
    FOnUSBRemove: TNotifyEvent;
    Procedure WndProc(Var Msg: TMessage);
    Function USBRegister: Boolean;
  protected
    Procedure WMDeviceChange(Var Msg: TMessage); dynamic;
  public
    Constructor Create;
    Destructor Destroy; override;
    Property OnUSBArrival: TNotifyEvent read FOnUSBArrival write FOnUSBArrival;
    Property OnUSBRemove: TNotifyEvent read FOnUSBRemove write FOnUSBRemove;
  End;
Const
  GUID_DEVINTERFACE_USB_DEVICE: TGUID = '{A5DCBF10-6530-11D2-901F-00C04FB951ED}';
  DBT_DEVICEARRIVAL = $8000; // system detected a new device
  DBT_DEVICEREMOVECOMPLETE = $8004; // device is gone
  DBT_DEVTYP_DEVICEINTERFACE = $00000005; // device interface class
Var
  USB: TUSB;

Implementation

{ TUSB }
Constructor TUSB.Create;
Begin
  FWindowHandle := AllocateHWnd(WndProc);
  USBRegister;
End;
Destructor TUSB.Destroy;
Begin
  DeallocateHWnd(FWindowHandle);
  Inherited Destroy;
End;

Function TUSB.USBRegister: Boolean;
Var
  dbi: DEV_BROADCAST_DEVICEINTERFACE;
  Size: Integer;
  r: Pointer;
Begin
  Result := False;
  Size := Sizeof(DEV_BROADCAST_DEVICEINTERFACE);
  ZeroMemory(@dbi, Size);
  dbi.dbcc_size := Size;
  dbi.dbcc_devicetype := DBT_DEVTYP_DEVICEINTERFACE;
  dbi.dbcc_reserved := 0;
  dbi.dbcc_classguid := GUID_DEVINTERFACE_USB_DEVICE;
  dbi.dbcc_name := 0;
  r := RegisterDeviceNotification(FWindowHandle, @dbi, DEVICE_NOTIFY_WINDOW_HANDLE);
  If Assigned(r) Then
    Result := True;
End;

Procedure TUSB.WMDeviceChange(Var Msg: TMessage);
Var
  devType: Integer;
  Datos: PDevBroadcastHdr;
Begin
  If (Msg.wParam = DBT_DEVICEARRIVAL) Or (Msg.wParam = DBT_DEVICEREMOVECOMPLETE) Then Begin
    Datos := PDevBroadcastHdr(Msg.lParam);
    devType := Datos^.dbch_devicetype;
    If devType = DBT_DEVTYP_DEVICEINTERFACE Then Begin // USB Device
      If Msg.wParam = DBT_DEVICEARRIVAL Then Begin
        If Assigned(FOnUSBArrival) Then
          FOnUSBArrival(Self);
      End
      Else Begin
        If Assigned(FOnUSBRemove) Then
          FOnUSBRemove(Self);
      End;
    End;
  End;
End;

Procedure TUSB.WndProc(Var Msg: TMessage);
Begin
  If (Msg.Msg = WM_DEVICECHANGE) Then Begin
    Try
      WMDeviceChange(Msg);
    Except
      Application.HandleException(Self);
    End;
  End
  Else
    Msg.Result := DefWindowProc(FWindowHandle, Msg.Msg, Msg.wParam, Msg.lParam);
End;

Initialization
  If Not Assigned(USB) Then
    USB := TUSB.Create;

Finalization
  FreeAndNil(USB);

End.
