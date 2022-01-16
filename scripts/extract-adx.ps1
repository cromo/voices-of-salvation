# $param1 = $args[0]
param(
  $AwbDirectory = "C:\Program Files (x86)\Steam\steamapps\common\Tales of Symphonia\P12E\Data\TOS_Server\Rawdata\WIN",
  $AwbUnpacker = ".\vendor\awb-tools\AWB_unpacker.exe",
  $OutputDirectory = ".\data\audio"
)
Write-Host $AwbDirectory
New-Item $OutputDirectory -ItemType Directory -Force

Get-ChildItem $AwbDirectory -Filter *.AWB | ForEach-Object {
  Write-Host "$OutputDirectory\$($_.FullName.Substring($AwbDirectory.Length + 1))"
  & $AwbUnpacker $_.FullName
  Move-Item "$($_)_extracted_files" -Destination "$OutputDirectory\$($_.FullName.Substring($AwbDirectory.Length + 1))"
}
