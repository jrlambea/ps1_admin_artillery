#REF http://www.sharepointdiary.com/2012/07/upload-file-to-sharepoint-library-using-powershell.html

Add-PSSnapin Microsoft.SharePoint.PowerShell
 
$ODATE              = (Get-Date).AddDays(-1)
[String]$web        = "https://sharepoint.corp.com/path/to/"
[String]$DocLib     = "Documents/TargetFolder"
[String]$FileBase   = "\\server.corp.com\SRC_DIR\" + $ODATE.ToString("yyMMdd")
$LocalFiles         = Get-ChildItem $FileBase*

#Function to Upload File
function UploadFile([String]$WebURL, [String]$DocLibName, $FilePath)
{

    #Get the Web & Lists to upload the file
    $Web2 = Get-SPWeb $WebURL
    $List = $Web2.GetFolder($DocLibName)
    $Files = $List.Files 

    #Get File Name from Path
    $FileName = $FilePath.FullName.Substring($FilePath.FullName.LastIndexOf("\")+1)

    #Add File to the collection
    $Files.Add($DocLibName +"/" + $FileName,$FilePath.OpenRead(),$false)
 
    #Dispose the objects
    $web2.Dispose()
 }

if ( $LocalFiles ) {

    ForEach ( $File in $LocalFiles )
    {
        UploadFile $web $DocLib $File
    }
    
}
