#Requires -Version 6.0
param(
  $AwbDirectory = "C:\Program Files (x86)\Steam\steamapps\common\Tales of Symphonia\P12E\Data\TOS_Server\Rawdata\WIN",
  $OutputDirectory = ".\data\audio",
  $AwbUnpacker = ".\vendor\awb-tools\AWB_unpacker.exe",
  $adx2wav = ".\vendor\awb-tools\ADX2WAV.EXE"
)
# This script requires features (`Get-Content`s `-AsByteStream`) that was added
# in PowerShell 6. This script was developed against PowerShell 7.
Write-Host $AwbDirectory
New-Item $OutputDirectory -ItemType Directory -Force

# Unpack the AWB files and move them to the output directory
Get-ChildItem $AwbDirectory -Filter *.AWB | ForEach-Object {
  Write-Host "$OutputDirectory\$($_.FullName.Substring($AwbDirectory.Length + 1))"
  & $AwbUnpacker $_.FullName
  Move-Item "$($_)_extracted_files" -Destination "$OutputDirectory\$($_.FullName.Substring($AwbDirectory.Length + 1))"
}

function Test-IsAdxFile([string]$Path) {
  $bytes = Get-Content $Path -AsByteStream -TotalCount 4
  if (($bytes[0] -eq 0x80) -and ($bytes[1] -eq 0x00)) {
    $copyrightOffset = (([int]$bytes[2] -shl 8) -bor [int]$bytes[3]) - 2
    $bytes = Get-Content $Path -AsByteStream -TotalCount ($copyrightOffset + 6)
    $copyright = [System.Text.Encoding]::ASCII.GetString($bytes[-6..-1])
    if ($copyright -eq "(c)CRI") {
      return $true
    }
  }
  return $false
}

# Rename bin files to ADX if they match the magic numbers
Get-ChildItem $OutputDirectory -Recurse -Filter *.bin | Where-Object {
  Test-IsAdxFile $_
} | ForEach-Object {
  $adxFileName = "$([System.Io.Path]::GetDirectoryName($_))\$([System.Io.Path]::GetFileNameWithoutExtension($_)).adx"
  Write-Host "$_ -> $adxFileName"
  Move-Item $_ -Destination $adxFileName
}

# Remove any remaining bin files since they aren't audio
Get-ChildItem $OutputDirectory -Recurse -Filter *.bin | ForEach-Object {
  Remove-Item $_
}

# Convert the ADX files to WAV and delete the ADX file
Get-ChildItem $OutputDirectory -Recurse -Filter *.adx | ForEach-Object {
  $wavFileName = "$([System.Io.Path]::GetDirectoryName($_))\$([System.Io.Path]::GetFileNameWithoutExtension($_)).wav"
  Write-Host "$_ -> $wavFileName"
  & $adx2wav $_ $wavFileName
  Remove-Item $_
}