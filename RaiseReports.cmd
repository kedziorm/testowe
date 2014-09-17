@echo off
rem Script brings up an OmniCubes Reports database version using scripts from VSDB Project
rem Takes one parameter - root directory of OmniCubes directory
rem
rem ex: RaiseReportsVersion C:\Users\dummmyuser\Projects\.net\ddi@mb\OmniCubes
rem 
rem Returned ErrorLevel values
rem 0 - ok, no errors
rem 2 - DB version number is EMPTY!
rem 3 - Wrong database type
rem 4 - SQL script execution failed
rem 5 - Conversion of sql script with powershell failed 
rem 6 - Directory where sql scripts are expected does not exist.

rem !!!DEBUG - this part is only necessary when running outside Jenkins. Jenkins sets there variables by itself.
rem Variable SAFEMODE prevents applying any changes to a database, only scripts are generated when it's defined
rem set SAFEMODE=ON
rem MSSQL Server where changes are applied:
rem SET BY JENKINS: set DATABASESERVER=MBSLOSQL001
rem Project name:
rem SET BY JENKINS: set PROJECT=BNB
rem Project type (ex: Preview, leave empty for Live: set PROJECTTYPE=)
rem SET BY JENKINS: set PROJECTTYPE=Preview
rem A directory where git repo is cloned, it should point to a root directory without ending slash:
rem set WORKSPACE=C:\Users\piaseckim\Projects\.net with a space in name\ddi@mb\OmniCubes
rem SET BY JENKINS: set WORKSPACE=c:\Users\piaseckim\Projects\.net\ddi@mb\OmniCubes-RedBull
rem !!!DEBUG

