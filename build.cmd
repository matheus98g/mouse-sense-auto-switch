@echo off
rem Builds bin\MouseSwitch.exe with the C# compiler that ships with .NET Framework 4.x
setlocal
set CSC=%WINDIR%\Microsoft.NET\Framework64\v4.0.30319\csc.exe
if not exist "%CSC%" set CSC=%WINDIR%\Microsoft.NET\Framework\v4.0.30319\csc.exe
if not exist "%~dp0bin" mkdir "%~dp0bin"
"%CSC%" /nologo /target:winexe /optimize+ /out:"%~dp0bin\MouseSwitch.exe" /r:System.Windows.Forms.dll /r:System.Drawing.dll /r:System.Web.Extensions.dll "%~dp0src\MouseSwitch.cs"
