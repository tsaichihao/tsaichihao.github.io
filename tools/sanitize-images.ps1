[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string[]]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

foreach ($inputPath in $Path) {
  $resolved = (Resolve-Path -LiteralPath $inputPath).Path
  $extension = [System.IO.Path]::GetExtension($resolved).ToLowerInvariant()
  if ($extension -notin @(".jpg", ".jpeg", ".png")) {
    throw "Unsupported image format: $resolved"
  }

  $source = [System.Drawing.Image]::FromFile($resolved)
  try {
    $pixelFormat = if ($extension -eq ".png") {
      [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    } else {
      [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    }
    $bitmap = New-Object System.Drawing.Bitmap($source.Width, $source.Height, $pixelFormat)

    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        if ($extension -ne ".png") {
          $graphics.Clear([System.Drawing.Color]::White)
        }
        $graphics.DrawImageUnscaled($source, 0, 0)
      } finally {
        $graphics.Dispose()
      }

      $temporaryPath = "$resolved.sanitized"
      if ($extension -eq ".png") {
        $bitmap.Save($temporaryPath, [System.Drawing.Imaging.ImageFormat]::Png)
      } else {
        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
          Where-Object MimeType -eq "image/jpeg" |
          Select-Object -First 1
        $encoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
          [System.Drawing.Imaging.Encoder]::Quality,
          [long]92
        )
        $bitmap.Save($temporaryPath, $jpegCodec, $encoderParameters)
      }
    } finally {
      $bitmap.Dispose()
    }
  } finally {
    $source.Dispose()
  }

  Move-Item -LiteralPath $temporaryPath -Destination $resolved -Force
  Write-Host "Metadata removed: $resolved"
}
