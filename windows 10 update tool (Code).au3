#Region ; **** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=shell32.dll|-155
#AutoIt3Wrapper_Outfile=Win10_Ultimate_Deployer_v42.9.1.exe
#AutoIt3Wrapper_Res_RequestedExecutionLevel=highestAvailable
#EndRegion ; **** End of Directives ****

#RequireAdmin
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <File.au3>
#include <InetConstants.au3>

; --- CONFIG ---
Global $ISO_URL = "https://archive.org/download/windows-10-22-h-2-russian-x-64/Windows%2010%2022H2%20(Russian)%20x64.iso"
Global $ISO_PATH = ""
Global $EXTRACT_DIR = @DesktopDir & "\Win10_Files"

; --- UI ---
$hGUI = GUICreate("Win10 Universal Deployer v42.9.1", 450, 850)
GUISetBkColor(0xF0F0F0)

GUICtrlCreateLabel("Windows 10 Setup Tool", 10, 20, 430, 30, $SS_CENTER)
GUICtrlSetFont(-1, 16, 800)

; ?????? 1: ??????????
GUICtrlCreateGroup(" Step 1: ISO Preparation ", 15, 60, 420, 110)
$btnDown = GUICtrlCreateButton("DOWNLOAD ISO (Auto)", 35, 85, 380, 35)
$btnSelect = GUICtrlCreateButton("SELECT ISO MANUALLY", 35, 125, 380, 35)
GUICtrlCreateGroup("", -99, -99, 1, 1)

$progress = GUICtrlCreateProgress(15, 180, 420, 20)

; ?????? 2: ??? Windows 7
GUICtrlCreateGroup(" Windows 7 Fixes (STRICT NO IE) ", 15, 215, 420, 160)
GUICtrlSetColor(-1, 0xFF0000)
$btnScan = GUICtrlCreateButton("SCAN DISKS FOR ISO", 35, 240, 380, 35)
$btnBrowser = GUICtrlCreateButton("DEEP SEARCH BROWSERS & DOWNLOAD", 35, 280, 380, 35)
$btnCheckSpace = GUICtrlCreateButton("CHECK C: DRIVE SPACE", 35, 325, 380, 35)
GUICtrlCreateGroup("", -99, -99, 1, 1)

; ?????? 3: ???????? ??????
GUICtrlCreateGroup(" Step 2: Open Image ", 15, 390, 420, 110)
$btnMount = GUICtrlCreateButton("MOUNT ISO (Win 8+)", 35, 415, 380, 35)
$btnExtract = GUICtrlCreateButton("EXTRACT TO FOLDER", 35, 455, 380, 40)
GUICtrlCreateGroup("", -99, -99, 1, 1)

; ?????? 4: ??????
GUICtrlCreateGroup(" Step 3: Start Installation ", 15, 515, 420, 240)
$btnRunFolder = GUICtrlCreateButton("RUN NORMAL SETUP (setup.exe)", 35, 540, 380, 45)
GUICtrlSetFont(-1, 9, 800)
GUICtrlSetBkColor(-1, 0xADD8E6)

$btnRunSources = GUICtrlCreateButton("RUN SKIP KEY SETUP (sources\setup.exe)", 35, 595, 380, 45)
GUICtrlSetFont(-1, 9, 800)
GUICtrlSetBkColor(-1, 0x90EE90)

$btnRunMount = GUICtrlCreateButton("RUN FROM MOUNTED DRIVE (Win 8/10)", 35, 650, 380, 45)
GUICtrlSetFont(-1, 9, 800)
GUICtrlSetBkColor(-1, 0x00FF00)
GUICtrlCreateGroup("", -99, -99, 1, 1)

$Status = GUICtrlCreateLabel("Status: Ready", 10, 780, 430, 25, $SS_CENTER)
GUICtrlSetFont(-1, 10, 600)

GUISetState(@SW_SHOW)

; --- LOGIC ---
While 1
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            Exit
        Case $btnDown
            _DoDownload()
        Case $btnSelect
            _DoManualSelect()
        Case $btnScan
            _ScanDrives()
        Case $btnBrowser
            _ForceModernBrowser()
        Case $btnCheckSpace
            _CheckDiskSpace()
        Case $btnMount
            _DoMount()
        Case $btnExtract
            _DoExtract()
        Case $btnRunFolder
            _StartNormal()
        Case $btnRunSources
            _StartSources()
        Case $btnRunMount
            _StartFromMount()
    EndSwitch
WEnd

; --- ??????? ---

Func _DoDownload()
    GUICtrlSetData($Status, "Status: Downloading... Please wait.")
    Local $hDownload = InetGet($ISO_URL, @DesktopDir & "\Win10_Setup.iso", $INET_FORCERELOAD, $INET_ASYNCHRONOUS)

    While Not InetGetInfo($hDownload, $INET_DOWNLOADCOMPLETE)
        Local $nBytes = InetGetInfo($hDownload, $INET_BYTESREAD)
        Local $nSize = InetGetInfo($hDownload, $INET_DOWNLOADSIZE)
        If $nSize > 0 Then
            Local $nPct = Round(($nBytes / $nSize) * 100)
            GUICtrlSetData($progress, $nPct)
            GUICtrlSetData($Status, "Status: Downloading... " & $nPct & "%")
        EndIf
        Sleep(500)
    WEnd
    InetClose($hDownload)
    $ISO_PATH = @DesktopDir & "\Win10_Setup.iso"
    GUICtrlSetData($Status, "Status: ISO Downloaded to Desktop!")
    MsgBox(64, "?????", "ISO ??????? ?????? ?? ??????? ????.")
