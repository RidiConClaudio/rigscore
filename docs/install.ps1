& {
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
$d = Join-Path $env:LOCALAPPDATA 'you_are_incredible\RigScore'
$o = Join-Path $env:LOCALAPPDATA 'RigScore'; if (Test-Path $o) { Remove-Item $o -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path $d | Out-Null
$f = Join-Path $d 'scan.ps1'
Invoke-WebRequest -UseBasicParsing -Uri 'https://ridiconclaudio.github.io/rigscore/scan.ps1' -OutFile $f
$a = '-NoProfile -ExecutionPolicy Bypass -File "' + $f + '"'
$k = 'HKCU:\Software\Classes\rigscore'
New-Item -Path "$k\shell\open\command" -Force | Out-Null
Set-ItemProperty -Path $k -Name '(default)' -Value 'URL:RigScore'
Set-ItemProperty -Path $k -Name 'URL Protocol' -Value ''
Set-ItemProperty -Path "$k\shell\open\command" -Name '(default)' -Value ('powershell.exe ' + $a)
$w = New-Object -ComObject WScript.Shell
$l = $w.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) 'RigScore.lnk'))
$l.TargetPath = 'powershell.exe'; $l.Arguments = $a; $l.IconLocation = 'shell32.dll,15'; $l.Description = 'Scansione RigScore'; $l.Save()
Write-Host ''
if ((Get-Culture).TwoLetterISOLanguageName -eq 'it') { Write-Host '  RigScore installato: pulsante "Avvia scansione" e icona RigScore sul Desktop.' -ForegroundColor Green } else { Write-Host '  RigScore installed: "Start scan" button and RigScore icon on the Desktop.' -ForegroundColor Green }
& $f
}