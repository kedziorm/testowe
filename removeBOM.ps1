#script converts file given in first parameter removing UTF bom markers end UTF encoding
#set-executionpolicy remotesigned
#Write-Output "Removing UTF8 Encoding from: $($Args[0])";
#$bommarker = [CHAR][BYTE]239+[CHAR][BYTE]187+[CHAR][BYTE]191
#[byte[]]$content = [io.file]::ReadAllBytes($Args[0]); 
#$Utf8NoBomEncoding = (New-Object System.Text.UTF8Encoding -ArgumentList $false).GetString($content); 
#[io.file]::WriteAllText($Args[1], $Utf8NoBomEncoding);
Get-Content $Args[0] | Out-File -FilePath $Args[1] -Encoding "ASCII" -Force
