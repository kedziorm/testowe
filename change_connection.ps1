Function change_connection($FilePath,$oldserver,$newserver)

{
#This PowerShell function amend connection settings within Excel spreadsheet

#Open Excel spreadsheet - please provide full path
$Excel = New-Object -comobject Excel.Application
$ExcelWorkbook = $Excel.workbooks.open($FilePath) 

#Get current Connection string
#Assumption - only one Connection
$m=$ExcelWorkbook.Connections.Item(1).OLEDBConnection.Connection.ToString()

#set new ConnectionString
$m=$m.Replace($oldserver,$newserver)
$ExcelWorkbook.Connections.Item(1).OLEDBConnection.Connection=$m

$ExcelWorkbook.Save()
$ExcelWorkbook.Close()

$Excel.Quit()

}
