@echo off
setlocal
    "%~dp0plume-data\bin\luajit" "%~dp0plume-data\cli\init.lua" "%~dp0plume-data" %*
endlocal
exit /b %errorlevel%