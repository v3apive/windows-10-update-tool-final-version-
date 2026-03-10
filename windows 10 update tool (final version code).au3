#Region ; **** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=shell32.dll|-155
#AutoIt3Wrapper_Outfile=Win10_Ultimate_Deployer_v42.9.2.exe
#AutoIt3Wrapper_Res_RequestedExecutionLevel=highestAvailable
#EndRegion ; **** End of Directives ****

#RequireAdmin
#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#include <WindowsConstants.au3>
#include <File.au3>

; --- CONFIG ---
Global $ISO_URL = "https://archive.org/download/windows-10-22-h-2-russian-x-64/Windows%2010%2022H2%20(Russian)%20x64.iso"
Global $ISO_PATH = ""
Global $EXTRACT_DIR = @DesktopDir & "\Win10_Files"

; --- UI ---
$hGUI = GUICreate("Win10 Universal Deployer v42.9.2", 450, 850)
GUISetBkColor(0xF0F0F0)

GUICtrlCreateLabel("Windows 10 Setup Tool", 10, 20, 430, 30, $SS_CENTER)
GUICtrlSetFont(-1, 16, 800)

; Группа 1: Подготовка
GUICtrlCreateGroup(" Step 1: ISO Preparation ", 15, 60, 420, 110)
$btnDown = GUICtrlCreateButton("DOWNLOAD ISO (Auto)", 35, 85, 380, 35)
$btnSelect = GUICtrlCreateButton("SELECT ISO MANUALLY", 35, 125, 380, 35)
GUICtrlCreateGroup("", -99, -99, 1, 1)

$progress = GUICtrlCreateProgress(15, 180, 420, 20)

; Группа 2: Исправления для Windows 7
GUICtrlCreateGroup(" Windows 7 Fixes (STRICT NO IE) ", 15, 215, 420, 160)
GUICtrlSetColor(-1, 0xFF0000)
$btnScan = GUICtrlCreateButton("SCAN DISKS FOR ISO", 35, 240, 380, 35)
$btnBrowser = GUICtrlCreateButton("DEEP SEARCH BROWSERS & DOWNLOAD", 35, 280, 380, 35)
$btnCheckSpace = GUICtrlCreateButton("CHECK C: DRIVE SPACE", 35, 325, 380, 35)
GUICtrlCreateGroup("", -99, -99, 1, 1)

; Группа 3: Работа с образом
GUICtrlCreateGroup(" Step 2: Open Image ", 15, 390, 420, 110)
$btnMount = GUICtrlCreateButton("MOUNT ISO (Win 8+)", 35, 415, 380, 35)
$btnExtract = GUICtrlCreateButton("EXTRACT TO FOLDER", 35, 455, 380, 40)
GUICtrlCreateGroup("", -99, -99, 1, 1)

; Группа 4: Запуск установки
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

; --- ОСНОВНОЙ ЦИКЛ ---
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

; --- ФУНКЦИИ ---

Func _DoDownload()
    GUICtrlSetData($Status, "Status: Downloading... Please wait.")
    ; 1 = ForceReload, 1 = Asynchronous
    Local $hDownload = InetGet($ISO_URL, @DesktopDir & "\Win10_Setup.iso", 1, 1)

    If @error Or $hDownload = 0 Then
        MsgBox(16, "Error", "Ошибка запуска загрузки!")
        Return
    EndIf

    ; 2 = DownloadComplete
    While Not InetGetInfo($hDownload, 2)
        Local $nBytes = InetGetInfo($hDownload, 0) ; 0 = BytesRead
        Local $nSize = InetGetInfo($hDownload, 1)  ; 1 = TotalSize
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
    MsgBox(64, "Успех", "ISO успешно скачан на рабочий стол.")
EndFunc

Func _DoExtract()
    If $ISO_PATH = "" Or Not FileExists($ISO_PATH) Then Return MsgBox(48, "Error", "ISO не выбран!")
    Local $exe = _FindArchiver()
    If $exe = "" Then Return MsgBox(16, "Error", "Архиватор (7-Zip или WinRAR) не найден!")

    DirCreate($EXTRACT_DIR)
    GUICtrlSetData($Status, "Status: Extracting... Please wait.")

    Local $sCmd = ""
    If StringInStr($exe, "WinRAR.exe") Then
        ; Для WinRAR: x (извлечь), -y (да на всё), путь назначения со слешем в конце
        $sCmd = '"' & $exe & '" x -y "' & $ISO_PATH & '" "' & $EXTRACT_DIR & '\"'
    Else
        ; Для 7-Zip: x (извлечь), -o (папка), -y (да на всё)
        $sCmd = '"' & $exe & '" x "' & $ISO_PATH & '" -o"' & $EXTRACT_DIR & '" -y'
    EndIf

    ; Запуск процесса и ожидание завершения
    RunWait($sCmd, "", @SW_HIDE)

    If FileExists($EXTRACT_DIR & "\setup.exe") Then
        Beep(1000, 300) ; Звуковой сигнал завершения
        GUICtrlSetData($Status, "Status: Extracted successfully!")
        MsgBox(64, "Готово", "Распаковка завершена! Файлы в папке Win10_Files.")
    Else
        GUICtrlSetData($Status, "Status: Extraction Error")
        MsgBox(16, "Ошибка", "Не удалось распаковать файлы. Проверьте место на диске.")
    EndIf
