Get-ChildItem .\data\audio -Recurse -Filter *.wav | ForEach-Object {
  ".$($_.FullName.Substring($pwd.Path.Length))"
} | ConvertTo-Json
