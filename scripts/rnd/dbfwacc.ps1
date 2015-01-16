$MasterKey = New-Object System.Net.Cookie

$MasterKey.Domain = "xxx.com"
$MasterKey.Expires = (Get-Date).AddDays(7)
$MasterKey.Name = "downloads"
$MasterKey.Path = "/"
$MasterKey.Value = 1
$MasterKey.Version = 0

<#
$myProxy = New-Object System.Net.WebProxy
$myProxy.Address = "http://254.253.252.251:9090"
$myProxy.Credentials = New-Object System.Net.NetworkCredential("DOM\User", "SecurePwd")
#>

$request = [System.Net.HttpWebRequest]::Create("http://xxx.com/downloads.php?file=/doe.zip")
#$request.Proxy = $myProxy
$request.CookieContainer = New-Object System.Net.CookieContainer
$request.CookieContainer.Add("http://www.xxx.es", $MasterKey)
$request.Method = 'POST'
$response = $request.GetResponse();
$stream = $response.GetResponseStream()  

$writer = new-object System.IO.FileStream "C:\Users\SupahUser\Desktop\kk.bin", "Create"

[byte[]]$buffer = new-object byte[] 4096
[int]$total = [int]$count = 0

do {

    $count = $stream.Read($buffer, 0, $buffer.Length)
    $writer.Write($buffer, 0, $count)
 
} while ($count -gt 0)

$stream.Close()
$writer.Flush()
$writer.Close()
