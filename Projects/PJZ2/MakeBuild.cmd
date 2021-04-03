@rem Build functions

@echo off

@echo off
@set _oldpath=%cd%
cd /d %~dp0
call ..\..\toolchain\setpaths.bat

make %1 %2 %3 %4 %5 %6 %7 %8 %9

if errorlevel 1 goto failed

echo SUCCESS
cd /d %_oldpath%
exit /b 0

:failed
echo FAILED
cd /d %_oldpath%
exit /b 1