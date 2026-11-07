# CadAddinManager AutoCAD 2025 설치본 (잠금 수정판)

`C:\Jarch25\Acadv25JArch.dll` 같은 원본 DLL 이 AddinManager 실행 후 잠겨 빌드 복사가 실패하는 문제(MSB3021)를 고친 빌드의 설치 파일.

## 설치 파일

| 항목 | 값 |
|---|---|
| 파일 | `InstallerAcad\output\CadAddinManager-AutoCAD2025-2.0.8.exe` |
| 크기 | 2,141,947 바이트 |
| SHA-256 | `20ACA62050301CE2EB4269B002B10B02ECEDC4932BBB16A9E1C18AF51C2DE0A3` |
| 생성일 | 2026-11-07 (Inno Setup) |
| 포함 빌드 | `CadAddinManager\bin\Release A25` (2026-07-22 13:38). 이후 소스 변경 없음 |
| 설치 위치 | `%AppData%\Autodesk\ApplicationPlugins\CadAddinManager.bundle\25\` + `PackageContents.xml` |
| 설치 조건 | AutoCAD 종료 (실행 중이면 설치 차단) |

버전 표기는 2026-03-26 공식 빌드와 같은 2.0.8 이다. 파일 날짜나 아래 수정 내용으로 구분한다.

## 달라진 점

| 항목 | 2026-03-26 공식 빌드 | 2026-07-22 빌드 |
|---|---|---|
| 원본 DLL 읽기 | Mono.Cecil 이 파일 핸들 유지 | `InMemory = true` 로 메모리에 읽고 핸들 닫음 |
| Cecil 객체 해제 | 없음 | `using` 으로 해제 |

수정 위치: `CadAddinManager\Model\AssemLoader.cs` (`ResolveDuplicateMethod`, `GetAssemblyDef`). 2026-11-07 기준 미커밋.

잠금 원인이 Cecil 파일 핸들이라는 것은 코드와 증상으로 판단한 추정이다.

## 주의

| 항목 | 내용 |
|---|---|
| AutoCAD 2025 전용 | 설치본의 `PackageContents.xml` 에는 2025 항목만 있다. 공식 번들 위에 설치하면 다른 버전(2021~2024, 2026, 2027) 등록이 빠진다 |
| arx | AddinManager 는 `JArchXData.arx` 를 임시 폴더로 복사하지 않는다. XData 쓰는 명령은 실행 전 `(arxload "C:/Jarch25/JArchXData.arx")` 필요 |

## 설치 파일 다시 만들기

```powershell
# bin\Release A25 를 VS/솔루션(Any CPU)으로 빌드한 뒤
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" InstallerAcad\CadAddinManager-AutoCAD2025.iss
```

## 검증 상태 (2026-11-07)

| 항목 | 결과 |
|---|---|
| 설치 파일 컴파일 | 성공 |
| 설치 파일 실행 | 안 함 |
| 번들 DLL 수동 교체 | 완료. 같은 빌드의 `CadAddinManager.dll` 을 `bundle\25` 에 복사, 원본은 `CadAddinManager.dll.20261107.bak` |
| AutoCAD 에서 교체본 실행 | 미확인 |
| 잠금 해소 | 미확인 |
