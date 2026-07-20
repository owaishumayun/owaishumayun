# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-file PowerShell + WPF GUI tool ("Owais Humayun") that installs apps, applies Windows tweaks, and cleans up junk on Windows 10/11. Distributed as a one-liner (`irm <raw-url> | iex`) that regular, non-technical users run from an elevated PowerShell/Terminal window — the entire product is `owaishumayun.ps1`, no build step, no package manager, no dependencies beyond what ships with Windows.

Design intent (from README.md): "simple enough for a 10-year-old, clear enough for a 70-year-old" — big fonts, high contrast, plain-English descriptions and tooltips on every option, no jargon. Inspired by Chris Titus Tech's WinUtil but independently built/maintained with its own catalog and UI.

## Running / testing

There is no build system, linter, or test suite — this is a plain, readable `.ps1`. To exercise it:

- Run locally from an elevated PowerShell 5.1+ prompt: `.\owaishumayun.ps1` (it self-checks for STA apartment mode and admin rights; `#Requires -RunAsAdministrator` will block non-elevated sessions).
- The published quick-start path is `irm "https://raw.githubusercontent.com/owaishumayun/owaishumayun/main/owaishumayun.ps1" | iex` — the script re-launches itself via `Start-Process powershell.exe -STA` if it detects it wasn't started in STA mode (WPF requirement), which matters if this invocation path changes.
- No automated tests exist. Verify changes by actually launching the WPF window and checking checkboxes render, tooltips show, and `$AppCheckboxes`/`$TweakCheckboxes`/`$CleanupCheckboxes` keys line up with what's declared.

## Architecture

Everything lives in `owaishumayun.ps1`, top to bottom, in this order:

1. **STA/elevation bootstrap** — re-execs itself in STA mode if needed (required for WPF to load).
2. **`New-SafetyRestorePoint`** — creates a System Restore Point before *any* mutating action; called at the top of both `BtnApply` and `BtnRunCleanup` click handlers. Any new "apply changes" action should call this too.
3. **Data catalogs** (edit these to add apps/tweaks — no code changes needed elsewhere):
   - `$AppCategories` — an `[ordered]@{}` hashtable keyed by category name (e.g. "Web Browsers"), each value an array of `@{ Name; Id; Desc }`. `Id` must be a valid `winget` package ID (find via `winget search <name>`). All installs go through `winget install --id <Id> --source winget --silent --accept-package-agreements --accept-source-agreements` — no third-party download links, by design (see README Safety Notes).
   - `$Tweaks` — flat array of `@{ Name; Tier; Desc; Apply }` where `Tier` is `"Safe"` or `"Advanced"` and `Apply` is a scriptblock (usually a registry `Set-ItemProperty`/`New-Item`, or `powercfg`/`bcdedit`/`ipconfig` call). Safe tweaks are shown first and colored green (`#4ade80`); Advanced are orange (`#fb923c`) and kept visually separate.
   - `$CleanupItems` — flat array of `@{ Name; Desc; Apply }` for one-tick junk removal (temp files, prefetch, recycle bin, WU leftovers, thumbnail/icon/font cache, DNS flush, etc.). Everything here is framed as safe/reversible — Windows regenerates all of it.
4. **XAML UI definition** (`[xml]$Xaml`) — a WPF `Window` loaded via `[Windows.Markup.XamlReader]::Load`, four tabs (Install Apps / Tweaks / Clean-Up / About) inside a `TabControl`, dark theme (`#1e293b` background, `#f97316` orange accent), large fonts (15–28pt) per the accessibility-first design goal. XAML parse failures are caught and dumped as a full exception chain to the console rather than crashing silently — preserve that pattern if touching this block, since `irm | iex` users have no other way to file a useful bug report.
5. **Population logic** — walks the three catalogs above and dynamically builds `CheckBox` controls into `AppsPanel`/`TweaksPanel`/`CleanupPanel` (`StackPanel`s found via `$Window.FindName`), keeping a lookup hashtable (`$AppCheckboxes` keyed by `Id`, `$TweakCheckboxes`/`$CleanupCheckboxes` keyed by `Name`) so button handlers can check `.IsChecked` state.
6. **Button handlers** — `BtnRunCleanup`, `BtnApply` (installs checked apps then applies checked tweaks), `BtnRestorePoint` (labeled "Cancel" in the UI — just closes the window; the name is a holdover, don't be confused by it doing nothing restore-related itself).

### Adding a new app or tweak

No code changes required — add an entry to `$AppCategories` (under an existing or new category key) or `$Tweaks` (with `Tier = "Safe"` or `"Advanced"`) near the top of the file. The UI population loop and checkbox wiring pick it up automatically.

### Known gap between README and script

README.md advertises an "Updates tab" (pause Windows Update 35 days / restore default) and a "Cleanup & Repair" tab with heavier repair tools (Disk Cleanup, SFC, CHKDSK, startup list, defrag, component store cleanup) with restart-confirmation prompts. The current script only implements Install Apps / Tweaks / Clean-Up (junk-removal only, no repair tools) / About — those README features are aspirational and not yet built. Check README claims against the actual `$Xaml` tabs before assuming a feature exists.
