<p align="center">
  <img src="logo.png" alt="Owais Humayun logo - a kangaroo silhouette" width="160"/>
</p>

# Owais Humayun

**Owais Humayun's Windows Utility** — Install Programs, Tweaks, Fixes, and Updates for Windows 10/11. Built to be simple enough for a 10-year-old and clear enough for a 70-year-old, with no computer jargon required.

Inspired by the "one-command Windows toolbox" style popularized by tools like Chris Titus Tech's WinUtil, rebuilt and maintained independently under this project, with its own app catalog, tweak list, and a friendlier, bigger, plain-language interface.

## ⚡ Quick Start

Open **Terminal (Admin)** or **PowerShell (Admin)** and run:

```powershell
irm "https://raw.githubusercontent.com/owaishumayun/owaishumayun/main/owaishumayun.ps1?$(Get-Random)" | iex
```

> The trailing `?$(Get-Random)` isn't a typo - GitHub's raw-file CDN caches each exact URL for a few minutes per edge location, so right after an update some users can briefly fetch a stale copy. Appending a random query string forces every run to bypass the cache and pull the latest file straight from GitHub. Once you've created the repo on GitHub, replace the URL above with your actual raw file link (see **Publishing** below), and update it here too.

## ✨ Features

- **35+ apps across 7 categories** (browsers, chat & video calls, music & video, everyday tools, developer tools, security, gaming) — installed silently via `winget`, Microsoft's official package manager. No hunting for installer links.
- **Friendly, oversized interface** — large 16–19pt fonts, high-contrast colors, tooltips on every option, and a plain-English one-line description under each app and tweak. No technical jargon.
- **Tweaks in plain English** — grouped into "Recommended for Everyone" (safe, reversible) and "Advanced" (clearly separated, colored differently, for people who know what they're doing).
- **Cleanup & Repair tab** — one-click junk cleanup (temp files, prefetch, recycle bin, update leftovers, thumbnail/internet cache, DNS flush) plus separate buttons for heavier repair tools (Disk Cleanup, SFC scan, CHKDSK, startup program list, defrag, component store cleanup) — each with its own plain-English description and a confirmation prompt for anything that needs a restart.
- **Updates tab** — pause Windows Update for 35 days, or restore default behavior, in one click.
- **Restore Point safety net** — automatically creates a System Restore Point before applying any changes, and lets you create one manually at any time.
- **About tab** — explains in plain language exactly what the tool does and doesn't do.

## 🛡️ Safety Notes

- Run tweaks you understand. Advanced tweaks are labeled and colored differently in the UI for a reason — a tooltip on every single item explains what it does before you tick the box.
- App installs go entirely through `winget`, not third-party download links.
- Always review `owaishumayun.ps1` yourself before running it — it's plain PowerShell, fully readable, nothing obfuscated.
- If you pause Windows Update, remember to resume it once you're patched.

## 🧩 Adding Your Own Apps or Tweaks

Open `owaishumayun.ps1` and edit the `$AppCategories` or `$Tweaks` collections near the top of the file — each entry is a simple hashtable with a `Name` and a plain-English `Desc`, no build step required.

```powershell
@{ Name = "Your App"; Id = "Publisher.AppId" }   # find IDs with: winget search <name>
```

## 📦 Requirements

- Windows 10 or 11
- PowerShell 5.1+ (built in)
- Administrator privileges (the script self-elevates checks for this)

## 🤝 Contributing

Pull requests welcome — new tweaks, new apps, bug fixes, or UI improvements.

## 📄 License

MIT — see [LICENSE](LICENSE). Free to use, modify, and redistribute.

## Logo

The mascot is a kangaroo silhouette, included as `logo.png` (ready to use) in this repo. The original source file is kept as `logo-original.avif` for reference.

---

Made by **Owais Humayun**.
