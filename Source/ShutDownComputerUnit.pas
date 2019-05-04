{=======================================================================================================================
关闭Windows函数ExitWindowsEx(UINT uFlag,DWORD:dwReserved)说明：

控制WINDOWS的开关：如关闭WINDOWS，重新启动WINDOWS等, ExitWindowsEx(UINT uFlags,DWORD dwReserved);是实现这一功能的API函数。如果Complile时提示EWX_XXXX未定义，那么请手动定义这几个常数，默认情况下是无需我们手动定义的。
const
  EWX_FORCE=4; //关闭所有程序并以其他用户身份登录？（！！应为“强制执行否”吧！！）
  EWX_LOGOFF=0; //重新启动计算机并切换到MS-DOS方式
  EWX_REBOOT=2; //重新启动计算机
  EWX_SHUTDOWN=1;//关闭计算机
  EWX_POWEROFF=8;//切断电源
  EWX_FORCEIFHUNG=$10;//不记得了，有谁好心查下MSDN
调用方法：
  ExitWindowsEx(EWX_REBOOT,0); //重启计算机
  ExitWindowsEx(EWX_FORCE+EWX_SHUTDOWN,0); //强行关机

  不过博主经常听到有人说这一API只在Windows 95/98/98SE/Me下有效，而在Windows NT/2000/XP下无效。
  其实这是不正确的，这一API在上述平台下均是有效的，只是我们在Windows NT/2000/XP平台下执行此函数之前，必须要获取得关机特权罢了，其实就算是Windows NT/2000/XP系统自身关机也必须要走这一流程的。
  另一个关机API，InitiateSystemShutdown(PChar(Computer_Name),PChar(Hint_Msg),Time,Force,Reboot);在Windows NT/2000/XP平台下还会自动调用系统本身的关机提示窗口。
  InitiateSystemShutdown(PChar(Computer_Name), PChar(Hint_Msg),Time,Force,Reboot);
                       //关机计算机名,关机提示信息,停留时长,是否强行关机,是否要重启
  当我们把Computer_Name设为nil时，默认为本机，如 InitiateSystemshutdown(nil,nil,0,True,False);//强行关机

  由于我们需要制作一个通用的关机程序，故要对当前的操作系统进行判断，这个比较简单，函数如下：
=======================================================================================================================}

unit ShutDownComputerUnit;

interface
uses  Windows;

  procedure ShutDownComputer; //关机
  procedure RebootComputer;   //重启
  procedure LogoffComputer;   //注销

implementation

procedure Get_Shutdown_Privilege; //获得用户关机特权，仅对Windows NT/2000/XP
var
  rl: Cardinal;
  hToken: Cardinal;
  tkp: TOKEN_PRIVILEGES;
begin
  OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or TOKEN_QUERY, hToken);
  if LookupPrivilegeValue(nil, 'SeShutdownPrivilege', tkp.Privileges[0].Luid) then
  begin
    tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
    tkp.PrivilegeCount := 1;
    AdjustTokenPrivileges(hToken, False, tkp, 0, nil, rl);
  end;
end;

function GetOperatingSystem: string;//获取操作系统信息
var  osVerInfo: TOSVersionInfo;
begin
  Result :='';
  osVerInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(osVerInfo) then
    case osVerInfo.dwPlatformId of
    VER_PLATFORM_WIN32_NT:
    begin
      Result := 'Windows NT/2000/XP'
    end;
    VER_PLATFORM_WIN32_WINDOWS:
    begin
      Result := 'Windows 95/98/98SE/Me';
    end;
  end;
end;

procedure ShutDownComputer; //执行关机的主函数
begin
  if GetOperatingSystem='Windows NT/2000/XP' then
  begin
    Get_Shutdown_Privilege;
    //调用此函数会出现系统关机提示窗口
    //InitiateSystemShutDown(nil,'关机提示：讨厌你所以关了你！',0,True,False);
    ExitWindowsEx(EWX_SHUTDOWN+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
  end else
  begin
    ExitWindowsEx(EWX_SHUTDOWN+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
  end;
end;

procedure RebootComputer; //执行重启的主函数
begin
  if GetOperatingSystem='Windows NT/2000/XP' then
  begin
    Get_Shutdown_Privilege;
    //调用此函数会出现系统关机提示窗口
    //InitiateSystemShutDown(nil,'关机提示：讨厌你所以关了你！',0,True,False);
    ExitWindowsEx(EWX_REBOOT+EWX_FORCE+EWX_FORCEIFHUNG,0);
  end else
  begin
    ExitWindowsEx(EWX_REBOOT+EWX_FORCE+EWX_FORCEIFHUNG,0);
  end;
end;

procedure LogoffComputer; //执行注销的主函数
begin
  if GetOperatingSystem='Windows NT/2000/XP' then
  begin
    Get_Shutdown_Privilege;
    //调用此函数会出现系统关机提示窗口
    //InitiateSystemShutDown(nil,'关机提示：讨厌你所以关了你！',0,True,False);
    //ExitWindowsEx(EWX_LOGOFF+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
    ExitWindowsEx(EWX_LOGOFF+EWX_FORCE,0);
  end else
  begin
    //ExitWindowsEx(EWX_LOGOFF+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
    ExitWindowsEx(EWX_LOGOFF+EWX_FORCE,0);
  end;
end;

end.
 