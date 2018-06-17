unit TU.Common;

interface

const
  STATUS_SUCCESS = $00000000;


function Win32Check(RetVal: LongBool; Where: String): LongBool;
procedure Win32CheckBuffer(BufferSize: Cardinal; Where: String);
function NativeCheck(Status: LongWord; Where: String): Boolean;

implementation

uses
  System.SysUtils, Winapi.WIndows;

resourcestring
  SOSError = 'System Error in %s. Code: 0x%x.'#$D#$A'%s';

function Win32Check(RetVal: LongBool; Where: String): LongBool;
begin
  if not RetVal then
    raise EOSError.CreateResFmt(@SOSError, [Where, GetLastError,
      SysErrorMessage(GetLastError)]);
  Result := True;
end;

procedure Win32CheckBuffer(BufferSize: Cardinal; Where: String);
begin
  // TODO: What about ERROR_BUFFER_OVERFLOW and ERROR_INVALID_USER_BUFFER?
  if (GetLastError <> ERROR_INSUFFICIENT_BUFFER) or (BufferSize = 0) then
    raise EOSError.CreateResFmt(@SOSError, [Where, GetLastError,
      SysErrorMessage(GetLastError)]);
end;

function NativeCheck(Status: LongWord; Where: String): Boolean;
begin
  if Status <> STATUS_SUCCESS then
    raise EOSError.CreateResFmt(@SOSError, [Where, Status,
      SysErrorMessage(Status, GetModuleHandle('ntdll.dll'))]);
  Result := Status = STATUS_SUCCESS;
end;

end.
