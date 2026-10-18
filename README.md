# Win7 Debloater

A small graphical tool that removes telemetry, nag updates and other bloat from **Windows 7**.
One file, no installation, no dependencies - it uses the PowerShell 2.0 that ships with Windows 7.

You tick what you want, press **Run**, and watch the progress in the log pane.
Nothing is changed until you confirm, and a System Restore point is created first (on by default).

> **Status:** early release. Use at your own risk and read the [disclaimer](#disclaimer).

## Quick start

1. Download `Win7-Debloat-GUI.bat` (or the whole repo as ZIP).
2. Double-click it. It asks for Administrator rights (UAC) by itself.
3. Tick the groups you want (the recommended ones are ticked by default) and press **Run**.
4. Restart when it asks.

## What it can do

| # | Group | Default | What it does |
|---|-------|:------:|--------------|
| 1 | Remove spying updates | on | Uninstalls telemetry / "Get Windows 10" updates: KB2952664, KB2977759, KB2990214, KB3021917, KB3022345, KB3035583, KB3068708, KB3075249, KB3080149, KB3123862, KB3150513 (only those that are installed) |
| 2 | Turn off data collection | on | Registry: CEIP, Windows Error Reporting, application telemetry / inventory collector, Windows 10 upgrade offer (GWX), handwriting data sharing, web print-driver download |
| 3 | Disable unneeded services | on | Fax, RemoteRegistry, WMPNetworkSvc, HomeGroupListener, HomeGroupProvider, SSDPSRV, upnphost, WerSvc, DiagTrack, dmwappushservice |
| 4 | Disable telemetry tasks | on | Scheduled tasks: Application Experience, CEIP, Autochk proxy, disk diagnostics, error reporting queue, GWX |
| 5 | Remove unneeded Windows features | off | Via DISM: games, Media Center, Tablet PC, desktop gadgets, Fax and Scan, DVD Maker (slow, needs a restart) |
| 6 | Clean temporary files | on | `%TEMP%`, `Windows\Temp`, Windows Update download cache, crash dumps |
| 7 | Turn off hibernation | off | `powercfg -h off` - frees disk space equal to your RAM |
| 8 | SSD optimization | off | Disables Superfetch/Prefetch and scheduled defrag. **SSD only!** |
| 9 | Turn off Remote Desktop | off | Disables the RDP services and denies connections |
| 10 | Remove Service Pack 1 backup files | off | `dism /Cleanup-Image /SPSuperseded` - **irreversible**, SP1 can no longer be uninstalled |

Items that do not exist on your system are skipped (`[ -- ]` in the log).
Log tags: `[ OK ]` done, `[ -- ]` skipped, `[ !! ]` warning, `[FAIL]` error with a code.
The log is shown in the window only; the tool writes no log file.

## Undoing changes

* **System Restore** - the easiest way; the tool offers to create a restore point before it starts.
* **Services** - open `services.msc` and set the startup type back (usually *Manual* or *Automatic*).
  The log shows the previous startup type of every service while the tool runs.
* **Scheduled tasks** - `schtasks /change /tn "<task path>" /enable`.
* **Registry values** - the values it sets are listed in the log; delete them or set them back.
* **Windows features** - Control Panel, Programs, *Turn Windows features on or off*.
* **Removed updates** - reinstall them from Windows Update (unhide them first if you hid them).

## Requirements

* Windows 7 (x86 or x64), best with Service Pack 1
* Administrator rights
* PowerShell 2.0 (built in) and DISM (built in)

The tool shows a warning in the log if it detects a different Windows version.

## How it works

`Win7-Debloat.bat` is a single file with two parts:

1. A tiny batch header that asks for elevation and starts PowerShell hidden.
2. A PowerShell + Windows Forms program below the `#PS-BEGIN` marker, which the batch header reads from
   the file itself and runs. No temporary files are written.

All texts live in one `key=value` block near the top of the PowerShell part, so they are easy to edit.
The window icon is embedded in the script as base64.

### Development notes

* Keep the file **ASCII-only** and with **CRLF** line endings (`.gitattributes` enforces CRLF).
* Do not remove or duplicate the `#PS-BEGIN` marker.
* Avoid typographic quotes in the PowerShell part - PowerShell treats them as real quotes.

## FAQ

**My antivirus / SmartScreen warns about it.**
It is a plain-text script that disables services and edits the registry, and it starts PowerShell
hidden - behaviour that heuristics dislike. Read the source (it is one text file) and decide for yourself.

**Why Windows 7? It is out of support.**
Many machines still run it. Debloating reduces data leaks, but it does not replace security updates -
use a current browser and be careful online.

**Can it break something?**
Yes, any system tweaking tool can. Items that depend on your hardware are labelled in the UI
(SSD optimization, Remote Desktop). Create the restore point and untick what you do not understand.

## Icon

The trash-can icon (`assets/Win7-Debloat.ico`, also embedded in the script) is third-party artwork and is
**not** covered by the MIT license. It shows the Windows flag, a Microsoft trademark. This project is not
affiliated with or endorsed by Microsoft.

## Disclaimer

This software is provided "as is", without warranty of any kind. You use it at your own risk.
Back up your data before making system changes.

## License

[MIT](LICENSE) for the code. The icon is excluded, see above.
