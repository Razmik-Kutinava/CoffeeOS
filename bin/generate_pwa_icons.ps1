$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$outDir = Join-Path $PSScriptRoot "..\public\pwa"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Write-Icon($size, $path) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::FromArgb(255, 26, 26, 26))
  $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 255, 140, 66))
  $pad = [int]($size * 0.125)
  $g.FillEllipse($brush, $pad, $pad, $size - 2 * $pad, $size - 2 * $pad)
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

Write-Icon 192 (Join-Path $outDir "icon-192.png")
Write-Icon 512 (Join-Path $outDir "icon-512.png")
Write-Icon 180 (Join-Path $outDir "apple-touch-icon.png")
Write-Host "Wrote icons to $outDir"
