{=======================================================================================================================
�ر�Windows����ExitWindowsEx(UINT uFlag,DWORD:dwReserved)˵����

����WINDOWS�Ŀ��أ���ر�WINDOWS����������WINDOWS��, ExitWindowsEx(UINT uFlags,DWORD dwReserved);��ʵ����һ���ܵ�API���������Complileʱ��ʾEWX_XXXXδ���壬��ô���ֶ������⼸��������Ĭ������������������ֶ�����ġ�
const
  EWX_FORCE=4; //�ر����г����������û���ݵ�¼��������ӦΪ��ǿ��ִ�з񡱰ɣ�����
  EWX_LOGOFF=0; //����������������л���MS-DOS��ʽ
  EWX_REBOOT=2; //�������������
  EWX_SHUTDOWN=1;//�رռ����
  EWX_POWEROFF=8;//�жϵ�Դ
  EWX_FORCEIFHUNG=$10;//���ǵ��ˣ���˭���Ĳ���MSDN
���÷�����
  ExitWindowsEx(EWX_REBOOT,0); //���������
  ExitWindowsEx(EWX_FORCE+EWX_SHUTDOWN,0); //ǿ�йػ�

  ��������������������˵��һAPIֻ��Windows 95/98/98SE/Me����Ч������Windows NT/2000/XP����Ч��
  ��ʵ���ǲ���ȷ�ģ���һAPI������ƽ̨�¾�����Ч�ģ�ֻ��������Windows NT/2000/XPƽ̨��ִ�д˺���֮ǰ������Ҫ��ȡ�ùػ���Ȩ���ˣ���ʵ������Windows NT/2000/XPϵͳ����ػ�Ҳ����Ҫ����һ���̵ġ�
  ��һ���ػ�API��InitiateSystemShutdown(PChar(Computer_Name),PChar(Hint_Msg),Time,Force,Reboot);��Windows NT/2000/XPƽ̨�»����Զ�����ϵͳ����Ĺػ���ʾ���ڡ�
  InitiateSystemShutdown(PChar(Computer_Name), PChar(Hint_Msg),Time,Force,Reboot);
                       //�ػ��������,�ػ���ʾ��Ϣ,ͣ��ʱ��,�Ƿ�ǿ�йػ�,�Ƿ�Ҫ����
  �����ǰ�Computer_Name��Ϊnilʱ��Ĭ��Ϊ�������� InitiateSystemshutdown(nil,nil,0,True,False);//ǿ�йػ�

  ����������Ҫ����һ��ͨ�õĹػ����򣬹�Ҫ�Ե�ǰ�Ĳ���ϵͳ�����жϣ�����Ƚϼ򵥣��������£�
=======================================================================================================================}

unit ShutDownComputerUnit;

interface
uses  Windows;

  procedure ShutDownComputer; //�ػ�
  procedure RebootComputer;   //����
  procedure LogoffComputer;   //ע��

implementation

procedure Get_Shutdown_Privilege; //����û��ػ���Ȩ������Windows NT/2000/XP
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

function GetOperatingSystem: string;//��ȡ����ϵͳ��Ϣ
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

procedure ShutDownComputer; //ִ�йػ���������
begin
  if GetOperatingSystem='Windows NT/2000/XP' then
  begin
    Get_Shutdown_Privilege;
    //���ô˺��������ϵͳ�ػ���ʾ����
    //InitiateSystemShutDown(nil,'�ػ���ʾ�����������Թ����㣡',0,True,False);
    ExitWindowsEx(EWX_SHUTDOWN+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
  end else
  begin
    ExitWindowsEx(EWX_SHUTDOWN+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
  end;
end;

procedure RebootComputer; //ִ��������������
begin
  if GetOperatingSystem='Windows NT/2000/XP' then
  begin
    Get_Shutdown_Privilege;
    //���ô˺��������ϵͳ�ػ���ʾ����
    //InitiateSystemShutDown(nil,'�ػ���ʾ�����������Թ����㣡',0,True,False);
    ExitWindowsEx(EWX_REBOOT+EWX_FORCE+EWX_FORCEIFHUNG,0);
  end else
  begin
    ExitWindowsEx(EWX_REBOOT+EWX_FORCE+EWX_FORCEIFHUNG,0);
  end;
end;

procedure LogoffComputer; //ִ��ע����������
begin
  if GetOperatingSystem='Windows NT/2000/XP' then
  begin
    Get_Shutdown_Privilege;
    //���ô˺��������ϵͳ�ػ���ʾ����
    //InitiateSystemShutDown(nil,'�ػ���ʾ�����������Թ����㣡',0,True,False);
    //ExitWindowsEx(EWX_LOGOFF+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
    ExitWindowsEx(EWX_LOGOFF+EWX_FORCE,0);
  end else
  begin
    //ExitWindowsEx(EWX_LOGOFF+EWX_FORCE+EWX_POWEROFF+EWX_FORCEIFHUNG,0);
    ExitWindowsEx(EWX_LOGOFF+EWX_FORCE,0);
  end;
end;

end.
 