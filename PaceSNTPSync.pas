program EasySNTPSync;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Classes,
  SysUtils,
  CustApp { you can add units after this },
  Windows,
  sntpsend;

type

  { TMysntp }

  TMysntp = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
    function SetSysTime(dDateTime: TDateTime): boolean;
    function SetLocTime(dDateTime: TDateTime): boolean;
  end;

  { TMysntp }

  procedure TMysntp.DoRun;
  var
    ErrorMsg: string;
    sntp: TSntpSend;
    remoteTime: TDateTime;
    targeth: string;
    dowhat: string;

  begin
    // quick check parameters
    ErrorMsg := CheckOptions('h', 'help');
    if ErrorMsg <> '' then
    begin
      ShowException(Exception.Create(ErrorMsg));
      Terminate;
      Exit;
    end;

    // parse parameters
    if HasOption('h', 'help') then
    begin
      WriteHelp;
      Terminate;
      Exit;
    end;

    { add your program here }

    if trim(ParamStr(2)) = '' then
    begin
      //targeth := '192.168.10.117';
      targeth := 'time.nist.gov';
      //targeth := '192.168.75.3';

    end
    else
      targeth := ParamStr(2);

    if trim(ParamStr(1)) = '' then
    begin
      dowhat := 'setsystemtime';
    end
    else
      dowhat := ParamStr(1);


    sntp := TSNTPSend.Create;
    sntp.Timeout := 10000;
    sntp.TargetHost := targeth;
    //sntp.TargetPort:='37';
    sntp.SyncTime := True;
    writeln('Contacting ' + sntp.TargetHost + ' on port ' + sntp.TargetPort);
    try
      try
        if sntp.GetSNTP then
        begin
          remoteTime := sntp.NTPTime;
          writeln('Remote time is :' + DateTimeToStr(remoteTime) + ' UTC');
          if LowerCase(dowhat) = 'setsystemtime' then
            SetSysTime(remoteTime);
          if LowerCase(dowhat) = 'setlocaltime' then
            SetLocTime(remoteTime);
        end
        else
          writeln('Unable to retrieve remote time');
      except
        On E: Exception do
          WriteLn('Exception ' + E.ClassName + ': ' + E.Message);
      end;
    finally
      sntp.Free;
    end;

    // stop program loop
    Terminate;
  end;

  constructor TMysntp.Create(TheOwner: TComponent);
  begin
    inherited Create(TheOwner);
    StopOnException := True;
  end;

  destructor TMysntp.Destroy;
  begin
    inherited Destroy;
  end;

  procedure TMysntp.WriteHelp;
  begin
    { add your help code here }
    writeln('Usage: setsystemtime time.nist.gov (if no options uses defaults)');
  end;

  function TMysntp.SetSysTime(dDateTime: TDateTime): boolean;
  const
    SE_SYSTEMTIME_NAME = 'SeSystemtimePrivilege';
  var
    hToken: THandle;
    ReturnLength: DWORD;
    tkp, PrevTokenPriv: TTokenPrivileges;
    luid: TLargeInteger;
    dSysTime: TSystemTime;
  begin
    Result := False;
    if (Win32Platform = VER_PLATFORM_WIN32_NT) then
    begin
      if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or
        TOKEN_QUERY, hToken) then
      begin
        try
          if not LookupPrivilegeValue(nil, SE_SYSTEMTIME_NAME, luid) then
            Exit;
          tkp.PrivilegeCount := 1;
          tkp.Privileges[0].luid := luid;
          tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
          if not AdjustTokenPrivileges(hToken, False, tkp,
            SizeOf(TTOKENPRIVILEGES), PrevTokenPriv, ReturnLength) then
            Exit;
          if (GetLastError <> ERROR_SUCCESS) then
          begin
            raise Exception.Create(SysErrorMessage(GetLastError));
            Exit;
          end;
        finally
          closehandle(hToken); { *Converted from CloseHandle*  }
        end;
      end;
    end;
    DateTimeToSystemTime(dDateTime, dSysTime);
    Result := Windows.SetSystemTime(dSysTime);
    writeln('Time is now Synced');
  end;

  function TMysntp.SetLocTime(dDateTime: TDateTime): boolean;
  const
    SE_SYSTEMTIME_NAME = 'SeSystemtimePrivilege';
  var
    hToken: THandle;
    ReturnLength: DWORD;
    tkp, PrevTokenPriv: TTokenPrivileges;
    luid: TLargeInteger;
    dSysTime: TSystemTime;
  begin
    Result := False;
    if (Win32Platform = VER_PLATFORM_WIN32_NT) then
    begin
      if OpenProcessToken(GetCurrentProcess, TOKEN_ADJUST_PRIVILEGES or
        TOKEN_QUERY, hToken) then
      begin
        try
          if not LookupPrivilegeValue(nil, SE_SYSTEMTIME_NAME, luid) then
            Exit;
          tkp.PrivilegeCount := 1;
          tkp.Privileges[0].luid := luid;
          tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;
          if not AdjustTokenPrivileges(hToken, False, tkp,
            SizeOf(TTOKENPRIVILEGES), PrevTokenPriv, ReturnLength) then
            Exit;
          if (GetLastError <> ERROR_SUCCESS) then
          begin
            raise Exception.Create(SysErrorMessage(GetLastError));
            Exit;
          end;
        finally
          closehandle(hToken); { *Converted from CloseHandle*  }
        end;
      end;
    end;
    DateTimeToSystemTime(dDateTime, dSysTime);
    Result := Windows.SetLocalTime(dSysTime);
    writeln('Time is now Synced');
  end;




var
  Application: TMysntp;

begin
  Application := TMysntp.Create(nil);
  Application.Title := 'Easy SNTP Sync';
  Application.Run;
  Application.Free;
end.


