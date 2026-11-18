param([string]$Site = 'https://ridiconclaudio.github.io/rigscore/')
# Builds the site into docs\ (served by GitHub Pages) from the sources in src\.
# Usage: powershell -ExecutionPolicy Bypass -File build.ps1 [-Site https://example.github.io/rigscore/]
$d = $PSScriptRoot; $u8 = New-Object Text.UTF8Encoding $false
if (-not $Site.EndsWith('/')) { $Site += '/' }
$read = { param($f) [IO.File]::ReadAllText((Join-Path (Join-Path $d 'src') $f)).TrimStart([char]0xFEFF) }
$scan = (& $read 'scan.ps1').Replace('%%SITE%%', $Site).Trim()
$inst = (& $read 'site-install.tpl.ps1').Replace('%%SITE%%', $Site).Trim()
$body = (& $read 'rigscore.src.html').Replace('%%SITE%%', $Site).Replace('%%PS%%', $scan).Replace('%%INST%%', $inst).Replace('%%I18N%%', (& $read 'i18n-en.js'))
$outDir = Join-Path $d 'docs'; New-Item -ItemType Directory -Force $outDir | Out-Null
$head = @'
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="description" content="RigScore: scan your PC, see how games will run, and get software tweaks and hardware upgrade advice with prices.">
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 28 28'%3E%3Crect x='1.5' y='1.5' width='25' height='25' rx='6' fill='%23161B22' stroke='%23FF7B3A' stroke-width='2'/%3E%3Cpath d='M6 18 L10 12 L14 15 L18 8 L22 11' fill='none' stroke='white' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/%3E%3C/svg%3E">
<style>:root{color-scheme:light;padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0;font-size:14px;font-family:system-ui,sans-serif}img{max-width:100%}[hidden]{display:none!important}</style>

'@
[IO.File]::WriteAllText((Join-Path $outDir 'index.html'), $head + $body, $u8)
[IO.File]::WriteAllText((Join-Path $outDir 'scan.ps1'), $scan, $u8)
[IO.File]::WriteAllText((Join-Path $outDir 'install.ps1'), $inst, $u8)
[IO.File]::WriteAllText((Join-Path $outDir '.nojekyll'), '', $u8)
# Body-only copy for the claude.ai artifact preview (not committed).
[IO.File]::WriteAllText((Join-Path $d 'bancopc.html'), $body, $u8)
Write-Host "Build OK for $Site"
