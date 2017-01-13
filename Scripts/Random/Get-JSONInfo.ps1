$url="http://www.xxxx.com/xxxx/api/asociado?limit=1000&page=1&sort=[{%22property%22:%22nombre%22,%20%22direction%22:%22asc%22}]"

[System.Net.WebClient]$WebClient = New-Object System.Net.WebClient
$WebClient.Encoding = [System.Text.Encoding]::Default
$Data = $WebClient.DownloadString("$url")
$Object = ConvertFrom-Json $Data
$Object.Content | Export-Csv file.csv -Encoding Default -NoTypeInformation
