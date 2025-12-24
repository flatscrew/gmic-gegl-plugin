[Setup]
AppName=GMIC-GEGL
AppVersion={#Version}
AppPublisher=Flatscrew
DefaultGroupName=Gimp3
DefaultDirName={localappdata}\gegl-0.4\plug-ins
Compression=lzma
SolidCompression=yes
OutputBaseFilename=GMIC-GEGL-{#Version}-Setup-win64
OutputDir=.
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
DisableProgramGroupPage=yes
ChangesEnvironment=yes

[Files]
Source: "plugins\*.dll"; \
DestDir: "{localappdata}\gegl-0.4\plug-ins"; \
Flags: ignoreversion createallsubdirs recursesubdirs
