@echo off

REM
REM get date in following format - day name - day - month name - year
REM

for /f "delims=" %%a in ('wmic OS Get localdatetime ^| find "."') do set dt=%%a
set year=%dt:~0,4%
set month=%dt:~4,2%
set day=%dt:~6,2%
if %month%==01 set month=Jan
if %month%==02 set month=Feb
if %month%==03 set month=Mar
if %month%==04 set month=Apr
if %month%==05 set month=May
if %month%==06 set month=Jun
if %month%==07 set month=Jul
if %month%==08 set month=Aug
if %month%==09 set month=Sep
if %month%==10 set month=Oct
if %month%==11 set month=Nov
if %month%==12 set month=Dec

For /f %%# In ('WMIC Path Win32_LocalTime Get DayOfWeek^|Findstr [1-7]') Do ( 
        Set DOW=%%#)
if %dow%==1 set dow=Monday
if %dow%==2 set dow=Tuesday
if %dow%==3 set dow=Wednesday
if %dow%==4 set dow=Thursday
if %dow%==5 set dow=Friday
if %dow%==6 set dow=Saturday
if %dow%==7 set dow=Sunday

set getData=%dow% - %day%-%month%-%year%
echo %getData%

@echo on
