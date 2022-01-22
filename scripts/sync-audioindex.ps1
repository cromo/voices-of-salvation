param ($OutputFile = ".\data\audio\index.txt")

$projectRoot = Get-Location
Get-ChildItem .\data\audio -Recurse -Filter *.wav | ForEach-Object {
  Add-Content $OutputFile $_.ToString().Substring("$projectRoot\data".Length).Replace("\", "/")
}