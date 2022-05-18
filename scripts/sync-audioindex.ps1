param ($OutputFile = ".\data\audio\index.json")

$projectRoot = Get-Location
.\scripts\get-audioindex.ps1 | Out-File -FilePath $OutputFile