function New-FileToEventTrigger {
    <#
    .SYNOPSIS
        Creates a scheduled task that runs on system startup, monitors a directory for new 
        files and creates an event log entry if this occurs. 
    .PARAMETER Name
        The name of the new FileToEventTrigger
    .PARAMETER WatchPath
        The path that will be watched. Can be a local path or network share.
    .PARAMETER WatchFilter
        A filter to only watch for specific files, e.g. '*.txt'
    .PARAMETER EventSource
        The source name, that the created event log entries will have
    .PARAMETER EventLogName
        The event log, in which the event entries will be created
    .PARAMETER EventId
        The event id for this particular FileToEventTrigger
    .PARAMETER EventType
        The type, that the created event log entries will have
    .EXAMPLE
        PS C:\> New-FileToEventTrigger -Name InternetRequest -Path \\server.domain.tld\InternetRequest -EventSource InternetRequest -EventId 1001
        
        The scheduled task "RequestPermission" will be created. 
        The task starts on system startup and creates a IO.FileSystemWatcher,
        that continously monitors \\server.domain.tld\InternetRequest for 
        newly created files. If a new file was created, e.g. "JohnDoe.txt", 
        a new entry in the Application event log, with the EventID 1001 of 
        the source "InternetRequest" will be created. 
        Its message content would be 
        "\\server.domain.tld\InternetRequest\JohnDoe.txt,Message content if any".
        The event can be used to trigger another scheduled task, that runs if such a 
        event occures. This task could proccess information that is given in the 
        created file. 
    .NOTES
        Author: VRDSE
    #>
    #Requires -RunAsAdministrator
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$Name,
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$WatchPath,
        [string]$WatchFilter = '*',    
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$EventSource,
        [ValidateSet('Application', 'System')]
        [string]$EventLogName = 'Application',
        [int32]$EventId = 1000,
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$EventType = 'Information'
    )
    
    begin {
        # Requires administrative privileges
        New-EventLog -LogName Application -Source $EventSource
    }
    
    process {
        # Event message 'll be the path of the newly created file and its content (comma-separated)
        $Message = '"$($eventArgs.FullPath),$(Get-Content -Path $eventArgs.FullPath)"'
        $WriteEventLog = "Write-EventLog -LogName $EventLogName -Source $EventSource -EntryType $EventType -EventId $EventId -Message $Message"
        $StartFileSystemWatcher = "PSFileToEvent\Start-FileSystemWatcher -Path $WatchPath -Filter $WatchFilter -Event Created -NotifyFilter FileName -Action {$WriteEventLog}"
        $Command = "Import-Module PSFileToEvent;$StartFileSystemWatcher"
        $EncodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Command)) 

        $TaskArgument = "-NoExit -NoProfile -ExecutionPolicy Bypass -EncodedCommand $EncodedCommand"
        $TaskAction = New-ScheduledTaskAction -Execute powershell.exe -Argument $TaskArgument
        $TaskTrigger = New-ScheduledTaskTrigger -AtStartup
        $TaskDescription = $Name
        $Task = New-ScheduledTask -Action $TaskAction -Trigger $TaskTrigger -Description $TaskDescription
        
        # Requires administrative privileges
        Register-ScheduledTask -TaskName $Name -InputObject $Task -User SYSTEM -Force

        Start-ScheduledTask -TaskName $Name
    }
    
    end {
    }
}