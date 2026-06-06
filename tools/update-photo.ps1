[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("Profile", "Gallery")]
  [string]$Mode,

  [Parameter(Mandatory = $true)]
  [string]$ImagePath,

  [ValidateLength(0, 120)]
  [string]$Caption = "",

  [switch]$Publish
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = (Resolve-Path -LiteralPath $ImagePath).Path
$sourceItem = Get-Item -LiteralPath $sourcePath

if ($sourceItem.Length -gt 20MB) {
  throw "The image must not exceed 20 MB."
}

Add-Type -AssemblyName System.Drawing

function Apply-ExifOrientation {
  param([System.Drawing.Image]$Image)

  $orientationId = 0x0112
  if (-not ($Image.PropertyIdList -contains $orientationId)) {
    return
  }

  $orientation = $Image.GetPropertyItem($orientationId).Value[0]
  $rotation = switch ($orientation) {
    2 { [System.Drawing.RotateFlipType]::RotateNoneFlipX }
    3 { [System.Drawing.RotateFlipType]::Rotate180FlipNone }
    4 { [System.Drawing.RotateFlipType]::Rotate180FlipX }
    5 { [System.Drawing.RotateFlipType]::Rotate90FlipX }
    6 { [System.Drawing.RotateFlipType]::Rotate90FlipNone }
    7 { [System.Drawing.RotateFlipType]::Rotate270FlipX }
    8 { [System.Drawing.RotateFlipType]::Rotate270FlipNone }
    default { [System.Drawing.RotateFlipType]::RotateNoneFlipNone }
  }
  $Image.RotateFlip($rotation)
}

function Save-SanitizedJpeg {
  param(
    [string]$InputPath,
    [string]$OutputPath
  )

  $source = [System.Drawing.Image]::FromFile($InputPath)
  try {
    Apply-ExifOrientation -Image $source
    $maxDimension = 1600
    $scale = [Math]::Min(1, $maxDimension / [Math]::Max($source.Width, $source.Height))
    $width = [Math]::Max(1, [Math]::Round($source.Width * $scale))
    $height = [Math]::Max(1, [Math]::Round($source.Height * $scale))
    $bitmap = New-Object System.Drawing.Bitmap($width, $height)

    try {
      $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
      try {
        $graphics.Clear([System.Drawing.Color]::White)
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $graphics.DrawImage($source, 0, 0, $width, $height)
      } finally {
        $graphics.Dispose()
      }

      $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
        Where-Object MimeType -eq "image/jpeg" |
        Select-Object -First 1
      $encoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
      $encoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
        [System.Drawing.Imaging.Encoder]::Quality,
        [long]88
      )

      $outputDirectory = Split-Path -Parent $OutputPath
      New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
      $temporaryPath = "$OutputPath.sanitized"
      $bitmap.Save($temporaryPath, $jpegCodec, $encoderParameters)
    } finally {
      $bitmap.Dispose()
    }
  } finally {
    $source.Dispose()
  }

  Move-Item -LiteralPath $temporaryPath -Destination $OutputPath -Force
}

$changedPaths = @()

if ($Mode -eq "Profile") {
  $relativePath = "assets/photos/archer-tsai-profile.jpg"
  $destination = Join-Path $repoRoot $relativePath
  Save-SanitizedJpeg -InputPath $sourcePath -OutputPath $destination
  $changedPaths += $relativePath
} else {
  $filename = "{0}.jpg" -f (Get-Date -Format "yyyyMMdd-HHmmss")
  $relativePath = "assets/photos/$filename"
  $destination = Join-Path $repoRoot $relativePath
  Save-SanitizedJpeg -InputPath $sourcePath -OutputPath $destination

  $manifestPath = Join-Path $repoRoot "photos.json"
  $photos = @()
  if (Test-Path -LiteralPath $manifestPath) {
    $content = Get-Content -LiteralPath $manifestPath -Raw
    if (-not [string]::IsNullOrWhiteSpace($content)) {
      $photos = @($content | ConvertFrom-Json)
    }
  }

  $entry = [ordered]@{
    src = $relativePath
    caption = $Caption.Trim()
    alt = if ($Caption.Trim()) { $Caption.Trim() } else { "Archer Tsai photo" }
  }
  @($entry) + $photos |
    ConvertTo-Json -Depth 4 |
    Set-Content -LiteralPath $manifestPath -Encoding utf8

  $changedPaths += $relativePath
  $changedPaths += "photos.json"
}

Write-Host "Image processed and metadata removed: $relativePath"

if ($Publish) {
  & git -C $repoRoot add -- $changedPaths
  & git -C $repoRoot diff --cached --check
  & git -C $repoRoot commit -m "Update portfolio photo"
  & git -C $repoRoot push
  Write-Host "Changes committed and pushed to GitHub."
} else {
  Write-Host "Not published. Run again with -Publish after reviewing the result."
}
