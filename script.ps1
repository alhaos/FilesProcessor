using assembly .\modules\FilesProcessor\System.Data.SQLite.dll
using module .\modules\FilesProcessor\FilesProcessor.psm1
$DebugPreference = 'Continue'
$conf = Import-PowerShellDataFile .\conf.psd1

$FilesProcessor = [FilesProcessor]::new($conf.FilesProcessor)
#$FilesProcessor.Init()
$FilesProcessor.GetFiles()
$FilesProcessor.Connection.Close()