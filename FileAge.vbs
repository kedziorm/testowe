if WScript.Arguments.Count < 2 then
    WScript.Echo "Missing parameters"
	WScript.Echo "Give two!"
	WScript.Echo "1 - a filename to check [string]"
	WScript.Echo "2 - max age in days, if age is greater then file is deleted [integer]"
else
	Set FSO = CreateObject("Scripting.FileSystemObject")
	filename = WScript.Arguments(0)
	maxageindays = CLng(WScript.Arguments(1))
	if FSO.FileExists(filename) then	
		LastModified = FSO.GetFile(filename).DateLastModified
		DateDifference = CLng(DateDiff("d",LastModified, Now()))
		if (DateDifference >= maxageindays) then
			WScript.Echo "File: " & filename & " age " & DateDifference & " days is older than: " & maxageindays & " - deleting"
			FSO.DeleteFile(filename)
		End if
	end if
end if
