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
; VegaConnect: BUILD_DATE в реестре должен быть в том же формате, что
; hbb_common::gen_version (chrono "%Y-%m-%d %H:%M"). Клиент
; is_installed_lower_version() (ui_interface.rs) читает это значение из
; Software\<app>\InstallState\<app> и сравнивает лексикографически со
; своим BUILD_DATE. Пустое значение => BUILD_DATE > "" => true =>
; ложное "установлена более поздняя версия". ISCC выполняется уже
; после cargo build, поэтому штамп ISPP всегда >= BUILD_DATE бинаря,
; и сравнение даёт false.
#define BuildDate GetDateTimeString('yyyy-mm-dd HH:nn', '-', ':')

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
UninstallDisplayName={#AppName}

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
; VegaConnect: клиент ищет себя через get_valid_subkey() (src\platform\windows.rs).
; Порядок поиска:
;   1) HKLM\Software\<app>\InstallState\<app>                       <- нам достаточно
;   2) HKLM\Software\Classes\Installer\Products\<GUID>              (MSI, не используем)
;   3) HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\<app> (wow / non-wow)
;
; Мы пишем ТОЛЬКО ветку (1). Дополнительная запись в Uninstall\<app>
; НЕ нужна и создаёт дубль в "Установка и удаление программ":
; Inno Setup уже создаёт свою запись под AppId={{GUID}}.
;
; BuildDate обязателен: is_installed_lower_version() читает его из того же
; subkey и сравнивает со своим BUILD_DATE. Без него get_reg() вернёт "",
; и клиент покажет "установлена более поздняя версия".
;
; Строка с deletekey — разовая уборка: у пользователей, ставивших предыдущую
; (сломанную) сборку, остался ключ Uninstall\VegaConnect. Сносим его при
; установке. Ключ не создаётся, только удаляется.

Root: HKLM; Subkey: "Software\{#AppName}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#AppName}\InstallState\{#AppName}"; ValueType: string; ValueName: "InstallLocation"; ValueData: "{app}";            Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#AppName}\InstallState\{#AppName}"; ValueType: string; ValueName: "BuildDate";       ValueData: "{#BuildDate}";    Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#AppName}\InstallState\{#AppName}"; ValueType: string; ValueName: "DisplayVersion";  ValueData: "{#AppVersion}";   Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\{#AppName}\InstallState\{#AppName}"; ValueType: string; ValueName: "Publisher";       ValueData: "{#AppPublisher}"; Flags: uninsdeletekey
Root: HKLM; Subkey: "Software\Microsoft\Windows\CurrentVersion\Uninstall\{#AppName}"; Flags: deletekey

[Code]
{ VegaConnect: после штатного удаления Inno Setup запускаем cleanup-vegaconnect.bat
  в --silent режиме. Скрипт добивает то, о чём Inno не знает:
    - старые папки %APPDATA%\RustDesk, %LOCALAPPDATA%\RustDesk, Program Files\RustDesk;
    - ярлыки на перенесённых рабочих столах (Shell Folders) и OneDrive;
    - записи RustDesk и VegaConnect в Uninstall, Software, Run, Services;
    - службы, firewall-правила, scheduled tasks.
  См. res/cleanup-vegaconnect.bat. }
{ VegaConnect: cleanup after uninstall.
  ExtractTemporaryFile works only at install time, not during uninstall.
  Two-phase approach:
    usUninstall      - copy cleanup-vegaconnect.bat from the install dir
                       into the temp dir, while files are still present;
    usPostUninstall  - the install dir has been removed by Inno, run
                       the .bat from the temp dir with --silent.
  This fixes the runtime error
  "Cannot call ExtractTemporaryFile function during Uninstall".

  IMPORTANT: do NOT use curly braces inside this comment. Inno Setup
  comments are brace-delimited with no nesting; any inner brace closes
  the comment early and breaks parsing. Use plain text. }
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