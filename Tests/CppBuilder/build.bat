@echo off
rem Builds and runs the C++Builder header check. See README.md.
rem
rem   build.bat [Win32|Win64|Win64x|all] [Debug|Release]
rem
rem Uses TwineCompile's jtmake when it is installed, otherwise MSBuild.
rem Set HPPCHECK_USE_MSBUILD=1 to use MSBuild anyway.

setlocal
set "HERE=%~dp0"
set "PLATS=%~1"
if "%PLATS%"=="" set "PLATS=Win32"
if /i "%PLATS%"=="all" set "PLATS=Win32 Win64 Win64x"
set "CFG=%~2"
if "%CFG%"=="" set "CFG=Debug"

if not "%BDS%"=="" goto :have_bds
for %%D in (37.0 23.0 22.0 21.0) do (
  if exist "%ProgramFiles(x86)%\Embarcadero\Studio\%%D\bin\rsvars.bat" (
    call "%ProgramFiles(x86)%\Embarcadero\Studio\%%D\bin\rsvars.bat" >nul
    goto :have_bds
  )
)
echo Could not find rsvars.bat - run this from a RAD Studio Command Prompt.
exit /b 2
:have_bds

rem --- choose the build tool ---------------------------------------------
set "JTMAKE="
if "%HPPCHECK_USE_MSBUILD%"=="1" goto :have_tool
for %%J in (jtmake.exe) do set "JTMAKE=%%~$PATH:J"
if defined JTMAKE goto :jt_version
set "JTDEFAULT=%ProgramFiles(x86)%\JomiTech\TwineCompile\jtmake.exe"
if exist "%JTDEFAULT%" set "JTMAKE=%JTDEFAULT%"
if not defined JTMAKE goto :have_tool

:jt_version
rem jtmake's -ide switch for this RAD Studio version; left out if unknown
for %%I in ("%BDS%") do set "BDSVER=%%~nxI"
set "JTIDE="
if "%BDSVER%"=="37.0" set "JTIDE=-ide130"
if "%BDSVER%"=="23.0" set "JTIDE=-ide120"
if "%BDSVER%"=="22.0" set "JTIDE=-ide110"
if "%BDSVER%"=="21.0" set "JTIDE=-ide104"

:have_tool
if defined JTMAKE (echo Building with TwineCompile: "%JTMAKE%" %JTIDE%) else (echo Building with MSBuild)

rem --- build and run each platform ---------------------------------------
set "FAILED="
for %%P in (%PLATS%) do call :one %%P || set "FAILED=1"
echo.
if defined FAILED (
  echo C++Builder header check FAILED.
  exit /b 1
)
echo C++Builder header check passed for: %PLATS%
exit /b 0

:one
echo.
echo === %1 %CFG% ===
if defined JTMAKE goto :one_jtmake
msbuild "%HERE%HppCheck.cbproj" /t:Build /p:Config=%CFG% /p:Platform=%1 /nologo /v:m
if errorlevel 1 exit /b 1
goto :one_run
:one_jtmake
"%JTMAKE%" %JTIDE% -B -pl"%1" -c"%CFG%" "%HERE%HppCheck.cbproj"
if errorlevel 1 exit /b 1
:one_run
"%HERE%%1\%CFG%\HppCheck.exe"
if errorlevel 1 exit /b 1
exit /b 0