EndFunc

Func _FindArchiver()
    ; Ищем 7-Zip в реестре
    Local $r7z = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\7-Zip", "Path")
    If $r7z <> "" And FileExists($r7z & "\7z.exe") Then Return $r7z & "\7z.exe"

    ; Ищем WinRAR в реестре
    Local $rWrar = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe", "")
    If $rWrar <> "" And FileExists($rWrar) Then Return $rWrar

    ; Проверка стандартных путей
    Local $paths[4] = [ _
        @ProgramFilesDir & "\7-Zip\7z.exe", _
        "C:\Program Files (x86)\7-Zip\7z.exe", _
        @ProgramFilesDir & "\WinRAR\WinRAR.exe", _
        "C:\Program Files (x86)\WinRAR\WinRAR.exe"]

    For $i = 0 To 3
        If FileExists($paths[$i]) Then Return $paths[$i]
    Next
    Return ""
EndFunc

Func _StartNormal()
    Local $sFile = $EXTRACT_DIR & "\setup.exe"
    If FileExists($sFile) Then
        ShellExecute($sFile)
    Else
        MsgBox(48, "Ошибка", "setup.exe не найден. Сначала нажмите EXTRACT.")
    EndIf
EndFunc

Func _StartSources()
    Local $sFile = $EXTRACT_DIR & "\sources\setup.exe"
    If FileExists($sFile) Then
        ShellExecute($sFile)
    Else
        MsgBox(48, "Ошибка", "Файл в подпапке sources не найден!")
    EndIf
EndFunc

Func _StartFromMount()
    Local $aDrives = DriveGetDrive("CDROM")
    If Not @error Then
        For $i = 1 To $aDrives[0]
            If FileExists($aDrives[$i] & "\sources\setup.exe") Then
                ShellExecute($aDrives[$i] & "\sources\setup.exe")
                Return
            EndIf
        Next
    EndIf
    MsgBox(48, "Ошибка", "Смонтированный диск не найден!")
EndFunc

Func _DoManualSelect()
    Local $f = FileOpenDialog("Select ISO", @HomeDrive, "ISO Files (*.iso)")
    If Not @error Then
        $ISO_PATH = $f
        GUICtrlSetData($Status, "Status: ISO Selected!")
    EndIf
EndFunc

Func _DoMount()
    If StringInStr(@OSVersion, "WIN_7") Then Return MsgBox(48, "Win 7", "Монтирование не поддерживается в Win 7!")
    If $ISO_PATH <> "" Then ShellExecute($ISO_PATH)
EndFunc

Func _ForceModernBrowser()
    Local $aB[3] = ["chrome.exe", "firefox.exe", "msedge.exe"]
    For $b In $aB
        Local $r = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\" & $b, "")
        If $r <> "" Then
            ShellExecute($r, $ISO_URL)
            Return
        EndIf
    Next
    ClipPut($ISO_URL)
    MsgBox(64, "Инфо", "Ссылка на ISO скопирована в буфер обмена.")
EndFunc

Func _ScanDrives()
    Local $aD = DriveGetDrive("FIXED")
    For $i = 1 To $aD[0]
        Local $h = FileFindFirstFile($aD[$i] & "\*Windows*10*.iso")
        If $h <> -1 Then
            $ISO_PATH = $aD[$i] & "\" & FileFindNextFile($h)
            FileClose($h)
            GUICtrlSetData($Status, "Status: ISO Found and Linked!")
            MsgBox(64, "Найдено", "Найден образ: " & $ISO_PATH)
            Return
        EndIf
    Next
    MsgBox(48, "Пусто", "Образ Windows 10 не найден на дисках.")
EndFunc

Func _CheckDiskSpace()
    Local $free = Round(DriveSpaceFree("C:\") / 1024, 2)
    MsgBox(64, "Место на диске", "Свободно на C: " & $free & " GB. Для установки нужно минимум 17 GB.")
EndFunc