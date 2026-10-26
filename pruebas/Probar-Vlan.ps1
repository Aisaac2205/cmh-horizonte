<#
.SYNOPSIS
  Prueba la matriz de comunicacion entre VLAN del Centro Medico Horizonte.

.DESCRIPTION
  Detecta en que VLAN esta el equipo (172.16.<VLAN>.x), corre las pruebas que
  corresponden a esa VLAN y compara el resultado esperado con el obtenido.
  Deja un informe en pruebas/resultados/vlan<NN>-<fecha>.md listo para el anexo.

.EXAMPLE
  .\Probar-Vlan.ps1 -Extension 4001
  .\Probar-Vlan.ps1 -Vlan 30 -ModoQoS     # con las reglas PRUEBA-QOS activas en el hEX
#>
[CmdletBinding()]
param(
    [ValidateSet(10, 20, 30, 40)]
    [int]$Vlan,

    # Extension registrada en este equipo. Se usa en el From del SIP OPTIONS
    # para que Asterisk identifique el endpoint y no lo cuente como intento fallido.
    [string]$Extension = '4001',

    # Activar cuando las reglas PRUEBA-QOS (iperf3) esten habilitadas en el hEX
    [switch]$ModoQoS,

    [string]$Pbx = '172.16.20.10',
    [string]$Ap = '172.16.20.2',
    [string]$Iperf = '172.16.20.20'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Redes = @{
    10 = 'GESTION'
    20 = 'VOZ'
    30 = 'ADMIN'
    40 = 'INVITADOS'
}

# ---------------------------------------------------------------- utilidades
function Get-VlanLocal {
    $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -match '^172\.16\.(10|20|30|40)\.' }
    if (-not $ips) { return $null }
    $ip = @($ips)[0]
    [pscustomobject]@{
        Vlan      = [int]($ip.IPAddress.Split('.')[2])
        IP        = $ip.IPAddress
        Interfaz  = $ip.InterfaceAlias
    }
}

function Test-Ping([string]$Destino) {
    $p = New-Object System.Net.NetworkInformation.Ping
    for ($i = 0; $i -lt 2; $i++) {
        try { if ($p.Send($Destino, 1000).Status -eq 'Success') { return $true } } catch { }
    }
    return $false
}

function Test-Tcp([string]$Destino, [int]$Puerto) {
    $c = New-Object System.Net.Sockets.TcpClient
    try {
        $t = $c.ConnectAsync($Destino, $Puerto)
        return ($t.Wait(1500) -and $c.Connected)
    } catch { return $false } finally { $c.Close() }
}

function Test-SipOptions([string]$Destino, [string]$Ext) {
    # Envia un SIP OPTIONS por UDP 5060. Cualquier respuesta SIP (200, 401, 404)
    # demuestra que el router y el firewall de la PBX dejan pasar la senalizacion.
    $u = New-Object System.Net.Sockets.UdpClient(0)
    try {
        $u.Client.ReceiveTimeout = 2000
        $lp = ([System.Net.IPEndPoint]$u.Client.LocalEndPoint).Port
        $ipLocal = $script:IpLocal
        $tag = [guid]::NewGuid().ToString('N').Substring(0, 10)
        $msg = @(
            "OPTIONS sip:$Destino SIP/2.0"
            "Via: SIP/2.0/UDP ${ipLocal}:$lp;branch=z9hG4bK$tag;rport"
            "Max-Forwards: 70"
            "From: <sip:$Ext@$Destino>;tag=$tag"
            "To: <sip:$Destino>"
            "Call-ID: $tag@$ipLocal"
            "CSeq: 1 OPTIONS"
            "Contact: <sip:$Ext@${ipLocal}:$lp>"
            "User-Agent: CMH-Probar-Vlan"
            "Content-Length: 0"
            ""
            ""
        ) -join "`r`n"
        $b = [Text.Encoding]::ASCII.GetBytes($msg)
        [void]$u.Send($b, $b.Length, $Destino, 5060)
        $ep = New-Object System.Net.IPEndPoint([Net.IPAddress]::Any, 0)
        $r = [Text.Encoding]::ASCII.GetString($u.Receive([ref]$ep))
        return $r.StartsWith('SIP/2.0')
    } catch { return $false } finally { $u.Close() }
}

function Test-Dns([string]$Servidor) {
    try {
        $null = Resolve-DnsName -Name 'www.google.com' -Server $Servidor -DnsOnly -QuickTimeout -ErrorAction Stop
        return $true
    } catch { return $false }
}

