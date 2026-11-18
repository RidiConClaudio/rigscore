# RigScore

**Scan your Windows PC, see how 40 popular games will run on it, and get concrete software tweaks and hardware upgrade advice with prices.**

🌐 **Live site:** https://ridiconclaudio.github.io/rigscore/ — English and Italian, with currency and shops for Italy, US, UK, Germany, France, Spain and other countries.

## What it does

- **Overview** – a 0–100 gaming score, the PC type (desktop, laptop, all-in-one, mini PC), every component with its rating, and the CPU/GPU bottleneck.
- **Games** – a percentage per game (40% = minimum specs, 70% = recommended, 100% = max settings with headroom) and estimated FPS at 1080p, 1440p or 4K. It also flags hard blockers: ray tracing required, Secure Boot needed by anti-cheat, too little RAM or VRAM.
- **Optimize** – 20+ checks on your actual system, each with a ready-to-copy command: OS support status, GPU drivers, power plan, Game Mode, hardware GPU scheduling, memory integrity (VBS), startup programs, bloatware and debloat tools, duplicate antivirus, disk space, XMP/EXPO, single-channel RAM, Secure Boot, BIOS age, laptop thermals and battery health.
- **Upgrade** – advice that is aware of the motherboard and socket: drop-in CPUs, GPUs capped by what your CPU can actually drive, a new platform (CPU + board + RAM), RAM and SSD. Each option shows price, performance gain, how many more games would run, a value rating and links to shops in your country. For laptops it covers RAM, storage, cooling and a comparison with buying a new PC.

## How to use it

Open the site: the browser alone detects the graphics card, threads, approximate RAM and runs a quick CPU benchmark.

For the full analysis (CPU model, RAM type/speed/slots, drives, motherboard, Windows edition and settings), run **one line in PowerShell** (`Win`+`X` → Windows PowerShell):

```powershell
irm https://ridiconclaudio.github.io/rigscore/scan.ps1 | iex
```

After 10–30 seconds RigScore opens with your results.

**One-click option:** install it once and from then on use the *Start scan* button on the site or the RigScore icon on your Desktop:

```powershell
irm https://ridiconclaudio.github.io/rigscore/install.ps1 | iex
```

No admin rights are needed. The installer saves the script to `%LOCALAPPDATA%\RigScore`, registers a `rigscore://` link and creates a Desktop shortcut. To remove it:

```powershell
Remove-Item 'HKCU:\Software\Classes\rigscore' -Recurse; Remove-Item "$env:LOCALAPPDATA\RigScore" -Recurse; Remove-Item "$([Environment]::GetFolderPath('Desktop'))\RigScore.lnk"
```

## Privacy and safety

- The scan script **only reads** system information (WMI/CIM and the registry). It installs nothing and changes nothing. Read it here: [`src/scan.ps1`](src/scan.ps1).
- Results travel in the URL fragment (`#…`), which browsers never send to the server. They are processed only in your browser and kept in its local storage.
- The script reports bloatware names only when they match a known list; it does not upload your list of installed programs.

## Limits

- Game performance is estimated from official requirements and relative GPU/CPU indexes: expect ±20–30%.
- Prices are mid-2026 estimates in euros, converted roughly for other currencies. Always check the shop links for today's prices.
- The full scan works on Windows only.

## Project structure

```
src/rigscore.src.html     page source (Italian base text, all logic)
src/i18n-en.js            Italian → English dictionary applied at runtime
src/scan.ps1              scan script (%%SITE%% is replaced at build time)
src/site-install.tpl.ps1  installer template
build.ps1                 builds the site into docs/
docs/                     generated site, served by GitHub Pages
```

Build after editing the sources:

```powershell
powershell -ExecutionPolicy Bypass -File build.ps1
```

## License

[MIT](LICENSE)
