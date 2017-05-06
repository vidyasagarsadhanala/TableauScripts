@echo off
:: *********************** TabPublish.bat **********************************
::
:: This script will publish a workbook or data source it to 
:: a target server/site/project.
::
:: USAGE
:: tabpublish ["Full file path"] [Object type (workbook/datasource)]
::			  ["Published name"] [Server URL] [Site ID] ["Project name"] 
::			  [Refresh after publishing? (yes/no)]
::			  [Server username] [Server password] [DB username] [DB password]
:: 
:: e.g.: tabpublish "C:\Users\rstryker\Desktop\Temp\Orders.tds" datasource "Orders" http://localhost QA "Data Sources" no admin admin superstore_user superstore_user

::	
:: Directory info
::

set TAB_CMD="C:\Tabcmd\Command Line Utility\tabcmd"
set LOG_DIR=E:\Scripts\logs
set LOG_PURGE_INTERVAL_DAYS=1

::
:: User Input
::

set Object_File=%1
set Object_Type=%2
set Object_Published_Name=%3
set Target_Server=%4
set Target_Site=%5
set Target_Project=%6
set Do_Refresh=%7
set Server_Username=%8
set Server_Password=%9
SHIFT
set DB_Username=%9
SHIFT
set DB_Password=%9

::
:: Execute
::

:Set Log file name
for /f "tokens=1-4 delims=/ " %%i in ("%date%") do set datestring=%%i%%j%%k
set logfile=%LOG_DIR%\TabMigrate_%datestring%.log

echo Begin publication %date% %time% %USERNAME%   		>> %logfile% 

:Login to Target Server
echo Logging in to %Target_Server% >> %logfile%
%TAB_CMD% login -u %Server_Username% -p %Server_Password% -s %Target_Server% -t %Target_Site%	>> %logfile%

:Publish Object
echo Publishing %Object_File% >> %logfile%
echo Type: %Object_Type% >> %logfile%
echo Name: %Object_Published_Name%  >> %logfile%
echo Project: %Target_Project% >> %logfile%

%TAB_CMD% publish %Object_File% --name %Object_Published_Name% --project %Target_Project% --db-username %DB_Username% --db-password %DB_Password% --timeout 300 --overwrite --tabbed --save-db-password --no-prompt --no-certcheck >> %logfile%

:Refresh if necessary
if %Do_Refresh%==YES set Do_Refresh=yes
if %Do_Refresh%==yes (
	echo Refreshing %Object_Name% >> %logfile%
	%TAB_CMD% refreshextracts --%Object_Type% %Object_Published_Name% --project %Target_Project% --no-certcheck  >> %logfile%
)

:Logout of Target Server
echo Logging out of %Target_Server% >> %logfile%
%TAB_CMD% logout >> %logfile%

:Delete Old Files
echo Deleting old logs >> %logfile%
forfiles /p "%LOG_DIR%" /m TabMigrate*.log /d -%LOG_PURGE_INTERVAL_DAYS% /C "cmd /c del @path" 2>nul >> %logfile%
