@echo off
setlocal
    luajit "%~dp0plume-data\cli\init.lua" "%~dp0plume-data" %*
endlocal
exit /b %errorlevel%