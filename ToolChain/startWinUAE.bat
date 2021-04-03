@rem first parameter is the config to load
@rem second parameter is the kickstart (KS13,KS204,KS30,KS31 or AROS)
@rem third parameter is which executable to run on the harddrive (or if it ends with .adf/.dms then the disk image to start with) when booting the machine
@rem fourth parameter is the path to a second floppy disk image if it exists
@set oldpath_startwinuae=%cd%
@cd /d "%~dp0.."
@set UAEOtherParms=
@set exeName=%3
@set ExeNameWithoutQuotes=%exeName:"=%

@set extension=%ExeNameWithoutQuotes:~-4%

@if not exist dh0\t md dh0\t

@if /i '%extension%' EQU '.dms' goto bootDisk
@if /i '%extension%' NEQ '.adf' goto bootHDWithFile
:bootDisk

@rem check if parameter is added as ""
@if x%3 == x goto bootHD
@if %3 == "" goto bootHD

@set Disk1Path=%cd%\%3
@if not exist %Disk1Path% set Disk1Path=%3

@if x%4 == x goto bootSingleDisk
@if %4 == "" goto bootSingleDisk

@set Disk2Path=%cd%\%4
@if not exist %Disk2Path% set Disk2Path=%4

:bootDualDisk
@echo Booting Amiga in %1 mode, and starting disks %Disk1Path% and %Disk2Path%
@if not exist %Disk1Path% echo Disk %Disk1Path% not found
@if not exist %Disk1Path% goto Failed
@if not exist %Disk2Path% echo Disk %Disk2Path% not found
@if not exist %Disk2Path% goto Failed
@set UAEOtherParms=%UAEOtherParms% -s floppy0="%Disk1Path%" -s floppy1="%Disk2Path%" -s nr_floppies=2 -s floppy1type=1
@goto Boot

:bootSingleDisk
@echo Booting Amiga in %1 mode, and starting disk %Disk1Path%
@if not exist %Disk1Path% echo Disk %Disk1Path% not found
@if not exist %Disk1Path% goto Failed
@set UAEOtherParms=%UAEOtherParms% -s floppy0="%Disk1Path%"
@goto Boot

:bootHDWithFile
@set exeName=%3

:bootHD
@echo Booting Amiga in %1 mode, and starting executable %exeName% on the HD
@if exist %3 (
	@set exeName=t\tempexe
	@copy %3 dh0\t\tempexe >nul
)

@set exeName=%exeName:\=/%
@echo /|set /p =%exeName%>dh0\t\startup-sequence
@copy dh0\t\startup-sequence dh0\s\startup-sequence >nul
@if errorlevel 1 (
	echo Couldn't write dh0:s/startup-sequence
	goto failed
)

:Boot

@rem if on RDP we need extra params - Antiriad 2019
@if "%SESSIONNAME%" == "" goto nordp
@if "%SESSIONNAME%" == "Console" goto nordp
@set UAEOtherParms=%UAEOtherParms% -norawinput_all
:nordp

@set UAEConfig=%1
@set UAEConfigDescription=%1_Amiga_Forever
@set UAEConfigWindowTitle=%1_AF
@set KickStartOverride=
@if exist .\winuae\rom.key goto AmigaForever
@set UAEConfig=%1
@set UAEConfigDescription=%1_%2
@set UAEConfigWindowTitle=%1_%2
@if /i "%2" == "AROS" goto ArosNeedsNoKickstart
@if not exist .\winuae\Roms\%2.rom (
	echo Found neither AmigaForever roms nor %2.rom in the WinUAE folder - aborting
	goto Failed
)
@set KickStartOverride=-s kickstart_rom_file=.\Roms\%2.rom
:ArosNeedsNoKickStart
:AmigaForever
@REM @copy .\winuae\configurations\sharedconfig.txt+.\winuae\configurations\%UAEConfig%.uae .\winuae\configurations\_Temp.UAE >NUL
@REM @start .\winuae\winuae.exe -config=_Temp.UAE %UAEOtherParms%  -s config_description="%UAEConfigDescription%" -s config_window_title="%UAEConfigWindowTitle%" -s kickstart_rom_file_id="" %KickstartOverride%
@start .\winuae\winuae.exe -config=%UAEConfig%.uae %UAEOtherParms%  -s config_description="%UAEConfigDescription%" -s config_window_title="%UAEConfigWindowTitle%" -s kickstart_rom_file_id="" %KickstartOverride%

@cd /d %oldpath_startwinuae%
@goto Success
:Failed
@cd /d %oldpath_startwinuae%
@exit /b 1
:Success
@exit /b 0
