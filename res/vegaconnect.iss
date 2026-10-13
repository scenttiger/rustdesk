; VegaConnect Inno Setup script
; Build via: ISCC.exe res\vegaconnect.iss
; Requires: flutter build windows --release (done beforehand)
; Encoding: UTF-8 with BOM (required for Cyrillic in [Tasks]/[Messages]).

#define AppName "VegaConnect"
#define AppVersion "1.5.0"
#define AppPublisher "Vega IT"
#define AppURL "https://connect.vega-it.ru"
#define AppExeName "vegaconnect.exe"
#define BuildDir "..\flutter\build\windows\x64\runner\Release"
#define OutputDir "..\dist"

[Setup]
AppId={{7B3E9F1A-4C2D-4E8B-9A1F-1E5C3B7D2A44}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
InfoBeforeFile=NOTICE.txt
LicenseFile=..\LICENCE
OutputDir={#OutputDir}
OutputBaseFilename=VegaConnect-Setup-{#AppVersion}
SetupIconFile=vegaconnect.ico
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName} {#AppVersion}

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
; VegaConnect: русский текст хранится в UTF-8 BOM, иначе Inno Setup читает его как CP1251.
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "autostart"; Description: "Запускать VegaConnect при входе в систему"; GroupDescription: "Автозапуск:"; Flags: unchecked

[Files]
; VegaConnect: основной payload клиента.
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; VegaConnect: cleanup-vegaconnect.bat кладётся в {app}. При удалении Inno
; копирует его в {tmp} на шаге usUninstall и запускает на usPostUninstall (см. [Code]
{ VegaConnect: cleanup after uninstall.
  ExtractTemporaryFile works only at install time, not during uninstall.
  Two-phase approach:
    usUninstall      - copy cleanup-vegaconnect.bat from the install
                       directory into the temp directory, while files
                       are still present on disk;
    usPostUninstall  - the install directory has been removed by Inno,
                       run the .bat from the temp directory with --silent.
  This fixes the runtime error
  "Cannot call ExtractTemporaryFile function during Uninstall".

  IMPORTANT: do NOT use curly braces inside this comment. Inno Setup
  comments are { ... } with no nesting, so any inner brace closes the
  comment early and breaks parsing. Use plain text instead. }
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
  SrcBat: String;
  TmpBat: String;
begin
  TmpBat := ExpandConstant('{tmp}\cleanup-vegaconnect.bat');
  if CurUninstallStep = usUninstall then
  begin
    SrcBat := ExpandConstant('{app}\cleanup-vegaconnect.bat');
    if FileExists(SrcBat) then
      FileCopy(SrcBat, TmpBat, False);
  end
  else if CurUninstallStep = usPostUninstall then
  begin
    if FileExists(TmpBat) then
      Exec(
        ExpandConstant('{cmd}'),
        '/c ""' + TmpBat + '" --silent"',
        '',
        SW_HIDE,
        ewWaitUntilTerminated,
        ResultCode
      );
  end;
end;