function Start-FileSystemWatcher {
    <#
    .Synopsis
        Starts monitoring for file changes
    .Description
        Starts monitoring for file changes using the events on IO.FileSystemWatcher
    .Parameter Path
        The path to the file or directory that will be watched.
    .Parameter Filter
        Filters the files that are being watched. E.g. '*.txt' watches only for Text files.
    .Parameter Recurse
        If set, the watcher monitors the specified director and all its subdirectories.
    .Parameter Event
        A list of events to watch for.
        By default, Created, Deleted, Changed, and Renamed are watched for, 
        and Error and Disposed are not watched for.
    .Parameter NotifyFilter
        Type(s) of NotifyFilter changes to watch for.
        https://msdn.microsoft.com/en-us/library/system.io.filesystemwatcher.notifyfilter(v=vs.110).aspx
    .Parameter Action
        A script block that defines the performed action, if the FileSystemWatcher triggers.
    .Example
        Start-FileSystemWatcher \\server.domain.tld\Share -Action {
            $subject = "$($eventArgs.ChangeType): $($eventArgs.FullPath)"
            $body = (Get-Content $eventArgs.FullPath -ErrorAction SilentlyContinue | Out-String)
            $email = @{
                From = 'system@domain.tld'
                To = 'me@domain.tld'
                SmtpServer = 'smtp.domain.tld'
                Subject = $subject
            }
            if ($body) { $email+=@{Body = $body }}                        
            Send-MailMessage @email
        }
        # Watches \\server.domain.tld\Share and sends an email with the content of files as they change
    #>  

    param(
        [Parameter(ValueFromPipelineByPropertyName = $true, Position = 0, Mandatory = $true)]
        [Alias('FullName')]
        [string]$Path,
        [string]$Filter = '*',
        [switch]$Recurse,
        [ValidateSet('Created', 'Deleted', 'Changed', 'Renamed', 'Error', 'Disposed')]
        [string[]]
        $Event = @("Created", "Deleted", "Changed", "Renamed"),
        [ValidateSet('Attributes', 'CreationTime', 'DirectoryName', 'FileName', 'LastAccess', 'LastWrite', 'Security', 'Size')]
        [string[]]
        $NotifyFilter = @('FileName', 'DirectoryName', 'LastWrite'), 
        [Parameter(Mandatory = $true)]
        [ScriptBlock[]]
        $Action
    )
    
    process {    
        if (Test-Path $Path) {
            $FileSystemWatcher = [IO.FileSystemWatcher]@{
                NotifyFilter          = $NotifyFilter
                Path                  = $Path
                Filter                = $Filter
                IncludeSubdirectories = $Recurse
            }
            foreach ($EventItem in $Event) {
                foreach ($ActionItem in $Action) {
                    $Arguments = @{
                        InputObject = $FileSystemWatcher
                        EventName   = $EventItem
                        Action      = $ActionItem
                    }
                    Register-ObjectEvent @Arguments
                }                
            }
        }
        else {
            Write-Error "$Path not found. Please specify a path that is accessible."
        }        
    }
}