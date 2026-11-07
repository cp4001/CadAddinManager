; CadAddinManager - BricsCAD 설치 프로그램
; 원본(AutoCAD/WixSharp) 설치와 완전 분리된 별도 설치본.
; BricsCAD 자동 로드는 레지스트리(HKCU\Software\Bricsys\BricsCAD\Vxxx64\<locale>\Applications) 방식 사용.

#define AppName "CadAddinManager for BricsCAD"
#define AppRegName "CadAddinManager"
#define AppVersion "2.0.8"
#define AppPublisher "ChuongMep.com"
#define AppDescription "Execute Assembly no need reopen BricsCAD - Addin Manager"
; SrcBin 은 빌드 방식에 따른 출력 경로. VS/솔루션(Any CPU) 빌드는 bin\, /p:Platform=x64 빌드는 bin\x64\.
; ISCC 컴파일 시 /DSrcBin="..\CadAddinManager\bin\x64" 로 재정의 가능.
#ifndef SrcBin
  #define SrcBin "..\CadAddinManager\bin"
#endif
#define SrcRoot SrcBin

[Setup]
AppId={{F7A2C1E4-3B56-4D91-9A2C-BCA1CADB1C42}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={userappdata}\CadAddinManager\BricsCAD
DisableProgramGroupPage=yes
DisableDirPage=no
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=output
OutputBaseFilename=CadAddinManager-BricsCAD-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
WizardImageStretch=no
SetupIconFile=..\Installer\Resources\Icons\ShellIcon.ico
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\24\CadAddinManager.dll

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Files]
; BricsCAD V24 빌드 -> 24 폴더
Source: "{#SrcRoot}\Release B24\*"; DestDir: "{app}\24"; Flags: ignoreversion recursesubdirs createallsubdirs
; BricsCAD V21 빌드 -> 21 폴더
Source: "{#SrcRoot}\Release B21\*"; DestDir: "{app}\21"; Flags: ignoreversion recursesubdirs createallsubdirs

[Code]
const
  BricsRoot = 'Software\Bricsys\BricsCAD';

// 실행 중 프로세스 확인 (WMI)
function IsAppRunning(const FileName: string): Boolean;
var
  FSWbemLocator, FWMIService, FWbemObjectSet: Variant;
begin
  Result := False;
  try
    FSWbemLocator := CreateOleObject('WBemScripting.SWbemLocator');
    FWMIService := FSWbemLocator.ConnectServer('', 'root\CIMV2', '', '');
    FWbemObjectSet := FWMIService.ExecQuery(Format('SELECT Name FROM Win32_Process Where Name="%s"', [FileName]));
    Result := (FWbemObjectSet.Count > 0);
  except
    Result := False;
  end;
end;

// 레지스트리 버전키(V21x64 등)를 DLL 폴더명(21/24)으로 매핑. 미지원이면 빈 문자열
function VersionKeyToFolder(const VerKey: string): string;
begin
  Result := '';
  if Pos('V21', VerKey) = 1 then Result := '21';
  if Pos('V24', VerKey) = 1 then Result := '24';
end;

// 설치된 BricsCAD 프로파일을 열거해 자동 로드 등록
procedure RegisterForBricsCAD;
var
  Vers, Locs: TArrayOfString;
  i, j: Integer;
  folder, loader, verKey, appKey: string;
begin
  if not RegGetSubkeyNames(HKEY_CURRENT_USER, BricsRoot, Vers) then exit;
  for i := 0 to GetArrayLength(Vers) - 1 do
  begin
    folder := VersionKeyToFolder(Vers[i]);
    if folder = '' then continue;
    loader := ExpandConstant('{app}\') + folder + '\CadAddinManager.dll';
    if not FileExists(loader) then continue;
    verKey := BricsRoot + '\' + Vers[i];
    if not RegGetSubkeyNames(HKEY_CURRENT_USER, verKey, Locs) then continue;
    for j := 0 to GetArrayLength(Locs) - 1 do
    begin
      // 로케일 키(ko_KR, en_US 등)만 대상
      if Pos('_', Locs[j]) = 0 then continue;
      appKey := verKey + '\' + Locs[j] + '\Applications\' + '{#AppRegName}';
      RegWriteStringValue(HKEY_CURRENT_USER, appKey, 'DESCRIPTION', '{#AppDescription}');
      RegWriteStringValue(HKEY_CURRENT_USER, appKey, 'LOADER', loader);
      RegWriteDWordValue(HKEY_CURRENT_USER, appKey, 'LOADCTRLS', 2);
      RegWriteDWordValue(HKEY_CURRENT_USER, appKey, 'MANAGED', 1);
    end;
  end;
end;

// 자동 로드 등록 해제 (제거 시)
procedure UnregisterFromBricsCAD;
var
  Vers, Locs: TArrayOfString;
  i, j: Integer;
  verKey, appKey: string;
begin
  if not RegGetSubkeyNames(HKEY_CURRENT_USER, BricsRoot, Vers) then exit;
  for i := 0 to GetArrayLength(Vers) - 1 do
  begin
    verKey := BricsRoot + '\' + Vers[i];
    if not RegGetSubkeyNames(HKEY_CURRENT_USER, verKey, Locs) then continue;
    for j := 0 to GetArrayLength(Locs) - 1 do
    begin
      appKey := verKey + '\' + Locs[j] + '\Applications\' + '{#AppRegName}';
      if RegKeyExists(HKEY_CURRENT_USER, appKey) then
        RegDeleteKeyIncludingSubkeys(HKEY_CURRENT_USER, appKey);
    end;
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  if IsAppRunning('bricscad.exe') then
  begin
    MsgBox('BricsCAD가 실행 중입니다. 설치 전에 BricsCAD를 모두 종료해 주세요.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
    RegisterForBricsCAD;
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
  if IsAppRunning('bricscad.exe') then
  begin
    MsgBox('BricsCAD가 실행 중입니다. 제거 전에 BricsCAD를 모두 종료해 주세요.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
    UnregisterFromBricsCAD;
end;
