#2014-06-10 Michal Piasecki
#Script sorts files from directory getting them recursively, but:
#version 1.0
#0. Takes one parameter: a directory path from which files are taken
#1. Sorting is done with numbers so files named with a prefix containing version number separated with "." can be get in apropriate order
#2. A prefix version number must contain 4 places, ex: A.B.C.D
#3. Prefix must be separated from name with "_", ex: A.B.C.D_BlahBlah
#4. Only *.sql files are taken into consideration, ex: A.B.C.D_BlahBlah.sql
#5. Dos ERRORLEVEL is set to 1 when directory to recurse is not found, otherwise its 0
#Parameters:
# 0 - path to recurse directories
# 1 - list files having version number greater than specified here
#example: ./sortFilesByVersion.ps1 2.3.4
function pause{
	Write-Host "Press any key to continue ...";
	$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown");
}

function ResizeVersionArray{ Param([int[]]$arr)
	for($i=$($arr.Length-1); $i -le 2; $i++){
		$arr += 999;
	}
	return $arr
}

function IsVersionGreater{ Param([string]$version0, [string]$version1)
	$result = $false;
	$aver0 = $version0.Split(".");
	$aver1 = $version1.Split(".");
	
	$aver0 = ResizeVersionArray $aver0
	$aver1 = ResizeVersionArray $aver1
	<#Write-Host $aver0;
	Write-Host $aver1;
	$aver0 = ResizeVersionArray $aver0
	$aver1 = ResizeVersionArray $aver1
	Write-Host "$aver0 - $($aver0.Length-1)";
	Write-Host "$aver1 - $($aver1.Length-1)";
	pause;#>
	$ver0 = [string]::Format("{0:D4}-{1:D4}-{2:D4}-{3:D4}", [int]$($aver0[0]), [int]$($aver0[1]), [int]$($aver0[2]), [int]$($aver0[3]));
	$ver1 = [string]::Format("{0:D4}-{1:D4}-{2:D4}-{3:D4}", [int]$($aver1[0]), [int]$($aver1[1]), [int]$($aver1[2]), [int]$($aver1[3]));
	#Write-Output $ver0, $ver1
#	$version1
	#$ver1 = "{0:D4}-{1:D4}-{2:D4}-{3:D4}" -f [int]$($version1[0]), [int]$($version1[1]), [int]$($version1[2]), [int]$($version1[3]);
	if($ver0 -gt $ver1) {$result = $true}
	return $result;
}

if( Test-Path $Args[0] ){
	$fromVersion = $Args[1];
	Get-ChildItem $Args[0] -recurse -include *.sql | `
	 Where-Object {-not $_.PSIsContainer} | %{
		$ver = $_.Name.Substring(0, $_.Name.IndexOf("_"))
		if(IsVersionGreater $ver $fromVersion){
			$ver = $ver.Split(".");
			$ver = ResizeVersionArray $ver
			"{0:D4}-{1:D4}-{2:D4}-{3:D4};$_" -f [int]$($ver[0]), [int]$($ver[1]), [int]$($ver[2]), [int]$($ver[3]);
		}
	  } | `
	  Sort-Object | %{
		Write-Host """$($_.Split(";")[1])""";
	  }
	Exit 0;  
} else {
	Write-Host "Directory.does.NOT.exist.$($Args[0])";
	Exit 1;
}
