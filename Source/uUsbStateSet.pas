unit uUsbStateSet;

interface
  uses SysUtils,Registry,Windows, WinSvc,IniFiles,Classes;

  function SetUSBStop:Boolean; //ͣ��USB�豸
  function SetUSBStart:Boolean; //����USB�豸
  function USBIsStop:Boolean;   //USB�豸�Ƿ�ͣ��״̬
  function GetLocalUSBDisk:string;
  {�ж�ĳ�����Ƿ�װ��δ��װ����true���Ѱ�װ����false}
  function ServiceUninstalled(sService : string ) : boolean;
  {�ж�ĳ�����Ƿ���������������true��δ��������false}
  function ServiceRunning(sService : string ) : boolean;
  {�ж�ĳ�����Ƿ�ֹͣ��ֹͣ����true��δֹͣ����false}
  function ServiceStopped(sService : string ) : boolean;
  procedure SaveLog(const sValue:string);

implementation
uses PwdFunUnit;

procedure SaveLog(const sValue:string);
//3:����  4:����
var
  fn:string;
  sPath: array [0..255] of Char;
  //sPath :string;
  sList:TStrings;
begin
  GetWindowsDirectory(@sPath,40);  //�õ�Windows��ϵͳĿ¼
  fn := sPath+'USBSet.Log';
  sList := TStringList.Create;
  try
    if FileExists(fn) then
      sList.LoadFromFile(fn);
      
    if sList.Count>1000 then
      sList.Clear;
    sList.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss',now)+' '+sValue);
    sList.SaveToFile(fn);
  finally
    sList.Free;
  end;
end;

function GetUsbSetStatus:Integer;
//3:����  4:����
var
  fn,str:string;
  sPath: array [0..255] of Char;
begin
  GetWindowsDirectory(@sPath,40);  //�õ�Windows��ϵͳĿ¼
  fn := sPath+'USBSet.ini';
  with TIniFile.Create(fn) do
  begin
    str := ReadString('USBSET','STATUS','4');
    str := DeCrypt(str);
    Result := StrToIntDef(str,4);
    Free;
  end;
end;

function SetUsbSetStatus(const sValue:Integer):Boolean;
//3:����  4:����
var
  fn:string;
  sPath: array [0..255] of Char;
  str:string;
begin
  GetWindowsDirectory(@sPath,40);  //�õ�Windows��ϵͳĿ¼
  fn := sPath+'USBSet.ini';
  with TIniFile.Create(fn) do
  begin
    str := IntToStr(sValue);
    str := EnCrypt(str);
    WriteString('USBSET','STATUS',str);
    Result := True;
    Free;
  end;
end;

function GetUSBStartState:Integer; //��ȡUSB����/���õ�״̬
//3:����  4:����
var
  Reg:TRegistry;
begin
  Result := -1; //δ֪
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

function USBIsStop:Boolean;   //USB�豸�Ƿ�ͣ��״̬
begin
  Result := (GetUSBStartState=4) or
            (GetUsbSetStatus=4);
end;

function GetUSBWriteProtectState:Integer; //��ȡUSBд����״̬
//0:�ɶ���д  1:ֻ��Ȩ��
var
  Reg:TRegistry;
begin
  Result := -1;//δ֪
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

  SetUsbSetStatus(iKeyValue);

  //MessageBox(0, '���óɹ��������ʹ�ã���', 'ϵͳ��ʾ', MB_OK +
  //  MB_ICONINFORMATION + MB_TOPMOST);
  Result := True;
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
end;

function SetUSBStop:Boolean; //ͣ��USB�豸
begin
  Result := SetUSBStartState(4) and SetUsbSetStatus(4);
end;

function SetUSBStart:Boolean; //����USB�豸
begin
  Result := SetUSBStartState(3) and SetUsbSetStatus(4);
end;

function SetUSBReadOnly:Boolean; //����USBֻ��
begin
  Result := SetUSBWriteProtectState(1);
end;

function SetUSBReadWrite:Boolean; //����USB��д
begin
  Result := SetUSBWriteProtectState(0);
end;

function GetLocalUSBDisk: string;
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


//-------------------------------------
// ��ȡĳ��ϵͳ����ĵ�ǰ״̬
//
// return status code if successful
// -1 if not
//
// return codes:
//   SERVICE_STOPPED
//   SERVICE_RUNNING
//   SERVICE_PAUSED
//
// following return codes are used to indicate that the service is in the
// middle of getting to one of the above states:
//   SERVICE_START_PENDING
//   SERVICE_STOP_PENDING
//   SERVICE_CONTINUE_PENDING
//   SERVICE_PAUSE_PENDING
//
// sMachine:
//   machine name, ie: \SERVER
//   empty = local machine
//
//sService
//   service name, ie: Alerter
//
function ServiceGetStatus(sService: string ): DWord;
var
  //service control
  //manager handle
  schm,
  //service handle
  schs: SC_Handle;
  //service status
  ss: TServiceStatus;
  //current service status
  dwStat : DWord;
  sMachine:string;
begin
  sMachine := '127.0.0.1';
  dwStat := 0;
  //connect to the service
  //control manager
  schm := OpenSCManager(PChar(sMachine), Nil, SC_MANAGER_CONNECT);
  //if successful...
  if(schm  > 0)then
  begin
    //open a handle to
    //the specified service
    schs := OpenService(schm, PChar(sService), SERVICE_QUERY_STATUS);
    //if successful...
    if(schs  > 0)then
    begin
      //retrieve the current status
      //of the specified service
      if(QueryServiceStatus(schs, ss))then
      begin
        dwStat := ss.dwCurrentState;
      end;
      //close service handle
      CloseServiceHandle(schs);
    end;

    // close service control
    // manager handle
    CloseServiceHandle(schm);
  end;

  Result := dwStat;
end;

{�ж�ĳ�����Ƿ�װ��δ��װ����true���Ѱ�װ����false}
function ServiceUninstalled(sService : string ) : boolean;
begin
  Result := 0 = ServiceGetStatus(sService);
end;

{�ж�ĳ�����Ƿ���������������true��δ��������false}
function ServiceRunning(sService : string ) : boolean;
begin
  Result := SERVICE_RUNNING = ServiceGetStatus(sService );
end;

{�ж�ĳ�����Ƿ�ֹͣ��ֹͣ����true��δֹͣ����false}
function ServiceStopped(sService : string ) : boolean;
begin
  Result := SERVICE_STOPPED = ServiceGetStatus(sService );
end;
end.
