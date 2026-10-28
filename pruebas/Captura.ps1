<#
.SYNOPSIS
  Guarda una captura de la ventana activa (Winbox, navegador, Linphone) en capturas/.

.DESCRIPTION
  Espera unos segundos para que se pueda pasar a la ventana que se quiere capturar
  (Alt+Tab), toma solo esa ventana y la guarda como PNG con el nombre indicado.
  Si el archivo ya existe lo reemplaza, asi las capturas viejas de clase C se
  cambian por las nuevas sin tocar la DOCUMENTACION.

.EXAMPLE
  .\Captura.ps1 34-hex-direcciones
  .\Captura.ps1 39-hex-queue-tree -Retraso 5
  .\Captura.ps1 60-acl-vlan30-admin -PantallaCompleta
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidatePattern('^[0-9a-z][0-9a-z-]*$')]
    [string]$Nombre,

    [ValidateRange(0, 30)]
    [int]$Retraso = 3,

    [switch]$PantallaCompleta,

    [string]$Carpeta = (Join-Path (Split-Path $PSScriptRoot -Parent) 'capturas')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Drawing, System.Windows.Forms
if (-not ('CmhVentana' -as [type])) {
    Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class CmhVentana {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr h, int attr, out RECT r, int size);
}
'@
}
[void][CmhVentana]::SetProcessDPIAware()

if ($Retraso -gt 0) {
    Write-Host "Cambie a la ventana que quiere capturar. Captura en $Retraso s..." -ForegroundColor Cyan
    Start-Sleep -Seconds $Retraso
}

if ($PantallaCompleta) {
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
} else {
    $r = New-Object CmhVentana+RECT
    # 9 = DWMWA_EXTENDED_FRAME_BOUNDS, el borde visible sin la sombra de Windows
    [void][CmhVentana]::DwmGetWindowAttribute([CmhVentana]::GetForegroundWindow(), 9, [ref]$r, 16)
    $area = [System.Drawing.Rectangle]::FromLTRB($r.Left, $r.Top, $r.Right, $r.Bottom)
    if ($area.Width -lt 50 -or $area.Height -lt 50) { throw 'No se pudo leer la ventana activa. Repita con -PantallaCompleta.' }
}

$bmp = New-Object System.Drawing.Bitmap $area.Width, $area.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
try {
    $g.CopyFromScreen($area.Location, [System.Drawing.Point]::Empty, $area.Size)
    if (-not (Test-Path $Carpeta)) { New-Item -ItemType Directory -Path $Carpeta | Out-Null }
    $destino = Join-Path $Carpeta "$Nombre.png"
    $bmp.Save($destino, [System.Drawing.Imaging.ImageFormat]::Png)
} finally { $g.Dispose(); $bmp.Dispose() }

[System.Media.SystemSounds]::Asterisk.Play()
Write-Host "Guardada $destino ($($area.Width)x$($area.Height))" -ForegroundColor Green
