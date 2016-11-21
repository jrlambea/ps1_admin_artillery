#.\Scrap-Example.ps1 | Out-File Result.csv
[System.Net.WebClient]$WebClient = New-Object System.Net.WebClient
"Id;Name;Web;Telf;Poblacion;Direccion;Director;Fax;Email"
ForEach ($i in 1..354)
{
    $Data=$WebClient.DownloadString("http://www.aehcos.es/alojamientos/ficha.asp?cat=0&mun=0&ord=ord_q&cod=0&pag=${i}")
    $Name=$Data.Split("`n")[601].Split(">")[1].Split("<")[0]
    $Web=$Data.Split("`n")[618].Split("`"")[3]
    $Telf=$Data.Split("`n")[620].Split(";")[1].Split("<")[0]
    $Pobl=$Data.Split("`n")[622].Split(";")[1].Split("<")[0]
    $Dir=$Data.Split("`n")[624].Split(";")[1].Split("<")[0]
    $Director=$Data.Split("`n")[626].Split(";")[1].Split("<")[0]
    $Fax=$Data.Split("`n")[628].Split(";")[1].Split("<")[0]
    $email=$Data.Split("`n")[630].Split(";")[1].Split("<")[0]
    "${i};${Name};${Web};${Telf};${Pobl};${Dir};${Director};${Fax};${email}"
}
