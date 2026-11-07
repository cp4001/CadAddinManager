# BricsCAD 포팅 가이드

원본 AutoCAD/Civil3D용 CadAddinManager를 **원본 그대로 두고** BricsCAD에서도 동작하도록 추가한 작업 문서.

## 개요

| 항목 | 내용 |
|---|---|
| 방식 | 동일 프로젝트 + `#if BRICS` 조건부 컴파일 (원본 소스 보존) |
| 대상 버전 | BricsCAD V21, V24 (빌드 구성 `B21`, `B24`) |
| 프레임워크 | net48 |
| 리본 UI | BricsCAD에 동등 API 없음 → 제외. **명령어만 지원** |
| 설치 | Inno Setup 별도 설치본 + 레지스트리 자동 로드 |

## 네임스페이스 매핑

BricsCAD .NET API는 AutoCAD API를 미러링하지만 네임스페이스가 다르다. (V21/V24 동일)

| AutoCAD | BricsCAD | 어셈블리 |
|---|---|---|
| `Autodesk.AutoCAD.Runtime` | `Teigha.Runtime` | TD_Mgd.dll |
| `Autodesk.AutoCAD.ApplicationServices` | `Bricscad.ApplicationServices` | BrxMgd.dll |
| `Autodesk.AutoCAD.ApplicationServices.Core` | `Bricscad.ApplicationServices.Core` | BrxMgd.dll |
| `Autodesk.AutoCAD.Windows` | `Bricscad.Windows` | BrxMgd.dll |
| `Autodesk.AutoCAD.EditorInput` | `Bricscad.EditorInput` | BrxMgd.dll |

### 함정: `Application.DocumentManager`
`DocumentManager`는 `Bricscad.ApplicationServices.Application`(non-Core)에만 있고 `.Core.Application`에는 **없다**. AutoCAD는 `.Core.Application`에 있으므로 alias를 아래처럼 분기한다.

```csharp
#if BRICS
using Application = Bricscad.ApplicationServices.Application;
#else
using Application = Autodesk.AutoCAD.ApplicationServices.Core.Application;
#endif
```

## 변경 파일

| 파일 | 변경 |
|---|---|
| `CadAddinManager.csproj` | `B21`/`B24` 구성 추가. `IsBrics`일 때 AutoCAD NuGet 제외 → `TD_Mgd`/`BrxMgd` 참조(Private=false), `App.cs` 컴파일 제외 |
| `Command/AddInManagerCommand.cs` | using 분기 + 정규화된 attribute를 단축형으로 |
| `Command/AddinManagerBase.cs` | using + Application alias 분기 |
| `Command/DockPanelCommand.cs` | using 분기 (PaletteSet → Bricscad.Windows) |
| `Model/AddinItem.cs`, `Model/Addins.cs` | Runtime using 분기 |
| `ViewModel/AddInManagerViewModel.cs`, `ViewModel/AddinManager.cs` | Application alias 분기 |
| `Model/AssemLoader.cs` | `IsAPIReferenced`에 BricsCAD API 어셈블리(`td_mgd`/`brxmgd`) 탐지 추가 |

> `Model/ProcessManager.cs`는 Win32(MainWindowHandle)만 사용 → 변경 불필요.

## 빌드

`dotnet build`는 net48+PNG 리소스에서 MSB3823으로 실패하므로 **Visual Studio MSBuild.exe** 사용.

```powershell
$msb = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" `
  -latest -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe" | Select-Object -First 1
