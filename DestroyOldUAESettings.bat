@echo Note: This will delete up your old winuae registry settings, which can interfere with the build system's winuae config files
@pause
@cd /d "%~dp0"
@copy toolchain\originalwinuae.ini winuae\winuae.ini
@if exist winuae\winuaebootlog.txt del winuae\winuaebootlog.txt
@if exist winuae\configurations\configuration.backup del winuae\configurations\configuration.backup
@if exist winuae\configurations\configuration.cache del winuae\configurations\configuration.cache
@if exist winuae\winuae rd winuae\winuae /q /s
@regedit "%~dp0toolchain\RemoveWinuaeRegistryKey.reg"