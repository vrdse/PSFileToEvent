# PSFileToEvent

This module helps to create Windows Event Logs based on Files created in the File System.

## Install

```powershell
Invoke-WebRequest -Uri https://github.com/vrdse/PSFileToEvent/archive/master.zip -OutFile $env:TEMP\PSFileToEventTrigger.zip
Expand-Archive -Path $env:TEMP\PSFileToEventTrigger.zip -DestinationPath $env:TEMP
Copy-Item -Path $env:TEMP\PSFileToEvent-master\PSFileToEvent -Destination $env:ProgramFiles\WindowsPowerShell\Modules\PSFileToEvent -Recurse -Force
Import-Module -Name PSFileToEvent -Force
Remove-Item $env:TEMP\PSFileToEventTrigger.zip,$env:TEMP\PSFileToEvent-master -Force -Recurse
```

## Example

```powershell
New-FileToEventTrigger -Name InternetRequest -Path \\server.domain.tld\InternetRequest -EventSource InternetRequest -EventId 1001
```
     
- The scheduled task "RequestPermission" will be created.
- The task starts on system startup and creates a IO.FileSystemWatcher, that continously monitors \\\server.domain.tld\InternetRequest for newly created files. 
- If a new file was created, e.g. "JohnDoe.txt", a new entry in the Application event log, with the EventID 1001 of the source "InternetRequest" will be created. 
- Its message content would be "\\\server.domain.tld\InternetRequest\JohnDoe.txt,Message content if any".
- The event can be used to trigger another scheduled task, that runs if such an event occures. 
- This task could proccess information that is given in the created file.
 