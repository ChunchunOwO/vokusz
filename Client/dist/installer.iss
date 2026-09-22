; Inno Setup script for the Vokusz Windows installer.
; Built during CI — MyAppVersion is supplied by the release workflow via
;   ISCC.exe /DMyAppVersion=<version>
; Paths are relative to this .iss file (dist/), so the Flutter build output is
; one level up at ..\build\windows\x64\runner\Release\.

#define MyAppName "Vokusz"
#ifndef MyAppVersion
  #define MyAppVersion GetEnv('APP_VERSION')
  #if MyAppVersion == ""
    #define MyAppVersion "0.0.0"
  #endif
#endif
#define MyAppPublisher "vokusz"
#define MyAppURL "https://github.com/ChunchunOwO/vokusz"
#define MyAppExeName "vokusz.exe"

[Setup]
AppId={{B8F3A2D1-7C4E-4A9B-8D5F-1E6C3B2A0F47}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}/issues
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
OutputDir=..
OutputBaseFilename=vokusz-windows-x86_64-setup
SetupIconFile=icons\vokusz.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Classes\vokusz"; ValueType: string; ValueData: "URL:vokusz Protocol"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\vokusz"; ValueName: "URL Protocol"; ValueType: string; ValueData: ""
Root: HKCU; Subkey: "Software\Classes\vokusz\DefaultIcon"; ValueType: string; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\vokusz\shell\open\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\vokusz.package-manager"

[Code]
var
  PackageManager: String;

function InitializeSetup(): Boolean;
begin
  PackageManager := Lowercase(ExpandConstant('{param:PACKAGE_MANAGER|}'));
  Result := (PackageManager = '') or (PackageManager = 'winget') or
    (PackageManager = 'chocolatey');
  if not Result then
    MsgBox('Unsupported PACKAGE_MANAGER value.', mbError, MB_OK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and (PackageManager <> '') then
    if not SaveStringToFile(ExpandConstant('{app}\vokusz.package-manager'),
      PackageManager, False) then
      RaiseException('Could not record the package manager. Installation is incomplete.');
end;