& $msb AddInManager.sln /t:Build /p:Configuration="Release B24" /p:Platform="Any CPU"
& $msb AddInManager.sln /t:Build /p:Configuration="Release B21" /p:Platform="Any CPU"
```

출력: `CadAddinManager\bin\Release B24\CadAddinManager.dll` (+ Mono.Cecil 의존성). BricsCAD 참조 DLL은 런타임에 BricsCAD가 자기 폴더에서 로드하므로 복사하지 않는다.

### ⚠️ 출력 경로 함정
빌드 방식에 따라 출력 폴더가 달라지며, 설치 스크립트는 `bin\<구성>\`(VS/솔루션 빌드 경로)를 참조한다.

| 빌드 방식 | 출력 경로 |
|---|---|
| VS/솔루션 빌드, 또는 `/p:Platform=AnyCPU`(공백X) | `bin\Release B24\` ✅ |
| `/p:Platform="Any CPU"` (공백O) | `bin\Any CPU\Release B24\` ⚠️ |
| `/p:Platform=x64` | `bin\x64\Release B24\` |

### VS 2026 환경 주의
- 루트 `global.json`(SDK 10.0.100 미설치 지정)이 있으면 VS가 전 프로젝트 로드 실패 → **`global.json.disabled`로 비활성화**해 둠.
- `Build`(NUKE, net10 고정)/`A27` 구성은 net10 타깃이라 현재 VS가 로드/빌드 못함 → **`Build` 프로젝트 언로드, A27 사용 금지**. (BricsCAD B21/B24=net48은 무관)

## 설치 — BricsCAD (`InstallerBrics/CadAddinManager-BricsCAD.iss`)

- per-user 설치: `%AppData%\CadAddinManager\BricsCAD\` 아래 버전별 `21\`, `24\` 폴더
- **자동 로드**: 설치된 BricsCAD 프로파일을 레지스트리에서 열거해 각각 등록

```
HKCU\Software\Bricsys\BricsCAD\<Vxxx64>\<locale>\Applications\CadAddinManager
    DESCRIPTION = "..."
    LOADER      = <버전에 맞는 CadAddinManager.dll 전체 경로>
    LOADCTRLS   = 2   (BricsCAD 시작 시 로드)
    MANAGED     = 1   (.NET 관리 어셈블리)
```

- 제거 시 위 키를 열거해 삭제. 설치/제거 전 `bricscad.exe` 실행 여부를 WMI로 확인.
- 컴파일: `ISCC.exe InstallerBrics\CadAddinManager-BricsCAD.iss` (x64 출력이면 `/DSrcBin="..\CadAddinManager\bin\x64"`)
- 산출물: `InstallerBrics\output\CadAddinManager-BricsCAD-2.0.8.exe`

## 설치 — AutoCAD 2025 (`InstallerAcad/CadAddinManager-AutoCAD2025.iss`)

BricsCAD와 별개로 만든 AutoCAD 2025 전용 Inno 설치본. 레지스트리가 아닌 **번들 폴더 방식**.

- `Release A25`(net8) 출력을 `%AppData%\Autodesk\ApplicationPlugins\CadAddinManager.bundle\25\`에 복사 + `PackageContents.xml`(R25.0) 배치. AutoCAD가 번들을 자동 로드.
- per-user, 관리자 권한 불필요. 설치/제거 전 `acad.exe` 실행 여부 확인.
- 컴파일: `ISCC.exe InstallerAcad\CadAddinManager-AutoCAD2025.iss`
- 산출물: `InstallerAcad\output\CadAddinManager-AutoCAD2025-2.0.8.exe`

> AutoCAD 전체 버전(21~27) MSI는 업스트림 `Installer/`(WixSharp+NUKE)를 사용.

## 명령어

BricsCAD에서 사용 가능한 명령 (리본 없이 명령행 입력):

| 명령 | 기능 |
|---|---|
| `AddInManagerManual` | Addin Manager 창 (수동) |
| `AddInManagerFaceLess` | 마지막 명령 재실행 (창 없이) |
| `AddinManagerDockPanel` | Trace/Debug 출력 도킹 패널 토글 |

## 미검증 / TODO
- 실제 BricsCAD 안에서 자동 로드 및 명령 동작 테스트 (설치 → BricsCAD 재시작 → 명령 입력).
- 로드가 안 되면 `LOADCTRLS` 값 재확인.
