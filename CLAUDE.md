# CadAddinManager (Acad_AddinManager)

AutoCAD/Civil3D용 Addin Manager (Chuong Mep 업스트림). 이 포크는 **BricsCAD 지원**을 추가한다.

## Obsidian
- 저장 위치: `D:\Dropbox\Obsidian\Projects\Acad_AddinManager\`

## Confluence (사본)
- 상위 페이지 `131081` "JArchitecture - AutoCAD 플러그인 명령어 정리" 하위: CadAddinManager AutoCAD 2025 설치본 `10649632` (원본 `docs/AutoCAD2025-Install.md`)

## QMD 키워드
- CadAddinManager, AddinManager, BricsCAD, Teigha, Bricscad, AssemLoader, PackageContents, WixSharp, Inno Setup, Ribbon, PaletteSet, CommandMethod, LispFunction

## Build

### ⚠️ 빌드는 `dotnet build`가 아니라 Visual Studio **MSBuild.exe** 로
- `dotnet build`는 net48 + 임베디드 PNG 리소스 조합에서 **MSB3823/MSB3822**로 실패한다(원본 AutoCAD 구성도 동일). SDK 빌드 엔진의 알려진 이슈.
- MSBuild 경로: `vswhere -latest -requires Microsoft.Component.MSBuild -find "MSBuild\**\Bin\MSBuild.exe"`
- 정식 빌드는 NUKE(`build/`)가 MSBuild로 수행.

### 빌드 구성
- **AutoCAD (원본)**: `Release A21`~`A27` (A25+는 .NET 8/10, 그 이하 net48). NuGet `Chuongmep.Acad.Api.*` 참조.
- **BricsCAD (추가)**: `Release B21`(V21), `Release B24`(V24). net48. `#if BRICS`로 분기.
  ```powershell
  & $msb CadAddinManager\CadAddinManager.csproj /t:Restore,Build /p:Configuration="Release B24" /p:Platform=x64
  ```
- 솔루션에도 B21/B24 구성 등록됨. B 구성에서는 CadAddinManager만 빌드된다.

## ⚠️ VS 2026에서 솔루션 열기/빌드 문제 해결
이 환경에서 실제로 겪은 문제들:

1. **모든 프로젝트 "로드 실패" (`Microsoft.NET.Sdk`를 찾을 수 없음)**
   - 원인: 루트 `global.json`이 SDK **10.0.100**(미설치)을 지정. 설치된 건 9.0.314, 10.0.300. 커맨드라인 `dotnet`은 rollForward로 10.0.300을 찾지만 **VS 2026 IDE 리졸버는 실패**.
   - 조치: `global.json`을 **비활성화**(`global.json.disabled`로 이름 변경)해 둠. 커맨드라인 빌드는 영향 없음(그대로 10.0.300).
   - global.json이 있으면(버전을 10.0.300으로 고쳐도) VS 로드가 실패했음 → **없는 상태 유지**.

2. **".NET 10.0 타겟팅 미지원" 에러**
   - 원인: `build/Build.csproj`가 **항상 net10.0**, CadAddinManager/Test의 **A27 구성**이 net10.0-windows. 현재 VS가 net10 타깃팅 미지원.
   - 조치: 솔루션 탐색기에서 **`Build` 프로젝트 언로드**, **A27 구성 사용 금지**. BricsCAD(B21/B24=net48), AutoCAD 21~24(net48), A25/A26(net8)는 정상.

3. **VS 구성 선택**: 상단 구성 드롭다운 또는 빌드 → 구성 관리자에서 활성 솔루션 구성 선택.

## BricsCAD 지원 (요약)
- 네임스페이스 매핑: `Autodesk.AutoCAD.Runtime`→`Teigha.Runtime`, `...ApplicationServices`→`Bricscad.ApplicationServices`, `...AutoCAD.Windows`→`Bricscad.Windows`.
- `Application.DocumentManager`는 `Bricscad.ApplicationServices.Application`(non-Core)에만 존재.
- 리본 UI(`App.cs`)는 BricsCAD에 동등 API 없음 → BRICS 빌드에서 컴파일 제외(명령어만 지원).
- 자세한 내용: [docs/BricsCAD-Port.md](docs/BricsCAD-Port.md)

## Installer
- **AutoCAD (원본 전체 21~27)**: `Installer/`(WixSharp) → MSI. NUKE 빌드 필요.
- **BricsCAD V21+V24 (Inno, 추가)**: `InstallerBrics/CadAddinManager-BricsCAD.iss` → per-user 설치 + 레지스트리 자동 로드. `bin\Release B21`·`bin\Release B24` 둘 다 필요.
- **AutoCAD 2025 (Inno, 추가)**: `InstallerAcad/CadAddinManager-AutoCAD2025.iss` → `%AppData%\Autodesk\ApplicationPlugins\CadAddinManager.bundle\25\` + PackageContents.xml. `bin\Release A25` 필요.
  ```powershell
  # 먼저 해당 구성들을 VS/솔루션(Any CPU)으로 빌드한 뒤:
  & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" InstallerBrics\CadAddinManager-BricsCAD.iss
  & "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" InstallerAcad\CadAddinManager-AutoCAD2025.iss
  # /p:Platform=x64 로 빌드했다면: ISCC ... /DSrcBin="..\CadAddinManager\bin\x64"
  ```

## ⚠️ 빌드 출력 경로 함정
- `/p:Platform=AnyCPU`(공백X) 또는 VS/솔루션 빌드 → `bin\<구성>\` (설치 스크립트가 참조하는 경로)
- `/p:Platform="Any CPU"`(공백O) → `bin\Any CPU\<구성>\` (다른 경로, 주의)
- `/p:Platform=x64` → `bin\x64\<구성>\`

## Conventions
- 원본 AutoCAD 동작은 절대 변경하지 않는다. BricsCAD 대응은 `#if BRICS` / 별도 빌드 구성 / 별도 설치본으로만 분리.
- Readme.MD, CHANGELOG.md는 업스트림 관리 문서 — 임의 수정 금지.
