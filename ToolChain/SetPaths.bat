@ECHO OFF

REM Get current folder with no trailing slash
SET ScriptDir=%~dp0
SET ScriptDir=%ScriptDir:~0,-1%

IF "X%AMITOOLCHAIN%"=="X%ScriptDir%" goto AlreadySet
SET AMITOOLCHAIN=%ScriptDir%
SET VBCC=%ScriptDir%\bin
SET PATH=%VBCC%;%AMITOOLCHAIN%;%AMITOOLCHAIN%\..;%PATH%

:AlreadySet
