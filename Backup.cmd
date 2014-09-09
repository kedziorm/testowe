@echo off
rem Scripts 7zipz MSSQL backup files (*.bak) with maximum compression and deletes original files
rem In the second step it deletes old archives if it's older than "maxageindays" variable

rem A path to scan (recursively)
set folder=c:\folder
rem Maximum allowed age in days
set maxageindays=500
rem pooit where 7zip is located
set zip=".\7Zip\7z.exe"


for /R %folder% %%1 in (*.bak) do (
	if exist "%%1" (
               echo.        %date% %time% processing: %%1 >> Backup.log.txt
               echo **** %date% %time% creating archive **** > "%%~d1%%~p1%%~n1.log.txt"
			   rem cleanup if exists
			   if exist "%%~d1%%~p1%%~n1.7z" del "%%~d1%%~p1%%~n1.7z" /Q
               rem create archive
               start "" /LOW /WAIT %zip% a -t7z -mx9 "%%~d1%%~p1%%~n1.7z" "%%1" >> "%%~d1%%~p1%%~n1.log.txt" 2>&1
               rem test newly created archive
               call Test7zAndDelete.bat "%%~d1%%~p1%%~n1.7z"
	)
)
echo.        %date% %time% cleaning up old files, older than %maxageindays% are deleted >> BackupsPackAndClean.log.txt
rem chech for too old files
for /R %folder% %%1 in (*.7z) do (
	if exist "%%1" (
		cscript.exe //NoLogo FileAgeAndDelete.vbs "%%1" %maxageindays% >> BackupsPackAndClean.log.txt
	)
