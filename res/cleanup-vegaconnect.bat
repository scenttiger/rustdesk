@echo off
setlocal EnableExtensions
if /I "%~1"=="--silent" (set "SILENT=1") else (set "SILENT=0")
set "LOG=%TEMP%\vegaconnect-cleanup.log"
if "%SILENT%"=="0" title VegaConnect / RustDesk cleanup

net session >nul 2>&1
if errorlevel 1 (
    if "%SILENT%"=="1" ( echo [!] not admin >> "%LOG%" & exit /b 1 )
    echo [!] Run as Administrator ^(right-click -^> "Run as administrator"^).
    pause
    exit /b 1
)

echo === VegaConnect / RustDesk cleanup %DATE% %TIME% === > "%LOG%"

if "%SILENT%"=="0" ( echo === VegaConnect / RustDesk cleanup === & echo. )

if "%SILENT%"=="0" echo [1/8] Killing processes...
echo [1/8] Killing processes... >> "%LOG%"
for %%P in (vegaconnect.exe rustdesk.exe vegaconnect-service.exe rustdesk-service.exe) do taskkill /F /IM %%P >> "%LOG%" 2>&1
timeout /t 2 /nobreak >nul

if "%SILENT%"=="0" echo [2/8] Stopping and deleting services...
echo [2/8] Stopping and deleting services... >> "%LOG%"
for %%S in (VegaConnect vegaconnect RustDesk rustdesk RustDeskService rustdesk-service vegaconnect-service) do (
    sc query %%S >nul 2>&1 && (
        net stop %%S >> "%LOG%" 2>&1
        sc delete %%S >> "%LOG%" 2>&1
    )
)

if "%SILENT%"=="0" echo [3/8] Removing app folders...
echo [3/8] Removing app folders... >> "%LOG%"
for %%D in (
    "%APPDATA%\RustDesk"
    "%APPDATA%\VegaConnect"
    "%LOCALAPPDATA%\RustDesk"
    "%LOCALAPPDATA%\VegaConnect"
    "%ProgramData%\RustDesk"
    "%ProgramData%\VegaConnect"
    "%USERPROFILE%\.rustdesk"
    "%USERPROFILE%\.vegaconnect"
    "C:\Program Files\RustDesk"
    "C:\Program Files\VegaConnect"
    "C:\Program Files (x86)\RustDesk"
    "C:\Program Files (x86)\VegaConnect"
    "C:\Windows\System32\config\systemprofile\AppData\Roaming\RustDesk"
    "C:\Windows\System32\config\systemprofile\AppData\Roaming\VegaConnect"
) do (
    if exist %%D (
        if "%SILENT%"=="0" echo   - %%~D
        echo   rm %%~D >> "%LOG%"
        attrib -r -h -s %%D\*.* /s /d >nul 2>&1
        rmdir /S /Q %%D >nul 2>&1
    )
)

if "%SILENT%"=="0" echo [4/8] Removing desktop shortcuts...
echo [4/8] Removing desktop shortcuts... >> "%LOG%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $sf='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'; $cur=(Get-ItemProperty -LiteralPath $sf -Name Desktop -EA 0).Desktop; $desks=@(); if($cur){$desks+=$cur}; Get-ChildItem 'C:\Users' -Directory -EA 0 | ForEach-Object { $desks += (Join-Path $_.FullName 'Desktop'); $desks += (Join-Path $_.FullName 'OneDrive\Desktop'); $desks += (Join-Path $_.FullName 'OneDrive - *\Desktop') }; $desks += (Join-Path $env:PUBLIC 'Desktop'); $desks = $desks | Select-Object -Unique; foreach($d in $desks){ if(Test-Path -LiteralPath $d){ Get-ChildItem -LiteralPath $d -Force -EA 0 | Where-Object { $_.Extension -eq '.lnk' -and $_.Name -match 'rustdesk|vegaconnect' } | ForEach-Object { Write-Host ('  del ' + $_.FullName); $_.IsReadOnly=$false; Remove-Item -LiteralPath $_.FullName -Force -EA 0 } } }" >> "%LOG%" 2>&1

if "%SILENT%"=="0" echo [5/8] Removing Start Menu folders...
echo [5/8] Removing Start Menu folders... >> "%LOG%"
for /d %%U in ("C:\Users\*") do (
    rmdir /S /Q "%%U\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\RustDesk" >nul 2>&1
    rmdir /S /Q "%%U\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\VegaConnect" >nul 2>&1
)
rmdir /S /Q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\RustDesk" >nul 2>&1
rmdir /S /Q "%ProgramData%\Microsoft\Windows\Start Menu\Programs\VegaConnect" >nul 2>&1

if "%SILENT%"=="0" echo [6/8] Cleaning registry keys...
echo [6/8] Cleaning registry keys... >> "%LOG%"
for %%K in (
    "HKCU\Software\RustDesk"
    "HKCU\Software\VegaConnect"
    "HKLM\Software\RustDesk"
    "HKLM\Software\VegaConnect"
    "HKLM\Software\WOW6432Node\RustDesk"
    "HKLM\Software\WOW6432Node\VegaConnect"
    "HKLM\SYSTEM\CurrentControlSet\Services\RustDesk"
    "HKLM\SYSTEM\CurrentControlSet\Services\VegaConnect"
    "HKLM\SYSTEM\CurrentControlSet\Services\RustDeskService"
    "HKLM\SYSTEM\CurrentControlSet\Services\vegaconnect-service"
) do reg delete %%K /f >> "%LOG%" 2>&1

reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v RustDesk /f >> "%LOG%" 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v VegaConnect /f >> "%LOG%" 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v RustDesk /f >> "%LOG%" 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v VegaConnect /f >> "%LOG%" 2>&1

if "%SILENT%"=="0" echo [7/8] Removing Uninstall entries...
echo [7/8] Removing Uninstall entries... >> "%LOG%"
for %%H in (
    "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
) do (
    for /f "tokens=*" %%K in ('reg query %%H /s /f "RustDesk" 2^>nul ^| findstr /I "HKEY"') do reg delete "%%K" /f >> "%LOG%" 2>&1
    for /f "tokens=*" %%K in ('reg query %%H /s /f "VegaConnect" 2^>nul ^| findstr /I "HKEY"') do reg delete "%%K" /f >> "%LOG%" 2>&1
)

if "%SILENT%"=="0" echo [8/8] Firewall rules + scheduled tasks...
echo [8/8] Firewall rules + scheduled tasks... >> "%LOG%"
for %%N in ("RustDesk" "rustdesk" "VegaConnect" "vegaconnect") do netsh advfirewall firewall delete rule name=%%N >> "%LOG%" 2>&1
schtasks /Delete /TN "RustDesk" /F >> "%LOG%" 2>&1
schtasks /Delete /TN "VegaConnect" /F >> "%LOG%" 2>&1

if "%SILENT%"=="0" (
    echo.
    echo === Done. Log: %LOG% ===
    pause
) else (
    echo === Done. Log: %LOG% >> "%LOG%"
)
exit /b 0