# --------------------------------------------------------- casos de prueba
# Cada caso es solo datos. Invoke-Caso decide como probarlo segun su Tipo.
function New-Caso([string]$Id, [string]$Desc, [ValidateSet('ping', 'tcp', 'sip', 'dns')][string]$Tipo,
                  [string]$Destino, [int]$Puerto, [bool]$Espera, [string]$Regla) {
    $txt = switch ($Tipo) { 'ping' { $Destino } 'sip' { "${Destino}:5060/udp" } default { "${Destino}:$Puerto" } }
    [pscustomobject]@{ Id = $Id; Descripcion = $Desc; Tipo = $Tipo; Host = $Destino; Puerto = $Puerto
                       Texto = $txt; Esperado = $Espera; Regla = $Regla }
}

function Invoke-Caso($Caso) {
    switch ($Caso.Tipo) {
        'ping' { return Test-Ping $Caso.Host }
        'tcp'  { return Test-Tcp $Caso.Host $Caso.Puerto }
        'sip'  { return Test-SipOptions $Caso.Host $Extension }
        'dns'  { return Test-Dns $Caso.Host }
    }
}

function Get-Casos([int]$V) {
    $gw = "172.16.$V.1"
    $lista = @(
        New-Caso "V$V-01" 'Ping a la puerta de enlace' ping $gw 0 $true 'IN: ICMP desde LAN'
        New-Caso "V$V-02" 'DNS del router' dns $gw 53 $true 'IN: DNS y DHCP'
        New-Caso "V$V-03" 'Salida a internet (HTTPS)' tcp '1.1.1.1' 443 $true 'M5: VLAN -> Internet'
    )
    switch ($V) {
        10 { $lista += @(
            New-Caso 'V10-04' 'Winbox del router' tcp $gw 8291 $true 'IN: GESTION administra el router'
            New-Caso 'V10-05' 'SSH del router' tcp $gw 22 $true 'IN: GESTION administra el router'
            New-Caso 'V10-06' 'Ping a la PBX' ping $Pbx 0 $true 'M1: GESTION -> todas'
            New-Caso 'V10-07' 'Web de administracion de la PBX' tcp $Pbx 80 $true 'M1 + FreePBX Trusted'
            New-Caso 'V10-08' 'Web del AP' tcp $Ap 80 $true 'M1: GESTION -> todas'
            New-Caso 'V10-09' 'SIP OPTIONS a la PBX' sip $Pbx 5060 $true 'M1 + FreePBX SIP'
        ) }
        20 { $lista += @(
            New-Caso 'V20-04' 'Winbox del router' tcp $gw 8291 $false 'IN: descartar el resto'
            New-Caso 'V20-05' 'Ping a la PBX (misma VLAN)' ping $Pbx 0 $true 'Capa 2, sin pasar por el router'
            New-Caso 'V20-06' 'SIP OPTIONS a la PBX' sip $Pbx 5060 $true 'FreePBX: VOZ en zona Local'
            New-Caso 'V20-07' 'Web de administracion de la PBX' tcp $Pbx 80 $false 'FreePBX: Admin solo Trusted'
            New-Caso 'V20-08' 'Winbox por el gateway de ADMIN' tcp '172.16.30.1' 8291 $false 'IN: descartar el resto'
        ) }
        30 { $lista += @(
            New-Caso 'V30-04' 'Winbox del router' tcp $gw 8291 $false 'IN: descartar el resto'
            New-Caso 'V30-05' 'SSH del router por GESTION' tcp '172.16.10.1' 22 $false 'IN: descartar el resto'
            New-Caso 'V30-06' 'SIP OPTIONS a la PBX' sip $Pbx 5060 $true 'M2: ADMIN -> PBX solo SIP y RTP'
            New-Caso 'V30-07' 'Ping a la PBX' ping $Pbx 0 $false 'M2 solo SIP y RTP, M6 descarta'
            New-Caso 'V30-08' 'Web de administracion de la PBX' tcp $Pbx 80 $false 'M6: descartar el resto'
            New-Caso 'V30-09' 'SSH de la PBX' tcp $Pbx 22 $false 'M6: descartar el resto'
            New-Caso 'V30-10' 'Ping al AP (VOZ)' ping $Ap 0 $false 'M6: descartar el resto'
            New-Caso 'V30-11' 'iperf3 en la laptop host' tcp $Iperf 5201 ([bool]$ModoQoS) 'PRUEBA-QOS (solo en pruebas)'
        ) }
        40 { $lista += @(
            New-Caso 'V40-04' 'Winbox del router' tcp $gw 8291 $false 'IN: descartar el resto'
            New-Caso 'V40-05' 'Ping a la PBX' ping $Pbx 0 $false 'M6: invitados aislados'
            New-Caso 'V40-06' 'SIP OPTIONS a la PBX' sip $Pbx 5060 $false 'M6: invitados aislados'
            New-Caso 'V40-07' 'Ping al AP (VOZ)' ping $Ap 0 $false 'M6: invitados aislados'
            New-Caso 'V40-08' 'Web del AP' tcp $Ap 80 $false 'M6: invitados aislados'
        ) }
    }
    return $lista
}

