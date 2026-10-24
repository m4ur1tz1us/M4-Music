@echo off
call "%~1" x64
if errorlevel 1 exit /b 1
pushd "%~dp0build"
cl /nologo /LD /O2 /MT /EHsc /Fo:NativeStart.obj /Fe:M4MusicStart.dll "..\src\NativeStart.cpp" /link user32.lib
set "buildResult=%errorlevel%"
popd
exit /b %buildResult%
