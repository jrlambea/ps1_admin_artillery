Add-pssnapin VMWare.VimAutomation.Core

$VCENTER    = "vcenter.corp.com"
$VMS        = "servicefrontend.corp.com","appserver.corp.com"
$VMSDB      = "servicedb.corp.com"
$SQL_PORT   = 1405
$TIMEOUT    = 600
$COUNTER    = 0

<#
    Function to connect to a vCenter server, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function Connect(){

    Write-Host "Connecting to... $VCENTER"
    
    Try
    {
        Connect-VIServer $VCENTER | Out-Null
        Return $true

    } Catch {
        Return $false

    }
}


<#    Function to shutdown an array of virtual servers, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function ShutdownVMs($VMS) {

    $COUNTER = 0

    ForEach ( $VM in $VMS) {
        Write-Host "[!] Shutdown-VMGuest $VM"
        
        if ( ( Get-VM $VM ).PowerState -eq "PoweredOff" ) {
            Write-Host "    The server $VM is already PoweredOff."
        } else {
            Shutdown-VMGuest $VM -Confirm:$false

        }

    }

    While ( !( Test-Power "PoweredOff" $VMS ) -and $COUNTER -le $TIMEOUT ) {
        Write-Host "    Servers isn't PoweredOff, waiting 30 sec."
        $COUNTER += 30
        Sleep 30

    }  
    
    if ( $COUNTER -gt $TIMEOUT){
        
        Write-Host "    The server has not been stopped in time. Now has this situation:"

        ForEach ( $VM in $VMS) {
            Write-Host (Get-VM $VM | ft Name,PowerState | Out-String)
            Return $false

        }

    }

    Return $true
}

<#
    Function to test if an array of virtual servers has the same power status:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function Test-Power( $Status , $VMS ) {

    $COUNTER = 0

    ForEach ( $VM in $VMS) {
        if ( ( Get-VM $VM ).PowerState -ne "$Status" ) {
            Return $false

        }

    }

    Return $true
}

<#
    Function to start an array of virtual servers, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function StartVMs($VMS) {

    $COUNTER = 0

    ForEach ( $VM in $VMS) {
        Write-Host "[!] Start-VMGuest $VM"
        
        if ( ( Get-VM $VM ).PowerState -eq "PoweredOn" ) {
            Write-Host "    The server $VM is already PoweredOn."
        } else {
            Start-VM $VM -Confirm:$false | Out-Null

        }

    }
    
    While ( !( Test-Power "PoweredOn" $VMS ) -and $COUNTER -le $TIMEOUT ) {
        Write-Host "    Servers isn't PoweredOn, waiting 30 sec."
        $COUNTER += 30
        Sleep 30

    }  

    if ( $COUNTER -gt $TIMEOUT) {

        Write-Host "    The server has not been started in time. Now has this situation:"

        ForEach ( $VM in $VMS) {
            Write-Host (Get-VM $VM | ft Name,PowerState | Out-String)
            Return $false
        }

    }

    Return $true
}

<#
    Function to start an array of virtual servers, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function RestartVMs($Servers) {

    $COUNTER = 0
    For ( $i = 0 ; $i -ne $Servers.Length ; $i++ ){
        Write-Host "[!] Restart-VMGuest ", $Servers[$i]
        Restart-VMGuest $Servers[$i] -Confirm:$false | Out-null

    }

    While ( ( Test-Port $Servers $SQL_PORT ) -and $COUNTER -le $TIMEOUT ) {
        Write-Host "    Database listener still active, waiting 30 sec."
        $COUNTER += 30
        Sleep 30

    }

    $COUNTER = 0
    While ( !( Test-Port $Servers $SQL_PORT ) -and $COUNTER -le $TIMEOUT ) {
        Write-Host "    Database listener isn't active, waiting 30 sec."
        $COUNTER += 30
        Sleep 30

    }

    if ( $COUNTER -gt $TIMEOUT) {

        Write-Host "    The server has not been started in time. Now has this situation:"

        ForEach ( $VM in $VMS) {
            Write-Host (Get-VM $VM | ft Name,PowerState | Out-String)
            Return $false
        }

    }
    
    Return $true
}

<#
    Function to test the accessibility of a port, it returns a boolean value:
    - $true if the function has completed succesfully.
    - false if the function hasn't completed succesfully.
#>
Function Test-Port( $Server, $SQL_PORT ) {

    For ( $i=0 ; $i -ne $Server.Length ; $i++ ) {
    
        $tcpclient = new-Object system.Net.Sockets.TcpClient

        Try {
            $tcpclient.Connect( $Server[$i], $SQL_PORT[$i] )

        } catch {
            Return $false

        }

        $tcpclient.Close()

    }


    Return $true
}


<#    Main    #>
if ( Connect( $VCENTER ) ) {

    if ( ShutdownVMs( $VMS ) ) {

        if ( RestartVMs( $VMSDB ) ) {

            if ( $COUNTER -le $TIMEOUT ) {
                StartVMs( $VMS )
                Write-Host "`n[!] Restart completed Succesfully"

            } else {
                Write-Host "[X] The db listener has not been started in time."

            }
        }

    } else {
        Write-Host "[X] The servers couldn't be stopped succesfully."

    }

} else {
    Write-Host "[X] Couldn't connect to vCenter Server: $VCENTER"

}