EndFunc

Func _DoExtract()
    If $ISO_PATH = "" Or Not FileExists($ISO_PATH) Then Return MsgBox(48, "Error", "ISO ?? ??????!")
    Local $exe = _Find7z()
    If $exe = "" Then Return MsgBox(16, "Error", "7-Zip ??? WinRAR ?? ??????!")

    DirCreate($EXTRACT_DIR)
    GUICtrlSetData($Status, "Status: Extracting... Please wait.")

    Local $sCommand = ""
    If StringInStr($exe, "WinRAR.exe") Then
        $sCommand = '"' & $exe & '" x "' & $ISO_PATH & '" "' & $EXTRACT_DIR & '\"'
    Else
        $sCommand = '"' & $exe & '" x "' & $ISO_PATH & '" -o"' & $EXTRACT_DIR & '" -y'
    EndIf

    RunWait($sCommand, "", @SW_HIDE)
    GUICtrlSetData($Status, "Status: Extracted successfully!")
    MsgBox(64, "Done", "????? ?????? ? ????? Win10_Files.")
EndFunc

Func _Find7z()
    Local $p[4] = [@ProgramFilesDir & "\7-Zip\7z.exe", "C:\Program Files (x86)\7-Zip\7z.exe", @ProgramFilesDir & "\WinRAR\WinRAR.exe", "C:\Program Files (x86)\WinRAR\WinRAR.exe"]
    For $i = 0 To 3
        If FileExists($p[$i]) Then Return $p[$i]
    Next
    Return ""
EndFunc

Func _StartNormal()
    Local $sFile = $EXTRACT_DIR & "\setup.exe"
    If FileExists($sFile) Then
        GUICtrlSetData($Status, "Status: Starting Normal Setup...")
        ShellExecute($sFile)
    Else
        MsgBox(48, "Error", "setup.exe ?? ??????! ??????? ??????? EXTRACT.")
    EndIf
EndFunc

Func _StartSources()
    Local $sFile = $EXTRACT_DIR & "\sources\setup.exe"
    If FileExists($sFile) Then
        GUICtrlSetData($Status, "Status: Starting Skip Key Setup...")
        ShellExecute($sFile)
    Else
        MsgBox(48, "Error", "sources\setup.exe ?? ??????!")
    EndIf
EndFunc

Func _StartFromMount()
    Local $aDrives = DriveGetDrive("CDROM")
    Local $found = False
    If Not @error Then
        For $i = 1 To $aDrives[0]
            If FileExists($aDrives[$i] & "\sources\setup.exe") Then
                ShellExecute($aDrives[$i] & "\sources\setup.exe")
                $found = True
                ExitLoop
            EndIf
        Next
    EndIf
    If Not $found Then MsgBox(48, "Error", "???? ?? ??????!")
EndFunc

Func _DoManualSelect()
    Local $f = FileOpenDialog("Select ISO", @HomeDrive, "ISO Files (*.iso)")
    If Not @error Then
        $ISO_PATH = $f
        GUICtrlSetData($Status, "Status: ISO Selected: " & StringRegExpReplace($f, "^.*\\", ""))
    EndIf
EndFunc

Func _DoMount()
    If StringInStr(@OSVersion, "WIN_7") Then Return MsgBox(48, "Win 7", "Mount not supported on Win 7!")
    If $ISO_PATH = "" Or Not FileExists($ISO_PATH) Then Return MsgBox(48, "Error", "ISO ?? ??????!")
    ShellExecute($ISO_PATH)
    GUICtrlSetData($Status, "Status: Mounting ISO...")
EndFunc

Func _ForceModernBrowser()
    Local $aB[9] = ["chrome.exe", "firefox.exe", "supermium.exe", "opera.exe", "browser.exe", "vivaldi.exe", "brave.exe", "msedge.exe", "thorium.exe"]
    Local $found = False
    For $b In $aB
        Local $r = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" & $b, "")
        If $r <> "" And FileExists($r) Then
            ShellExecute($r, $ISO_URL)
            $found = True
            ExitLoop
        EndIf
    Next
    If Not $found Then ClipPut($ISO_URL)
    GUICtrlSetData($Status, $found ? "Status: Browser opened" : "Status: Link copied")
EndFunc

Func _ScanDrives()
    Local $aD = DriveGetDrive("FIXED")
    Local $f = ""
    For $i = 1 To $aD[0]
        Local $h = FileFindFirstFile($aD[$i] & "\*Windows*10*.iso")
        If $h <> -1 Then
            $f = $aD[$i] & "\" & FileFindNextFile($h)
            FileClose($h)
            ExitLoop
        EndIf
    Next
    If $f <> "" Then
        $ISO_PATH = $f
        GUICtrlSetData($Status, "Status: ISO Linked!")
        MsgBox(64, "Found", "ISO ??????: " & $f)
    Else
        MsgBox(48, "Not Found", "ISO ?? ?????? ?? ??????.")
    EndIf
EndFunc

Func _CheckDiskSpace()
    Local $free = Round(DriveSpaceFree("C:\") / 1024, 2)
    MsgBox(64, "Space", "???????? ?? C: " & $free & " GB")
EndFunc