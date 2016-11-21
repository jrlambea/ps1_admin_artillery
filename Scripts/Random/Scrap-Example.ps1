[System.Net.WebClient]$WebClient = New-Object System.Net.WebClient
"Id;Name;Web;Telf;Poblacion;Direccion;Director;Fax;Email"
ForEach ($i in 1..354)
{
    $Data=$WebClient.DownloadString("http://www.aehcos.es/alojamientos/ficha.asp?cat=0&mun=0&ord=ord_q&cod=0&pag=${i}")
    $Name=$Data.Split("`n")[601].Split(">")[1].Split("<")[0]
    $Web=($Data.Split("`n") | Select-String "Web:").Line.Split("`"")[3]
    $Telf=($Data.Split("`n") | Select-String "fono:").Line.Split(";")[1].Split("<")[0]
    $Pobl=($Data.Split("`n") | Select-String "Pobl").Line.Split(";")[1].Split("<")[0]
    $Dir=($Data.Split("`n") | Select-String "Direcci").Line.Split(";")[1].Split("<")[0]
    $Director=($Data.Split("`n") | Select-String "Director").Line.Split(";")[1].Split("<")[0]
    $email=($Data.Split("`n") | Select-String "E-mail").Line.Split("`"")[1].Replace("mailto:", "")
    $Fax=($Data.Split("`n") | Select-String "Fax:").Line.Split(";")[1].Split("<")[0]
    "${i};${Name};${Web};${Telf};${Pobl};${Dir};${Director};${Fax};${email}"
}
