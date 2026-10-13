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
; копирует его в {tmp} на шаге usUninstall и запускает на usPostUninstall (см. [Code]).
Source: "cleanup-vegaconnect.bat"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon
Name: "{userstartup}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: autostart

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(AppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"

[Registry]
; VegaConnect: клиент ищет себя через get_install_info() -> реестр.
; Inno Setup по умолчанию пишет Uninstall-запись только под {GUID}, а клиент
; ищет Software\{#AppName}\InstallState\{#AppName} и Uninstall\{#AppName}.
; Без этих ключей is_installed() возвращает false при установке в нестандартный
; путь, и пользователю показывается кнопка "Установить" (которая дополнительно
; создаёт .lnk, минуя наш installer).
Root: HKLM; Subkey: "Software\{#AppName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#AppName}\InstallState\{#AppName}"; ValueType: string; ValueName: "InstallLocation"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}"; ValueType: string; ValueName: "InstallLocation"; ValueData: "{app}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}"; ValueType: string; ValueName: "DisplayName"; ValueData: "{#AppName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}"; ValueType: string; ValueName: "DisplayVersion"; ValueData: "{#AppVersion}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}"; ValueType: string; ValueName: "Publisher"; ValueData: "{#AppPublisher}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}"; ValueType: string; ValueName: "DisplayIcon"; ValueData: "{app}\{#AppExeName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}"; ValueType: string; ValueName: "UninstallString"; ValueData: """{uninstallexe}"""; Flags: uninsdeletekey
[Code]
{ VegaConnect: после штатного удаления Inno Setup запускаем cleanup-vegaconnect.bat
  в --silent режиме. Скрипт добивает то, о чём Inno не знает:
    - старые папки %APPDATA%\RustDesk, %LOCALAPPDATA%\RustDesk, Program Files\RustDesk;
    - ярлыки на перенесённых рабочих столах (Shell Folders) и OneDrive;
    - записи RustDesk и VegaConnect в Uninstall, Software, Run, Services;
    - службы, firewall-правила, scheduled tasks.
  См. res/cleanup-vegaconnect.bat. }
{ VegaConnect: очистка следов после удаления.
  ВАЖНО: ExtractTemporaryFile работает ТОЛЬКО на этапе установки.
  На uninstall используем двухфазную схему:
    1) usUninstall — файлы ещё на месте, копируем .bat в {tmp};
    2) usPostUninstall — Inno уже удалил {app}, запускаем .bat из {tmp}.
  Это фиксит ошибку "Cannot call ExtractTemporaryFile function during Uninstall". }
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