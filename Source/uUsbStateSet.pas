unit uUsbStateSet;

interface
  uses SysUtils,Registry,Windows, WinSvc,IniFiles,Classes;

  function SetUSBStop:Boolean; //停用USB设备
  function SetUSBStart:Boolean; //启用USB设备
  function USBIsStop:Boolean;   //USB设备是否停用状态
  function GetLocalUSBDisk:string;
  {判断某服务是否安装，未安装返回true，已安装返回false}
  function ServiceUninstalled(sService : string ) : boolean;
  {判断某服务是否启动，启动返回true，未启动返回false}
  function ServiceRunning(sService : string ) : boolean;
  {判断某服务是否停止，停止返回true，未停止返回false}
  function ServiceStopped(sService : string ) : boolean;
  procedure SaveLog(const sValue:string);

implementation
uses PwdFunUnit;

procedure SaveLog(const sValue:string);
//3:启用  4:禁用
var
  fn:string;
  sPath: array [0..255] of Char;
  //sPath :string;
  sList:TStrings;
begin
  GetWindowsDirectory(@sPath,40);  //得到Windows的系统目录
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
//3:启用  4:禁用
var
  fn,str:string;
  sPath: array [0..255] of Char;
begin
  GetWindowsDirectory(@sPath,40);  //得到Windows的系统目录
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
//3:启用  4:禁用
var
  fn:string;
  sPath: array [0..255] of Char;
  str:string;
begin
  GetWindowsDirectory(@sPath,40);  //得到Windows的系统目录
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

function GetUSBStartState:Integer; //获取USB禁用/启用的状态
//3:启用  4:禁用
var
  Reg:TRegistry;
begin
  Result := -1; //未知
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

function USBIsStop:Boolean;   //USB设备是否停用状态
begin
  Result := (GetUSBStartState=4) or
            (GetUsbSetStatus=4);
end;

function GetUSBWriteProtectState:Integer; //获取USB写保护状态
//0:可读可写  1:只读权限
var
  Reg:TRegistry;
begin
  Result := -1;//未知
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

  SetUsbSetStatus(iKeyValue);

  //MessageBox(0, '设置成功，请放心使用！　', '系统提示', MB_OK +
  //  MB_ICONINFORMATION + MB_TOPMOST);
  Result := True;
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
end;

function SetUSBStop:Boolean; //停用USB设备
begin
  Result := SetUSBStartState(4) and SetUsbSetStatus(4);
end;

function SetUSBStart:Boolean; //启用USB设备
begin
  Result := SetUSBStartState(3) and SetUsbSetStatus(4);
end;

function SetUSBReadOnly:Boolean; //设置USB只读
begin
  Result := SetUSBWriteProtectState(1);
end;

function SetUSBReadWrite:Boolean; //设置USB读写
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
      //showmessage(str_temp+'盘为u盘') ;
      //listbox1.items.add(str_temp) ;
    end;
  end;
end;


//-------------------------------------
// 获取某个系统服务的当前状态
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

{判断某服务是否安装，未安装返回true，已安装返回false}
function ServiceUninstalled(sService : string ) : boolean;
begin
  Result := 0 = ServiceGetStatus(sService);
end;

{判断某服务是否启动，启动返回true，未启动返回false}
function ServiceRunning(sService : string ) : boolean;
begin
  Result := SERVICE_RUNNING = ServiceGetStatus(sService );
end;

{判断某服务是否停止，停止返回true，未停止返回false}
function ServiceStopped(sService : string ) : boolean;
begin
  Result := SERVICE_STOPPED = ServiceGetStatus(sService );
end;
end.
