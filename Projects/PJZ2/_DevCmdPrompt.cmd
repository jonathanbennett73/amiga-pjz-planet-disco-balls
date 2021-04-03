@echo off
@set _oldpath=%cd%
cd /d %~dp0
call ..\..\toolchain\setpaths.bat

cmd.exe