# ----------------------------------------------------------------- ejecucion
$local = Get-VlanLocal
$script:IpLocal = if ($local) { $local.IP } else { '0.0.0.0' }
if (-not $PSBoundParameters.ContainsKey('Vlan')) {
    if (-not $local) { throw 'Este equipo no tiene IP 172.16.10/20/30/40.x. Revise el cable o renueve la IP (ipconfig /renew).' }
    $Vlan = $local.Vlan
}
$ipTxt = if ($local) { "$($local.IP) ($($local.Interfaz))" } else { 'sin IP 172.16.x' }
$inicio = Get-Date

# Si hay otra ruta por defecto (Wi-Fi de casa, hotspot), la prueba de internet
# podria salir por ahi y no por el hEX. Se avisa y queda en el informe.
$otrasSalidas = @(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { -not $local -or $_.InterfaceAlias -ne $local.Interfaz } |
    Select-Object -ExpandProperty InterfaceAlias -Unique)
$avisoSalida = if ($otrasSalidas.Count -gt 0) { 'Otras salidas activas: ' + ($otrasSalidas -join ', ') + '. Desconectarlas para que V' + $Vlan + '-03 pase por el hEX.' } else { 'Ninguna otra salida a internet activa' }

Write-Host ""
Write-Host "Matriz de ACL, VLAN $Vlan $($Redes[$Vlan]) desde $env:COMPUTERNAME, $ipTxt" -ForegroundColor White
Write-Host ("{0}" -f $inicio.ToString('yyyy-MM-dd HH:mm:ss')) -ForegroundColor DarkGray
if ($otrasSalidas.Count -gt 0) { Write-Host "AVISO: $avisoSalida" -ForegroundColor Yellow }
Write-Host ""

$resultados = foreach ($c in (Get-Casos $Vlan)) {
    $obtenido = [bool](Invoke-Caso $c)
    $ok = ($obtenido -eq $c.Esperado)
    $txtEsp = if ($c.Esperado) { 'Permitido' } else { 'Bloqueado' }
    $txtObt = if ($obtenido) { 'Permitido' } else { 'Bloqueado' }
    $color = if ($ok) { 'Green' } else { 'Red' }
    Write-Host ("[{0}] {1,-7} {2,-36} {3,-22} esperado {4,-9} obtenido {5}" -f ($(if ($ok) { 'OK ' } else { 'ERR' })), $c.Id, $c.Descripcion, $c.Texto, $txtEsp, $txtObt) -ForegroundColor $color
    [pscustomobject]@{
        Id = $c.Id; Descripcion = $c.Descripcion; Destino = $c.Texto
        Esperado = $txtEsp; Obtenido = $txtObt; Resultado = $(if ($ok) { 'Cumple' } else { 'No cumple' }); Regla = $c.Regla
    }
}

$total = @($resultados).Count
$cumplen = @($resultados | Where-Object Resultado -eq 'Cumple').Count
Write-Host ""
Write-Host "$cumplen de $total pruebas cumplen" -ForegroundColor $(if ($cumplen -eq $total) { 'Green' } else { 'Yellow' })

# ------------------------------------------------------------------ informe
$dir = Join-Path $PSScriptRoot 'resultados'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$archivo = Join-Path $dir ("vlan{0}-{1}.md" -f $Vlan, $inicio.ToString('yyyyMMdd-HHmmss'))

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Prueba de matriz de ACL, VLAN $Vlan $($Redes[$Vlan])")
$md.Add("")
$md.Add("| Dato | Valor |")
$md.Add("|---|---|")
$md.Add("| Fecha y hora | $($inicio.ToString('yyyy-MM-dd HH:mm:ss')) (America/Guatemala) |")
$md.Add("| Equipo | $env:COMPUTERNAME |")
$md.Add("| IP de origen | $ipTxt |")
$md.Add("| Extension | $Extension |")
$md.Add("| Reglas PRUEBA-QOS | $(if ($ModoQoS) { 'Activas' } else { 'Inactivas' }) |")
$md.Add("| Otras salidas a internet | $avisoSalida |")
$md.Add("| Resultado | $cumplen de $total cumplen |")
$md.Add("")
$md.Add("| Id | Prueba | Destino | Esperado | Obtenido | Resultado | Regla que lo explica |")
$md.Add("|---|---|---|---|---|---|---|")
foreach ($r in $resultados) {
    $md.Add("| $($r.Id) | $($r.Descripcion) | ``$($r.Destino)`` | $($r.Esperado) | $($r.Obtenido) | $($r.Resultado) | $($r.Regla) |")
}
$md | Out-File -FilePath $archivo -Encoding utf8
Write-Host "Informe: $archivo" -ForegroundColor DarkGray

if ($cumplen -ne $total) { exit 1 }