SETLOCAL enableextensions enabledelayedexpansion
rem Configuration variables:
rem Directory where upgrading scripts are located:
set scriptslocation=%WORKSPACE%\OmniCubes.Database.Reports\Scripts\UpdateScripts
rem Part of SQLCMD command that determine db connection user and password
rem set dbuserandpassword=-U jenkins -P jenkinspassword
set dbuserandpassword=-E
rem Name of the SQL Server
set dbserver=%DATABASESERVER%
rem Name of the database to upgrade
set dbname=%PROJECT%Reports
if /I NOT [%PROJECTTYPE%]==[Live] set dbname=%PROJECT%Reports_%PROJECTTYPE%
rem Name of the database type (this is given just for additional checking so scripts doesn't break anything when run on other than desired type of DB)
set expectedDBtype=OmniCubesReports

IF DEFINED SAFEMODE echo.!!!Safe MODE is on - NO CHANGES TO Database!!!
echo Running scripts from: 
echo.    %scriptslocation%
echo.    Database: %dbserver%.%dbname%
echo.

set sqlcmdexe=sqlcmd.EXE
set sqlcmdoutput=.\%dbserver%.%dbname%.log
set sqlcmdinput=.\%dbserver%.%dbname%.sql
set sqlcmdparams=-S %dbserver% -d %dbname% %dbuserandpassword% -h -1 -t 180 -l 180 -c GO -b -i %sqlcmdinput% -o %sqlcmdoutput%
set sqlcmdsinglequeryparams=-S %dbserver% -d %dbname% %dbuserandpassword% -h -1 -t 180 -l 180 -W -w 2000 -Q
set sqlcmd=%sqlcmdexe% %sqlcmdparams%

set sqlgetdbtype="SET NOCOUNT ON; SELECT CONVERT(NVARCHAR(128),value) FROM sys.extended_properties WHERE name = 'meta_dbType'"
set sqlgetversion="SET NOCOUNT ON; SELECT CONVERT(NVARCHAR(128),value) FROM sys.extended_properties WHERE name = 'meta_schemaVersion'"

rem check scripts directory exists
if NOT EXIST "%scriptslocation%" GOTO ERROR_NO_REPO_DIRECTORY
rem check connection
%sqlcmdexe% %sqlcmdsinglequeryparams% %sqlgetversion% > nul
if %ERRORLEVEL% NEQ 0 GOTO END
rem determine dbtype
for /f "tokens=1" %%v in ('%sqlcmdexe% %sqlcmdsinglequeryparams% %sqlgetdbtype%') do (
set sqldbtype=%%v
)
if /I NOT [%sqldbtype%]==[%expectedDBtype%] GOTO ERROR_WRONG_DBTYPE
set %sqldbtype% = %sqldbtype%x
rem determine version 
for /f "tokens=1" %%v in ('%sqlcmdexe% %sqlcmdsinglequeryparams% %sqlgetversion%') do (
set currentversion=%%v
)
if [%currentversion%]==[] GOTO ERROR_VERSION_EMPTY
echo Current DB version %dbserver%.%dbname% = %currentversion%
if EXIST %sqlcmdinput% DEL %sqlcmdinput% /Q
rem let's do a backup
%sqlcmdexe% %sqlcmdsinglequeryparams% "BACKUP DATABASE [%dbname%] TO DISK = 'E:\SqlBackup\Manual\%dbname%_%currentversion%.bak' WITH INIT, SKIP"
echo Print '***************************************** START ***********************************************' >> %sqlcmdinput%
echo BEGIN TRANSACTION UPVERSION >> %sqlcmdinput%
echo GO >> %sqlcmdinput%
echo SET NUMERIC_ROUNDABORT OFF >> %sqlcmdinput%
echo GO >> %sqlcmdinput%
echo SET ANSI_PADDING,ANSI_WARNINGS,CONCAT_NULL_YIELDS_NULL ,ARITHABORT,QUOTED_IDENTIFIER,ANSI_NULLS ON >> %sqlcmdinput%
echo GO >> %sqlcmdinput%
set pwshlcmd=powershell -NoProfile -ExecutionPolicy Unrestricted -File .\sortFilesByVersion.ps1 "%scriptslocation%" %currentversion%
rem echo.DEBUG
rem echo.DEBUG About to run: 
rem echo %pwshlcmd%
rem echo.DEBUG
for /F "delims=" %%i in ('%pwshlcmd%') do (
				echo. Script taken:  %%~Ni%%~xi
				echo Print '************* executing: %%~Ni%%~xi ***************' >> %sqlcmdinput%
				echo. >> %sqlcmdinput%
				rem echo.DEBUG powershell -ExecutionPolicy Unrestricted -File .\removeBOM.ps1 %%i .\%%~Ni%%~xi
				powershell -ExecutionPolicy Unrestricted -File .\removeBOM.ps1 %%i .\%%~Ni%%~xi
				if %ERRORLEVEL% NEQ 0 GOTO ERROR_SCRIPT_CONVERSION
				type .\%%~Ni%%~xi >> %sqlcmdinput%
				del .\%%~Ni%%~xi /Q
				echo. >> %sqlcmdinput%
)
rem here's a final commit
echo COMMIT TRANSACTION UPVERSION >> %sqlcmdinput%	
echo GO >> %sqlcmdinput%
rem Here's executed whole script
IF NOT DEFINED SAFEMODE %sqlcmd%
if %ERRORLEVEL% NEQ 0 GOTO ERROR_EXECUTING_SCRIPT
GOTO END
:ERROR_VERSION_EMPTY
	echo.	ERROR. DB version is EMPTY! EXITING!
	set ERRORLEVEL=2
	GOTO END
:ERROR_WRONG_DBTYPE	
	echo.	ERROR. Expected DB type is "%expectedDBtype%", found "%sqldbtype%"
	set ERRORLEVEL=3
	GOTO END
:ERROR_EXECUTING_SCRIPT	
	echo.	ERROR. Script execution failed: 
	echo.   Script: %sqlcmdinput%
	echo ***********************************************************************************************************
	type %sqlcmdinput%
	echo.
	echo.   Log: %sqlcmdoutput% 
	echo ***********************************************************************************************************
	type %sqlcmdoutput% 
	set ERRORLEVEL=4
	GOTO END
:ERROR_SCRIPT_CONVERSION
	echo.	ERROR. Conversion of sql script failed 
	echo.   sql script: %sqlcmdinput% 
	set ERRORLEVEL=5
	GOTO END	
:ERROR_NO_REPO_DIRECTORY
	echo.	ERROR. Directory where sql scripts are expected does not exist.
	echo.   Expected dir: %scriptslocation% 
	set ERRORLEVEL=6
	GOTO END	
:END
rem if exist %sqlcmdinput% del %sqlcmdinput% /Q
rem if exist %sqlcmdoutput% del %sqlcmdoutput% /Q
EXIT %ERRORLEVEL%
