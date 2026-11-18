& {
$ErrorActionPreference = 'SilentlyContinue'
$it = (Get-Culture).TwoLetterISOLanguageName -eq 'it'
Write-Host ''
Write-Host $(if ($it) { '  RigScore: lettura delle specifiche in corso (10-30 secondi)...' } else { '  RigScore: reading your PC specs (10-30 seconds)...' }) -ForegroundColor Cyan
function S($v) { if ($null -eq $v) { $null } else { ("$v" -replace "`0", '').Trim() } }
$o = [ordered]@{ v = 2; t = (Get-Date).ToString('s') }
$cs = Get-CimInstance Win32_ComputerSystem
$os = Get-CimInstance Win32_OperatingSystem
$cv = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
$enc = Get-CimInstance Win32_SystemEnclosure | Select-Object -First 1
$bat = Get-CimInstance Win32_Battery | Select-Object -First 1
$bb = Get-CimInstance Win32_BaseBoard | Select-Object -First 1
$bios = Get-CimInstance Win32_BIOS | Select-Object -First 1
$sb = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State').UEFISecureBootEnabled
$batHealth = $null
try {
  $d = (Get-CimInstance -Namespace root\wmi -ClassName BatteryStaticData -ErrorAction Stop | Select-Object -First 1).DesignedCapacity
  $f = (Get-CimInstance -Namespace root\wmi -ClassName BatteryFullChargedCapacity -ErrorAction Stop | Select-Object -First 1).FullChargedCapacity
  if ($d -gt 0 -and $f -gt 0) { $batHealth = [math]::Round(100 * $f / $d) }
} catch {}
$o.sys = [ordered]@{
  maker = S $cs.Manufacturer; model = S $cs.Model; chassis = @($enc.ChassisTypes); pcType = $cs.PCSystemType
  battery = [bool]$bat; batteryHealth = $batHealth
  board = S "$($bb.Manufacturer) $($bb.Product)"; bios = S "$($bios.SMBIOSBIOSVersion)"; biosDate = $(if ($bios.ReleaseDate) { $bios.ReleaseDate.ToString('yyyy-MM-dd') })
  uefi = ($null -ne $sb); secureBoot = ($sb -eq 1)
}
$o.os = [ordered]@{
  name = S $os.Caption; ver = S $os.Version; build = [int]$os.BuildNumber; ubr = $cv.UBR; disp = S $cv.DisplayVersion
  arch = S $os.OSArchitecture; installed = $(if ($os.InstallDate) { $os.InstallDate.ToString('yyyy-MM-dd') })
  uptimeH = [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours, 1)
  ramFreeMB = [math]::Round($os.FreePhysicalMemory / 1024); procs = @(Get-Process).Count
}
$cpu = Get-CimInstance Win32_Processor | Select-Object -First 1
$o.cpu = [ordered]@{ name = S $cpu.Name; cores = $cpu.NumberOfCores; threads = $cpu.NumberOfLogicalProcessors; mhz = $cpu.MaxClockSpeed; socket = S $cpu.SocketDesignation; l3KB = $cpu.L3CacheSize; virt = $cpu.VirtualizationFirmwareEnabled }
$reg = Get-ChildItem 'HKLM:\SYSTEM\ControlSet001\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}' | ForEach-Object { Get-ItemProperty $_.PSPath } | Where-Object { $_.DriverDesc }
$o.gpu = @(Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Remote|Virtual|Basic Display|Mirage|Parsec|Indirect' } | ForEach-Object {
  $n = S $_.Name; $r = $reg | Where-Object { $_.DriverDesc -eq $n } | Select-Object -First 1
  $vram = $r.'HardwareInformation.qwMemorySize'
  if (-not $vram) { $m = $r.'HardwareInformation.MemorySize'; if ($m -is [byte[]]) { $vram = [BitConverter]::ToUInt32($m, 0) } elseif ($m) { $vram = $m } }
  if (-not $vram) { $vram = $_.AdapterRAM }
  [ordered]@{ name = $n; vramMB = [math]::Round([double]$vram / 1MB); driver = S $_.DriverVersion; driverDate = $(if ($_.DriverDate) { $_.DriverDate.ToString('yyyy-MM-dd') }); w = $_.CurrentHorizontalResolution; h = $_.CurrentVerticalResolution; hz = $_.CurrentRefreshRate; maxHz = $_.MaxRefreshRate }
})
$o.mon = @(Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorID | ForEach-Object {
  [ordered]@{ n = S (($_.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ''); mf = S (($_.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join ''); year = $_.YearOfManufacture }
})
$arr = Get-CimInstance Win32_PhysicalMemoryArray | Where-Object { $_.Use -eq 3 }
$sticks = @(Get-CimInstance Win32_PhysicalMemory | Where-Object { $_.Capacity -gt 0 } | ForEach-Object { [ordered]@{ gb = [math]::Round($_.Capacity / 1GB); speed = $_.Speed; cfg = $_.ConfiguredClockSpeed; type = $_.SMBIOSMemoryType; mtype = $_.MemoryType; ff = $_.FormFactor; maker = S $_.Manufacturer; part = S $_.PartNumber; slot = S $_.DeviceLocator; volt = $_.ConfiguredVoltage } })
$o.ram = [ordered]@{
  slots = ($arr | Measure-Object MemoryDevices -Sum).Sum; maxGB = [math]::Round((($arr | Measure-Object MaxCapacityEx -Sum).Sum) / 1MB)
  totalGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1); sumGB = ($sticks | ForEach-Object { $_.gb } | Measure-Object -Sum).Sum
  sticks = $sticks
}
$msft = @(Get-CimInstance -Namespace root\Microsoft\Windows\Storage -ClassName MSFT_PhysicalDisk)
$pds = @(Get-PhysicalDisk)
if ($pds.Count) {
  $o.disks = @($pds | ForEach-Object {
    $num = "$($_.DeviceId)"; $mf = $msft | Where-Object { "$($_.DeviceId)" -eq $num } | Select-Object -First 1
    $media = S $_.MediaType; $bus = S $_.BusType; $nm = S $_.FriendlyName; $rpm = $mf.SpindleSpeed
    if ($bus -in 'RAID', 'SCSI', 'Unknown' -and $nm -match 'NVMe|PCIe') { $bus = 'NVMe' }
    if ($media -notin 'SSD', 'HDD') {
      if ($bus -eq 'NVMe' -or $nm -match 'NVMe|SSD|Solid State|M\.2') { $media = 'SSD' }
      elseif ($rpm -eq 0) { $media = 'SSD' }
      elseif ($rpm -gt 0 -and $rpm -lt 100000) { $media = 'HDD' }
      elseif ($bus -eq 'USB') { $media = 'USB' }
    }
    $letters = @(Get-Partition -DiskNumber ([int]$num) | Where-Object { $_.DriveLetter } | ForEach-Object { "$($_.DriveLetter)" })
    $wear = $null; $temp = $null
    try { $rc = $_ | Get-StorageReliabilityCounter -ErrorAction Stop; $wear = $rc.Wear; $temp = $rc.Temperature } catch {}
    [ordered]@{ name = $nm; media = $media; bus = $bus; gb = [math]::Round($_.Size / 1GB); health = S $_.HealthStatus; letters = $letters; wear = $wear; temp = $temp; rpm = $(if ($rpm -lt 100000) { $rpm }) }
  })
} else {
  $o.disks = @(Get-CimInstance Win32_DiskDrive | ForEach-Object {
    $dd = $_
    $letters = @(Get-CimAssociatedInstance -InputObject $dd -ResultClassName Win32_DiskPartition | ForEach-Object { Get-CimAssociatedInstance -InputObject $_ -ResultClassName Win32_LogicalDisk } | ForEach-Object { "$($_.DeviceID)".TrimEnd(':') })
    [ordered]@{ name = S $dd.Model; media = $(if ($dd.Model -match 'SSD|NVMe|Solid') { 'SSD' } else { '?' }); bus = $(if ($dd.Model -match 'NVMe') { 'NVMe' } else { S $dd.InterfaceType }); gb = [math]::Round($dd.Size / 1GB); health = S $dd.Status; letters = $letters }
  })
}
$o.vols = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object { [ordered]@{ l = S $_.DeviceID; gb = [math]::Round($_.Size / 1GB); free = [math]::Round($_.FreeSpace / 1GB); fs = S $_.FileSystem } })
$plan = (powercfg /getactivescheme) -join ' '
$gm = (Get-ItemProperty 'HKCU:\Software\Microsoft\GameBar').AutoGameModeEnabled
$hags = (Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers').HwSchMode
$dg = Get-CimInstance -Namespace root\Microsoft\Windows\DeviceGuard -ClassName Win32_DeviceGuard
$av = @(Get-CimInstance -Namespace root\SecurityCenter2 -ClassName AntiVirusProduct | ForEach-Object { S $_.displayName })
$tpm = $null; try { $t = Get-CimInstance -Namespace root\cimv2\security\microsofttpm -ClassName Win32_Tpm -ErrorAction Stop; if ($t) { $tpm = S ($t.SpecVersion -split ',')[0] } } catch {}
$unk = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*', 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
$apps = @(Get-ItemProperty $unk | Where-Object { $_.DisplayName -and -not $_.SystemComponent } | ForEach-Object { S $_.DisplayName } | Sort-Object -Unique)
$appx = @(Get-AppxPackage | Where-Object { -not $_.IsFramework -and $_.SignatureKind -ne 'System' } | ForEach-Object { $_.Name })
$run = @()
foreach ($k in 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run', 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run') {
  $p = Get-ItemProperty $k; if ($p) { $run += $p.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object { $_.Name } }
}
$run += @(Get-ChildItem "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup", "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp" -Filter *.lnk | ForEach-Object { $_.BaseName })
$o.sw = [ordered]@{
  plan = $(if ($plan -match '\((.+)\)') { $Matches[1] } else { $plan }); gameMode = $gm; hags = $hags
  vbs = $dg.VirtualizationBasedSecurityStatus; hvci = @($dg.SecurityServicesRunning) -contains 2
  av = $av; tpm = $tpm; startup = @($run | Sort-Object -Unique); apps = $apps.Count; appx = $appx
  bloat = @($apps -match 'McAfee|Norton|Avast|AVG |Avira|WildTangent|Booking\.com|ExpressVPN|IObit|Driver Booster|Advanced SystemCare|CCleaner|Wave Browser|OneLaunch|Segurazo|ByteFence|Reimage|HP Wolf|HP Support Assistant|HP Documentation|HP JumpStart|Dell SupportAssist|Candy|TikTok|Microsoft 365 - |Bonjour')
  tools = @($apps -match 'Winhance|WinUtil|ShutUp10|Win11Debloat|Atlas|ReviOS|Process Lasso|MSI Afterburner|Lossless Scaling')
  net = @(Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { [ordered]@{ n = S $_.InterfaceDescription; speed = S $_.LinkSpeed; wifi = ($_.PhysicalMediaType -match '802\.11') } })
  admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
$raw = [Text.Encoding]::UTF8.GetBytes(($o | ConvertTo-Json -Depth 6 -Compress))
$ms = New-Object IO.MemoryStream
$gz = New-Object IO.Compression.GZipStream($ms, [IO.Compression.CompressionMode]::Compress)
$gz.Write($raw, 0, $raw.Length); $gz.Close()
$code = 'PCSCAN2:' + [Convert]::ToBase64String($ms.ToArray()).TrimEnd('=').Replace('+', '-').Replace('/', '_')
Set-Clipboard -Value $code
Start-Process ('%%SITE%%#' + $code)
Write-Host ''
Write-Host $(if ($it) { '  Fatto: si apre RigScore con i risultati.' } else { '  Done: RigScore is opening with your results.' }) -ForegroundColor Green
Write-Host $(if ($it) { '  Se non si apre: il codice e'' negli appunti, premi CTRL+V sulla pagina di RigScore.' } else { '  If it does not open: the code is on your clipboard, press CTRL+V on the RigScore page.' }) -ForegroundColor Green
Write-Host ''
Start-Sleep -Seconds 6
}
