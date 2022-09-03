@echo off

echo Prepare directories...
set script_dir=%~dp0
set src_dir=%script_dir%..
set build_dir="%script_dir%\build"
mkdir "%build_dir%"

echo Webview directory: %src_dir%
echo Build directory: %build_dir%

echo Looking for vswhere.exe...
set "vswhere=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%vswhere%" set "vswhere=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%vswhere%" (
	echo ERROR: Failed to find vswhere.exe
	exit /b 1
)
echo Found %vswhere%

echo Looking for VC...
for /f "usebackq tokens=*" %%i in (`"%vswhere%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do (
  set vc_dir=%%i
)
if not exist "%vc_dir%\Common7\Tools\vsdevcmd.bat" (
	echo ERROR: Failed to find VC tools x86/x64
	exit /b 1
)
echo Found %vc_dir%

call "%vc_dir%\Common7\Tools\vsdevcmd.bat" -arch=x86 -host_arch=x64

echo Building webview.dll (x86)
@REM mkdir "%src_dir%\dll\x86"
cl /D "WEBVIEW_API=__declspec(dllexport)" ^
	/I "%script_dir%\pkg\microsoft.web.webview2.1.0.664.37\build\native\include" ^
	"%script_dir%\pkg\microsoft.web.webview2.1.0.664.37\build\native\x86\WebView2Loader.dll.lib" ^
	/std:c++17 /EHsc "/Fo%build_dir%"\ ^
	"%src_dir%\webview-windows.cc" /link /DLL "/OUT:%build_dir%\webview_x86.dll" || exit \b
copy "%build_dir%\webview_x86.dll" "%script_dir%\dlls\x86"
@REM copy "%script_dir%\pkg\microsoft.web.webview2.1.0.664.37\build\native\x86\WebView2Loader.dll" "%script_dir%\dlls\x86"

call "%vc_dir%\Common7\Tools\vsdevcmd.bat" -arch=x64 -host_arch=x64
echo Building webview.dll (x64)
@REM mkdir "%src_dir%\dll\x64"
cl /D "WEBVIEW_API=__declspec(dllexport)" ^
	/I "%script_dir%\pkg\microsoft.web.webview2.1.0.664.37\build\native\include" ^
	"%script_dir%\pkg\microsoft.web.webview2.1.0.664.37\build\native\x64\WebView2Loader.dll.lib" ^
	/std:c++17 /EHsc "/Fo%build_dir%"\ ^
	"%src_dir%\webview-windows.cc" /link /DLL "/OUT:%build_dir%webview_x64.dll" || exit \b
copy "%build_dir%\webview_x64.dll" "%script_dir%\dlls\x64"
@REM copy "%script_dir%\pkg\microsoft.web.webview2.1.0.664.37\build\native\x64\WebView2Loader.dll" "%script_dir%\dlls\x64"

@REM echo Building webview.exe (x64)
@REM cl /I "%src_dir%\script\microsoft.web.webview2.1.0.664.37\build\native\include" ^
@REM 	"%src_dir%\script\microsoft.web.webview2.1.0.664.37\build\native\x64\WebView2Loader.dll.lib" ^
@REM 	/std:c++17 /EHsc "/Fo%build_dir%"\ ^
@REM 	"%src_dir%\main.cc" /link "/OUT:%build_dir%\webview.exe" || exit \b

@REM echo Building webview_test.exe (x64)
@REM cl /I "%src_dir%\script\microsoft.web.webview2.1.0.664.37\build\native\include" ^
@REM 	"%src_dir%\script\microsoft.web.webview2.1.0.664.37\build\native\x64\WebView2Loader.dll.lib" ^
@REM 	/std:c++17 /EHsc "/Fo%build_dir%"\ ^
@REM 	"%src_dir%\webview_test.cc" /link "/OUT:%build_dir%\webview_test.exe" || exit \b

@REM echo Running Go tests
@REM cd /D %src_dir%
@REM set CGO_ENABLED=1
@REM set "PATH=%PATH%;%src_dir%\dll\x64;%src_dir%\dll\x86"
@REM go test || exit \b
