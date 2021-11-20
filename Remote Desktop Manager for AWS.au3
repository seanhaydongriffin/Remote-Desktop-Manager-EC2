#include <AutoItConstants.au3>
#include <SQLite.au3>
#Include <_XMLDomWrapper2.au3>

Const $remote_desktop_manager_path = "C:\Users\sgriffin\AppData\Local\Devolutions\RemoteDesktopManagerFree"
Local $aResult, $iRows, $iColumns, $iRval



Local $iPID = Run('aws ec2 describe-instances --query "Reservations[*].Instances[*].{Name:Tags[?Key==`Name`]|[0].Value,PublicDns:PublicDnsName}" --output text', @ScriptDir, @SW_HIDE, $STDOUT_CHILD)

    ProcessWaitClose($iPID)

    Local $sOutput = StdoutRead($iPID)
	ConsoleWrite('@@ Debug(' & @ScriptLineNumber & ') : $sOutput = ' & $sOutput & @CRLF & '>Error code: ' & @error & @CRLF) ;### Debug Console

Local $arr = _DBG_StringSplit2d($sOutput, "	")
;_ArrayDisplay($arr)


_SQLite_Startup()
Local $hDskDb = _SQLite_Open($remote_desktop_manager_path & "\Connections.db")

If @error Then
    MsgBox($MB_SYSTEMMODAL, "SQLite Error", "Can't open permanent Database!")
    Exit -1
EndIf

for $i = 0 to (UBound($arr) - 1)

	$iRval = _SQLite_GetTable2d(-1, "SELECT DATA FROM Connections WHERE Name = '" & $arr[$i][0] & "';", $aResult, $iRows, $iColumns)
	Local $xml_dom = _XMLLoadXML($aResult[1][0], "")
	_XMLUpdateField($xml_dom, "/Connection/Url", $arr[$i][1])
	FileDelete(@ScriptDir & "\temp.xml")
	_XMLSaveXML($xml_dom, @ScriptDir & "\temp.xml")
	Local $data_xml = FileRead(@ScriptDir & "\temp.xml")

	_SQLite_Exec(-1, "UPDATE Connections SET DATA = '" & $data_xml & "' WHERE Name = '" & $arr[$i][0] & "';")
Next

_SQLite_Close($hDskDb)
_SQLite_Shutdown()

ShellExecute("RemoteDesktopManagerFree.exe", "", "C:\Program Files (x86)\Devolutions\Remote Desktop Manager Free")




func _DBG_StringSplit2d(byref $str,$delimiter)

    ; #FUNCTION# ======================================================================================
    ; Name ................:    _DBG_StringSplit2D($str,$delimiter)
    ; Description .........:    Create 2d array from delimited string
    ; Syntax ..............:    _DBG_StringSplit2D($str, $delimiter)
    ; Parameters ..........:    $str        - EOL (@CR, @LF or @CRLF) delimited string to split
    ;                           $delimiter  - Delimter for columns
    ; Return values .......:    2D array
    ; Author ..............:    kylomas
    ; =================================================================================================

    local $a1 = stringregexp($str,'.*?(?:\R|$)',3), $a2

    local $rows = ubound($a1) - 1, $cols = 0

    ; determine max number of columns by splitting each row and keeping highest ubound value

    for $i = 0 to ubound($a1) - 1
        $a2 = stringsplit($a1[$i],$delimiter,1)
        if ubound($a2) > $cols then $cols = ubound($a2)
    next

    ; define and populate array

    local $aRET[$rows][$cols-1]

    for $i = 0 to $rows - 1
        $a2 = stringsplit($a1[$i],$delimiter,3)
        for $j = 0 to ubound($a2) - 1
            $aRET[$i][$j] = $a2[$j]
        Next
    next

    return $aRET

endfunc
