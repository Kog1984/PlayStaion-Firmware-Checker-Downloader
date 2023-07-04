#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Martz90-Circle-Addon2-Playstation.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;#################################################################################################################################################
;# PlayStaion Firmware Checker & Downloader
;#
;# What does it do? Compares byte file size of PS4/PS5 website update files vs your download version of update files, download if size difference
;#
;# BY      : KEITH HOPKINS / CONSOLE NINJA
;# WEBSITE : https://consolerepair.xyz/
;#         : https://www.consoleninja.co.uk/
;##################################################################################################################################################
#include <AutoItConstants.au3>
#include <Misc.au3>
#include <Inet.au3>
#include <InetConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>

$TITLE = "PlayStaion Firmware Checker & Downloader"

; Test to make sure there is not already an instance running.
if _Singleton($TITLE, 1) = 0 Then
    Msgbox(64, $TITLE, "The program is already running.")
    Exit
EndIf

;PS4
$console= "PS4"
$update_dir = @MyDocumentsDir&"\PS4 FW"
$filename = "PS4UPDATE.PUP"
$firmware_host = "https://www.playstation.com/en-gb/support/hardware/ps4/system-software/"
If FileExists ($update_dir) = 0 Then DirCreate ( $update_dir )
If FileExists ($update_dir&"\sysupdate\") = 0 Then DirCreate ( $update_dir&"\sysupdate\" )
If FileExists ($update_dir&"\reinstallation") = 0 Then DirCreate ( $update_dir&"\reinstallation" )

ScrapeLinks($console)

;PS5
$console = "PS5"
$update_dir = @MyDocumentsDir&"\PS5 FW"
$filename = "PS5UPDATE.PUP"
$firmware_host = "https://www.playstation.com/en-gb/support/hardware/ps5/system-software/"
If FileExists ($update_dir) = 0 Then DirCreate ( $update_dir )
If FileExists ($update_dir&"\sysupdate\") = 0 Then DirCreate ( $update_dir&"\sysupdate\" )
If FileExists ($update_dir&"\reinstallation") = 0 Then DirCreate ( $update_dir&"\reinstallation")

ScrapeLinks($console)



Func ScrapeLinks($console)
	; InetGet downloads a file in the background.
	; The AutoIt script checks in a loop for the download to complete.


		; Save the downloaded file to the temporary folder.
        Local $sFilePath = _WinAPI_GetTempFileName(@TempDir)

        ; Download the file in the background with the selected option of 'force a reload from the remote site.'
        Local $hDownload = InetGet($firmware_host, $sFilePath, $INET_FORCERELOAD, $INET_DOWNLOADWAIT)
		If $hDownload = 0 Then Exit ;Quit offline

        ; Retrieve the number of total bytes received and the filesize.
        Local $iBytesSize = InetGetInfo($hDownload, $INET_DOWNLOADREAD)
        Local $iFileSize = FileGetSize($sFilePath)

        ; Close the handle returned by InetGet.
        InetClose($hDownload)

        ; Open the file for reading and store the handle to a variable.
        Local $hFileOpen = FileOpen($sFilePath, $FO_READ)
        If $hFileOpen = -1 Then
                MsgBox($MB_SYSTEMMODAL, "", "An error occurred when reading the file.")
                Return False
        EndIf

        ; Read the contents of the file using the handle returned by FileOpen.
        Local $sFileRead = FileRead($hFileOpen)
Select
	Case $console = "PS4"
		Local $aArray = StringRegExp($sFileRead, 'https://pc.ps4.update.playstation.net/update/ps4/image/.*?/PS4UPDATE.PUP', 3)
	Case $console = "PS5"
		Local $aArray = StringRegExp($sFileRead, 'https://pc.ps5.update.playstation.net/update/ps5/official/.*?/PS5UPDATE.PUP', 3)
EndSelect
		For $vElement In $aArray
                Firmware_DL($vElement,$console)
        Next
        ; Close the handle returned by FileOpen.
        FileClose($hFileOpen)
		FileDelete($sFilePath)
EndFunc   ;==>ScrapeLinks



Func Firmware_DL($firmware_dl,$console)
	ConsoleWrite($firmware_dl&@CRLF)
$online_update = InetGetSize ( $firmware_dl ,1 )
If $online_update = 0 Then Exit ;Quit offline
ConsoleWrite($online_update&@CRLF);Filesize in bytes
If StringInStr($firmware_dl,"rec") And $console = "PS4" Then
	$update_zip = $update_dir&"\reinstallation\PS4UPDATE.PUP"
	$text = "Re-Installation"
EndIf
If StringInStr($firmware_dl,"sys") And $console = "PS4" Then
	$update_zip = $update_dir&"\sysupdate\PS4UPDATE.PUP"
		$text = "System Update"
EndIf
If StringInStr($firmware_dl,"rec") And $console = "PS5" Then
	$update_zip = $update_dir&"\reinstallation\PS5UPDATE.PUP"
	$text = "Re-Installation"
EndIf
If StringInStr($firmware_dl,"sys") And $console = "PS5" Then
	$update_zip = $update_dir&"\sysupdate\PS5UPDATE.PUP"
		$text = "System Update"
EndIf
$cache_update = FileGetSize ( $update_zip )
ConsoleWrite($cache_update&@CRLF);Filesize in bytes
If $online_update <> $cache_update Then
	If Not IsDeclared("iMsgBoxAnswer") Then Local $iMsgBoxAnswer
	$iMsgBoxAnswer = MsgBox(8193,$TITLE,"A New " & $text& " File is Available will start Downloading "&@CRLF&"Please wait this may take upto 10-30 mins",30)
	Select
		Case $iMsgBoxAnswer = 1 ;OK
			ConsoleWrite("Downloading "&$console&" "&$text&" File........"&@CRLF)
			if FileExists($update_zip) = 1 Then
				If FileDelete($update_zip) = 0 Then
					MsgBox(0,"Error","Failure to delete "&$update_zip)
					Exit
				EndIf
			EndIf
			$current_download = InetGet ( $firmware_dl, $update_zip ,1,1 )
			ProgressOn($TITLE, "Downloading "&$console& " " &$text&" File", "0%", -1, -1, BitOR($DLG_NOTONTOP, $DLG_MOVEABLE))
			Do
			$current_size = InetGetInfo ($current_download,0)
			$progess = round(($current_size/$online_update)*100,0)
			ProgressSet($progess,Round($current_size/1024/1024,0)&"MB of "&round($online_update/1024/1024,0)&"MB")
			;ConsoleWrite($current_size&@CRLF)
			;ConsoleWrite($progess&@CRLF)
			Sleep(2500)
				If InetGetInfo($current_download,4) <> 0 Then
					MsgBox(0,$TITLE,"An error has occurred!"&@CRLF&"Please check your internet connection and try again.")
					Exit
				EndIf
			Until InetGetInfo ($current_download,3) = "TRUE"
			ProgressSet(100, "Done", "Complete")

			; Close the progress window.
			ProgressOff()
	EndSelect
Else
SplashTextOn($TITLE, $console&" "&$text&" File up to date", 600, 70, -1, -1, $DLG_TEXTVCENTER, "", 24)
Sleep(3000)
SplashOff()
EndIf
EndFunc
