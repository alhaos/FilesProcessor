using namespace System.Data
using namespace System.Data.SQLite
using namespace System.IO

class FilesProcessor {

    [hashtable]$Conf
    [SQLiteConnection]$Connection

    FilesProcessor([hashtable]$Conf) {
        $this.Conf = $Conf
        
        $this.Connection = [SQLiteConnection]::new("Data Source=$($this.conf.DatabaseFilename);Version=3;")
        $this.Connection.Open()
        
    }

    Init () {
        
        $clearFilesTable = $this.Connection.CreateCommand()
        $clearFilesTable.CommandText = "delete from FILES"
        $clearFilesTable.ExecuteNonQuery()

        $insertFile = $this.Connection.CreateCommand()
        $insertFile.CommandText = "insert into FILES (NAME, LAST_WRITE_TIME, STATUS) values (@NAME, @LAST_WRITE_TIME, 0)"

        $name = [SQLiteParameter]::new("@NAME", [DbType]::String)
        $lastWriteTime = [SQLiteParameter]::new("@LAST_WRITE_TIME", [DbType]::String)

        $insertFile.Parameters.Add($name)
        $insertFile.Parameters.Add($lastWriteTime)
        
        foreach ($file in [Directory]::GetFiles($this.Conf.WatchedDirectory)) {
            $fileInfo = [FileInfo]::new($file)
            $lastWriteTime.Value = $fileInfo.LastAccessTime.ToString("yyyy-MM-ddTHH:mm:ss")
            $name.Value = $fileInfo.FullName
            $insertFile.ExecuteNonQuery()
        }
    }

    GetFiles() {
        foreach ($file in [Directory]::GetFiles($this.Conf.WatchedDirectory)) {
            $fileInfo = [FileInfo]::new($file)
            $select = $this.Connection.CreateCommand()
            $select.CommandText = "select NAME, LAST_WRITE_TIME, STATUS from FILES where NAME = @FILENAME"
            $filenameParameter = [SQLiteParameter]::new("@FILENAME", [DbType]::String)
            $select.Parameters.Add($filenameParameter)
            if ($fileInfo.LastAccessTime -ge [datetime]::Now.Subtract([timespan]::new($this.Conf.FileAgeInHours, 0, 0))) {
                $filenameParameter.Value = $fileInfo.FullName
                $watchedFile = [WatchedFile]::new()
                $dataReader = $select.ExecuteReader()
                while ($dataReader.Read()) {
                    $watchedFile.Name = $dataReader.GetString(0)
                    $watchedFile.LastWriteTime = [datetime]::Parse($dataReader.GetString(1))
                    $watchedFile.Status = $dataReader.GetInt32(2)
                }
            }
        }
    }
}

class WatchedFile {
    [string]$Name
    [datetime]$LastWriteTime
    [int]$Status
}