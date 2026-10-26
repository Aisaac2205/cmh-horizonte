<#
.SYNOPSIS
  Saca la evidencia de configuracion y contadores del hEX por SSH con llave.

.DESCRIPTION
  Corre una lista fija de comandos de solo lectura en el router y guarda cada
  salida en pruebas/evidencias/router-<fecha>/, mas un resumen.md con el indice.
  Sirve para el anexo del informe: VLAN, DHCP, firewall con contadores, NAT,
  mangle, colas y export. Correrlo antes y despues de cada prueba de QoS.

  Preparacion (una sola vez, desde la laptop de GESTION):
    ssh-keygen -t ed25519 -f "$env:USERPROFILE\.ssh\cmh_hex_ed25519" -C cmh-hex
    Winbox, Files: subir cmh_hex_ed25519.pub
    Terminal:      /user ssh-keys import public-key-file=cmh_hex_ed25519.pub user=<usuario>

.EXAMPLE
  .\Evidencia-Router.ps1 -Usuario cmhti
  .\Evidencia-Router.ps1 -Usuario cmhti -Etiqueta antes-qos -ReiniciarContadores
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$Usuario,

    [string]$Router = '172.16.10.1',

    [string]$Llave = (Join-Path $env:USERPROFILE '.ssh\cmh_hex_ed25519'),

    # Texto corto que se agrega al nombre de la carpeta (antes-qos, despues-qos)
    [ValidatePattern('^[a-z0-9-]*$')]
    [string]$Etiqueta = '',

    # Pone en cero los contadores de firewall y colas DESPUES de sacar la evidencia,
    # para que la siguiente corrida muestre solo lo de la prueba
    [switch]$ReiniciarContadores
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Comandos de solo lectura. Nombre del archivo -> comando de RouterOS
$Comandos = [ordered]@{
    '00-identidad-y-hora'   = '/system identity print; /system clock print; /system resource print'
    '01-interfaces'         = '/interface print without-paging'
    '02-listas-interfaces'  = '/interface list member print without-paging'
    '03-bridge-puertos'     = '/interface bridge port print without-paging'
    '04-bridge-vlan'        = '/interface bridge vlan print without-paging'
    '05-direcciones'        = '/ip address print without-paging'
    '06-rutas'              = '/ip route print without-paging'
    '07-dhcp-servidores'    = '/ip dhcp-server print without-paging; /ip dhcp-server network print without-paging'
    '08-dhcp-leases'        = '/ip dhcp-server lease print without-paging'
    '09-dhcp-cliente-wan'   = '/ip dhcp-client print without-paging'
    '10-address-lists'      = '/ip firewall address-list print without-paging'
    '11-firewall-filter'    = '/ip firewall filter print stats without-paging'
    '12-firewall-nat'       = '/ip firewall nat print stats without-paging'
    '13-firewall-mangle'    = '/ip firewall mangle print stats without-paging'
    '14-queue-tree'         = '/queue tree print stats without-paging'
    '15-queue-simple'       = '/queue simple print stats without-paging'
    '16-servicios'          = '/ip service print without-paging'
    '17-log-firewall'       = '/log print without-paging where topics~firewall'
    '18-export'             = '/export'
}

function Invoke-RouterOS([string]$Comando) {
    $sshArgs = @(
        '-i', $Llave,
        '-o', 'BatchMode=yes',
        '-o', 'ConnectTimeout=5',
        '-o', 'StrictHostKeyChecking=accept-new',
        "$Usuario@$Router",
        $Comando
    )
    $salida = & ssh.exe @sshArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "ssh fallo ($LASTEXITCODE): $($salida -join ' ')" }
    return ($salida -join "`r`n")
}

if (-not (Test-Path $Llave)) {
    throw "No existe la llave $Llave. Ver la seccion Preparacion con: Get-Help .\Evidencia-Router.ps1 -Full"
}

$inicio = Get-Date
$nombre = 'router-' + $inicio.ToString('yyyyMMdd-HHmmss') + $(if ($Etiqueta) { "-$Etiqueta" } else { '' })
$dir = Join-Path (Join-Path $PSScriptRoot 'evidencias') $nombre
New-Item -ItemType Directory -Path $dir -Force | Out-Null

Write-Host "Evidencia del hEX ($Usuario@$Router) en $dir" -ForegroundColor White

$filas = foreach ($k in $Comandos.Keys) {
    $ext = if ($k -eq '18-export') { 'rsc' } else { 'txt' }
    $archivo = Join-Path $dir "$k.$ext"
    try {
        $texto = Invoke-RouterOS $Comandos[$k]
        $encabezado = "# $($Comandos[$k])`r`n# $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') desde $env:COMPUTERNAME`r`n`r`n"
        ($encabezado + $texto) | Out-File -FilePath $archivo -Encoding utf8
        Write-Host ("  [OK ] {0}" -f $k) -ForegroundColor Green
        [pscustomobject]@{ Archivo = "$k.$ext"; Comando = $Comandos[$k]; Estado = 'OK' }
    } catch {
        Write-Host ("  [ERR] {0}  {1}" -f $k, $_.Exception.Message) -ForegroundColor Red
        [pscustomobject]@{ Archivo = "$k.$ext"; Comando = $Comandos[$k]; Estado = 'Error' }
    }
}

if ($ReiniciarContadores) {
    Invoke-RouterOS '/ip firewall filter reset-counters-all; /ip firewall mangle reset-counters-all; /ip firewall nat reset-counters-all; /queue tree reset-counters-all; /queue simple reset-counters-all' | Out-Null
    Write-Host '  Contadores en cero para la siguiente prueba' -ForegroundColor Yellow
}

$md = New-Object System.Collections.Generic.List[string]
$md.Add("# Evidencia del router hEX, $($inicio.ToString('yyyy-MM-dd HH:mm:ss'))")
$md.Add("")
$md.Add("Router $Router, usuario $Usuario, equipo $env:COMPUTERNAME. Etiqueta: $(if ($Etiqueta) { $Etiqueta } else { 'ninguna' }).")
$md.Add("Contadores reiniciados al final: $(if ($ReiniciarContadores) { 'si' } else { 'no' }).")
$md.Add("")
$md.Add("| Archivo | Comando | Estado |")
$md.Add("|---|---|---|")
foreach ($f in $filas) { $md.Add("| $($f.Archivo) | ``$($f.Comando)`` | $($f.Estado) |") }
$md | Out-File -FilePath (Join-Path $dir 'resumen.md') -Encoding utf8

$errores = @($filas | Where-Object Estado -eq 'Error').Count
if ($errores -gt 0) { Write-Host "$errores comandos fallaron" -ForegroundColor Yellow; exit 1 }
Write-Host 'Listo' -ForegroundColor Green
