; CadAddinManager - AutoCAD 2025 설치 프로그램
; AutoCAD 자동 로드: %AppData%\Autodesk\ApplicationPlugins\CadAddinManager.bundle (번들 폴더 + PackageContents.xml)
; A25 구성(net8.0-windows) 출력을 25 폴더에 배치.

#define AppName "CadAddinManager for AutoCAD 2025"
#define AppVersion "2.0.8"
#define AppPublisher "ChuongMep.com"
#define BundleName "CadAddinManager.bundle"
; SrcBin: VS/솔루션(Any CPU) 빌드 출력. /p:Platform=x64 로 빌드했다면 /DSrcBin="..\CadAddinManager\bin\x64" 로 재정의
#ifndef SrcBin
  #define SrcBin "..\CadAddinManager\bin"
#endif

[Setup]
AppId={{A1B2C3D4-2025-4ACD-9E5F-CAD25AD00001}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
DefaultDirName={userappdata}\Autodesk\ApplicationPlugins\{#BundleName}
DisableDirPage=yes
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=output
OutputBaseFilename=CadAddinManager-AutoCAD2025-{#AppVersion}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
WizardImageStretch=no
SetupIconFile=..\Installer\Resources\Icons\ShellIcon.ico
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\25\CadAddinManager.dll

[Languages]
Name: "korean"; MessagesFile: "compiler:Languages\Korean.isl"

[Files]
; AutoCAD 2025 (A25, net8) 빌드 -> 25 폴더
Source: "{#SrcBin}\Release A25\*"; DestDir: "{app}\25"; Flags: ignoreversion recursesubdirs createallsubdirs
; 번들 매니페스트
Source: "PackageContents.xml"; DestDir: "{app}"; Flags: ignoreversion

[Code]
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

function InitializeSetup(): Boolean;
begin
  Result := True;
  if IsAppRunning('acad.exe') then
  begin
    MsgBox('AutoCAD가 실행 중입니다. 설치 전에 AutoCAD를 모두 종료해 주세요.', mbError, MB_OK);
    Result := False;
  end;
end;

function InitializeUninstall(): Boolean;
begin
  Result := True;
  if IsAppRunning('acad.exe') then
  begin
    MsgBox('AutoCAD가 실행 중입니다. 제거 전에 AutoCAD를 모두 종료해 주세요.', mbError, MB_OK);
    Result := False;
  end;
end;
