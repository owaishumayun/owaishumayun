if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to close"
    exit
}
<#
    Kangaroo Boost
    Install Programs, Tweaks, and Fixes for Windows 10/11
    Part of Kangaroo Co - Melbourne, Australia
    Built by Owais Humayun
    Simple. Safe. Free.
    License: MIT
    Repo:    https://github.com/owaishumayun/owaishumayun
#>

# ---------------------------------------------------------------------------
#  STA mode relaunch
# ---------------------------------------------------------------------------
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "[KangarooBoost] Restarting in the correct mode, one moment..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-STA", "-Command",
        "irm 'https://raw.githubusercontent.com/owaishumayun/owaishumayun/main/owaishumayun.ps1?$(Get-Random)' | iex"
    )
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

[System.Threading.Thread]::CurrentThread.CurrentCulture   = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::InvariantCulture

# Windows PowerShell 5.1 doesn't always negotiate TLS 1.2 by default, which makes
# WebClient calls to modern HTTPS endpoints (like the speed test) fail outright.
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

$WingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

# ---------------------------------------------------------------------------
#  EMBEDDED ASSET: Owais Humayun logo (JPEG, Base64) - shown on the About page.
#  Embedded rather than loaded from a file path because this script ships as a
#  single file run via irm | iex, with no adjacent assets on the end user's machine.
# ---------------------------------------------------------------------------
$OwaisLogoBase64 = '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'

# ---------------------------------------------------------------------------
#  SAFETY: Restore Point
# ---------------------------------------------------------------------------
function New-SafetyRestorePoint {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        # Windows only allows one restore point every 24h - when that limit is hit, Checkpoint-Computer
        # doesn't throw, it just emits a WARNING and silently skips creation. Catch that warning so the
        # console message we print actually matches what happened, instead of always claiming success.
        $cpWarnings = $null
        Checkpoint-Computer -Description "Kangaroo Boost - Snapshot" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop -WarningAction SilentlyContinue -WarningVariable cpWarnings
        if ($cpWarnings) {
            Write-Host "[KangarooBoost] You already have a restore point from the last 24 hours - Windows won't create another one yet." -ForegroundColor Yellow
            return "existing"
        }
        Write-Host "[KangarooBoost] Restore point created." -ForegroundColor Green
        return "created"
    } catch {
        Write-Host "[KangarooBoost] Could not create a new restore point (Windows only allows one every 24h)." -ForegroundColor Yellow
        return "failed"
    }
}

function Set-Progress {
    param($Bar, $PercentText, [double]$Percent)
    $Bar.Value = $Percent
    $PercentText.Text = "$([math]::Round($Percent))%"
    $Bar.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
}

# ---------------------------------------------------------------------------
#  APP CATALOG
# ---------------------------------------------------------------------------
$AppCategories = [ordered]@{
    "Web Browsers" = @(
        @{ Name = "Google Chrome";      Id = "Google.Chrome";              Desc = "A fast, popular web browser." }
        @{ Name = "Mozilla Firefox";    Id = "Mozilla.Firefox";            Desc = "A privacy-friendly web browser." }
        @{ Name = "Brave Browser";      Id = "Brave.Brave";                Desc = "A browser that blocks ads and trackers automatically." }
        @{ Name = "Microsoft Edge";     Id = "Microsoft.Edge";             Desc = "Microsoft's built-in browser, kept up to date." }
    )
    "Chat and Video Calls" = @(
        @{ Name = "Zoom";               Id = "Zoom.Zoom";                  Desc = "Video calls with family, friends, or work." }
        @{ Name = "WhatsApp";           Id = "WhatsApp.WhatsApp";          Desc = "Chat and video call on your computer." }
    )
    "Music and Video" = @(
        @{ Name = "VLC Media Player";   Id = "VideoLAN.VLC";               Desc = "Plays almost any video or audio file." }
        @{ Name = "Spotify";            Id = "Spotify.Spotify";            Desc = "Stream and listen to music." }
    )
    "Everyday Tools" = @(
        @{ Name = "7-Zip";              Id = "7zip.7zip";                  Desc = "Open zip files and compress your own." }
        @{ Name = "Adobe Acrobat Reader"; Id = "Adobe.Acrobat.Reader.64-bit"; Desc = "Open and read PDF files." }
        @{ Name = "Notepad++";          Id = "Notepad++.Notepad++";        Desc = "A simple, powerful text editor." }
    )
    "Developer Tools" = @(
        @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode"; Desc = "Popular code editor for programmers." }
        @{ Name = "Git";                Id = "Git.Git";                    Desc = "Tool for tracking changes in code projects." }
        @{ Name = "Python";             Id = "Python.Python.3.12";        Desc = "Programming language, great for beginners." }
    )
}

# ---------------------------------------------------------------------------
#  TWEAKS
# ---------------------------------------------------------------------------
$Tweaks = @(
    @{ Name = "Stop Windows from Watching What You Do (Telemetry)"; Tier = "Safe";
       Desc = "Reduces the usage data Windows sends to Microsoft.";
       Apply = { Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Turn Off Bing Results in Search"; Tier = "Safe";
       Desc = "Makes the Start Menu search only look at your own files, not the internet.";
       Apply = { New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Force | Out-Null; Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force } }

    @{ Name = "Always Show File Extensions"; Tier = "Safe";
       Desc = "Shows '.docx', '.jpg' etc. so you always know what kind of file you're opening.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord -Force } }

    @{ Name = "Stop Apps Running in the Background"; Tier = "Safe";
       Desc = "Saves battery and speeds up your PC by stopping apps you're not using.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Remove Annoying 'Tips and Suggestions'"; Tier = "Safe";
       Desc = "Turns off the pop-up tips and ads Windows sometimes shows you.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Make the Mouse Pointer Bigger and Easier to See"; Tier = "Safe";
       Desc = "Great for anyone who finds the normal cursor too small.";
       Apply = { Set-ItemProperty -Path "HKCU:\Control Panel\Cursors" -Name "CursorBaseSize" -Value 48 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Stop Apps Auto-Opening from USB Drives"; Tier = "Safe";
       Desc = "Stops apps from popping up automatically when you plug in a USB drive.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 255 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Speed Up Menus (Reduce Delay)"; Tier = "Safe";
       Desc = "Makes right-click menus pop open instantly instead of with a slight delay.";
       Apply = { Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Restore the Classic Right-Click Menu"; Tier = "Safe";
       Desc = "Brings back the full right-click menu from before Windows 11's simplified version.";
       Apply = {
            New-Item -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -Force
       } }

    @{ Name = "Show Seconds in the Taskbar Clock"; Tier = "Safe";
       Desc = "Adds seconds to the time shown in your taskbar clock.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowSecondsInSystemClock" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Turn Off the Widgets Icon on the Taskbar"; Tier = "Safe";
       Desc = "Removes the Widgets/news feed icon so the taskbar stays clutter-free.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Show Hidden Files and Folders"; Tier = "Safe";
       Desc = "Lets File Explorer show files that are normally hidden from view.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Left-Align Taskbar Icons (Classic Style)"; Tier = "Safe";
       Desc = "Moves taskbar icons back to the left, like older versions of Windows.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Hide the Search Icon on the Taskbar"; Tier = "Advanced";
       Desc = "Removes the search magnifying glass from the taskbar to reduce clutter.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Turn Off Cortana"; Tier = "Advanced";
       Desc = "Fully disables the Cortana voice assistant.";
       Apply = { New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force | Out-Null; Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord -Force } }

    @{ Name = "Disable Hibernation (Free Up Disk Space)"; Tier = "Advanced";
       Desc = "Turns off the hibernate feature and deletes its large hidden system file.";
       Apply = { Start-Process powercfg -ArgumentList "-h off" -Wait -NoNewWindow } }

    @{ Name = "Show Detailed Boot Info (For Troubleshooting)"; Tier = "Advanced";
       Desc = "Shows technical messages while Windows starts up - useful for diagnosing problems.";
       Apply = { bcdedit /set "{current}" bootlog Yes | Out-Null } }

    @{ Name = "Disable Sticky Keys Pop-up"; Tier = "Advanced";
       Desc = "Stops the accessibility pop-up that appears if you press Shift 5 times by accident.";
       Apply = { Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Reduce Game Bar Nag Prompts"; Tier = "Advanced";
       Desc = "Prevents certain pre-installed prompts from nagging you to enable extra features.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Disable Windows Recall"; Tier = "Advanced";
       Desc = "Turns off Recall, the feature that takes periodic screenshots of your activity.";
       Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force
       } }

    @{ Name = "Disable Copilot"; Tier = "Advanced";
       Desc = "Removes the Windows Copilot AI assistant from your taskbar and system.";
       Apply = {
            New-Item -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Force | Out-Null
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
       } }

    @{ Name = "Disable Delivery Optimization (P2P Updates)"; Tier = "Advanced";
       Desc = "Stops Windows from uploading update files to other PCs on the internet.";
       Apply = {
            New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Force | Out-Null
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0 -Type DWord -Force
       } }

    @{ Name = "Disable Advertising ID"; Tier = "Advanced";
       Desc = "Stops apps from using a unique ID to show you personalized ads.";
       Apply = { Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Disable Activity History and Timeline"; Tier = "Advanced";
       Desc = "Stops Windows from tracking and syncing your recent activity across devices.";
       Apply = {
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableActivityFeed" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "PublishUserActivities" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "UploadUserActivities" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
       } }

    @{ Name = "Switch to High Performance Power Plan"; Tier = "Advanced";
       Desc = "Prioritizes speed over battery savings - best for desktops.";
       Apply = { Start-Process powercfg -ArgumentList "/s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -Wait -NoNewWindow } }

    @{ Name = "Reset Network Adapters"; Tier = "Advanced";
       Desc = "Can fix internet connection problems. Briefly disconnects you from the network.";
       Apply = {
            Start-Process ipconfig -ArgumentList "/release" -Wait -NoNewWindow
            Start-Process ipconfig -ArgumentList "/renew" -Wait -NoNewWindow
            Start-Process ipconfig -ArgumentList "/flushdns" -Wait -NoNewWindow
       } }
)

# ---------------------------------------------------------------------------
#  CLEANUP CHECKLIST
# ---------------------------------------------------------------------------
$CleanupItems = @(
    @{ Name = "Personal Temp Files"; Desc = "Deletes leftover temporary files in your user folder.";
       Apply = { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Windows Temp Folder"; Desc = "Deletes temporary files Windows itself created.";
       Apply = { Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Prefetch Files"; Desc = "Safe to delete - Windows quietly rebuilds these to help apps start faster.";
       Apply = { Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Recent Files List"; Desc = "Clears the list of recently opened files shown in File Explorer.";
       Apply = { Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Recycle Bin"; Desc = "Permanently deletes everything currently in the Recycle Bin.";
       Apply = { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Windows Update Leftovers"; Desc = "Frees up a lot of space by deleting old, already-installed update files.";
       Apply = {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
       } }

    @{ Name = "Thumbnail Cache"; Desc = "Clears cached picture previews - Windows regenerates them automatically.";
       Apply = { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Internet Cache"; Desc = "Clears cached web files stored by Windows components.";
       Apply = { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "DNS Cache"; Desc = "Clears stored website addresses - can fix websites failing to load.";
       Apply = { Start-Process ipconfig -ArgumentList "/flushdns" -Wait -NoNewWindow } }

    @{ Name = "Clipboard"; Desc = "Empties whatever text or image is currently copied to your clipboard.";
       Apply = { Set-Clipboard -Value $null -ErrorAction SilentlyContinue } }

    @{ Name = "Jump Lists"; Desc = "Clears the recent-file shortcuts that show when you right-click a taskbar icon.";
       Apply = {
            Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Force -ErrorAction SilentlyContinue
       } }

    @{ Name = "Error Reporting Files"; Desc = "Deletes old crash and error report files Windows has saved.";
       Apply = { Remove-Item -Path "$env:ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Memory Dump Files"; Desc = "Deletes crash-dump files - these can be several GB in size.";
       Apply = {
            Remove-Item -Path "$env:SystemRoot\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:SystemRoot\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
       } }

    @{ Name = "Icon Cache"; Desc = "Fixes broken or wrong-looking icons by rebuilding the icon cache.";
       Apply = {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -Force -ErrorAction SilentlyContinue
            Start-Process explorer
       } }

    @{ Name = "Font Cache"; Desc = "Fixes fonts that look wrong or fail to display properly.";
       Apply = {
            Stop-Service -Name FontCache -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\FontCache*" -Force -ErrorAction SilentlyContinue
            Start-Service -Name FontCache -ErrorAction SilentlyContinue
       } }
)

# ---------------------------------------------------------------------------
#  SYSTEM INFO HELPERS (for Dashboard)
# ---------------------------------------------------------------------------
function Get-DiskInfo {
    try {
        $drive = Get-PSDrive -Name C -ErrorAction SilentlyContinue
        if ($drive) {
            $usedGB  = [math]::Round($drive.Used / 1GB, 1)
            $freeGB  = [math]::Round($drive.Free / 1GB, 1)
            $totalGB = [math]::Round(($drive.Used + $drive.Free) / 1GB, 1)
            $pctUsed = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
            return @{ UsedGB = $usedGB; FreeGB = $freeGB; TotalGB = $totalGB; PctUsed = $pctUsed }
        }
    } catch {}
    return @{ UsedGB = 0; FreeGB = 0; TotalGB = 0; PctUsed = 0 }
}

function Get-MemoryInfo {
    try {
        $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($os) {
            $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
            $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
            $usedGB  = [math]::Round($totalGB - $freeGB, 1)
            $pctUsed = if ($totalGB -gt 0) { [math]::Round(($usedGB / $totalGB) * 100) } else { 0 }
            return @{ UsedGB = $usedGB; FreeGB = $freeGB; TotalGB = $totalGB; PctUsed = $pctUsed }
        }
    } catch {}
    return @{ UsedGB = 0; FreeGB = 0; TotalGB = 0; PctUsed = 0 }
}

function Get-UptimeText {
    try {
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $parts = @()
        if ($uptime.Days -gt 0)    { $parts += "$($uptime.Days)d" }
        if ($uptime.Hours -gt 0)   { $parts += "$($uptime.Hours)h" }
        if ($uptime.Minutes -gt 0) { $parts += "$($uptime.Minutes)m" }
        if ($parts.Count -eq 0) { return "< 1 min" }
        return $parts -join " "
    } catch { return "N/A" }
}

function Get-WindowsVersionText {
    try {
        $build = [System.Environment]::OSVersion.Version.Build
        $name = if ($build -ge 22000) { "Windows 11" } else { "Windows 10" }
        $displayVer = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
        if ($displayVer) { return "$name $displayVer" } else { return "$name (Build $build)" }
    } catch { return "Windows" }
}

function Get-HealthScore {
    $score = 100
    $issues = @()
    $disk = Get-DiskInfo
    if ($disk.PctUsed -gt 90) { $score -= 30; $issues += "Disk almost full ($($disk.PctUsed)% used)" }
    elseif ($disk.PctUsed -gt 75) { $score -= 15; $issues += "Disk space getting low ($($disk.PctUsed)% used)" }
    $mem = Get-MemoryInfo
    if ($mem.PctUsed -gt 90) { $score -= 25; $issues += "Memory usage very high ($($mem.PctUsed)%)" }
    elseif ($mem.PctUsed -gt 75) { $score -= 10; $issues += "Memory usage elevated ($($mem.PctUsed)%)" }
    try {
        $tempCount = @(Get-ChildItem "$env:TEMP" -ErrorAction SilentlyContinue).Count
        if ($tempCount -gt 500) { $score -= 10; $issues += "$tempCount temp files found" }
        elseif ($tempCount -gt 200) { $score -= 5; $issues += "$tempCount temp files found" }
    } catch {}
    try {
        $uptime = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue).LastBootUpTime
        if ($uptime.TotalDays -gt 14) { $score -= 10; $issues += "PC hasn't restarted in $([math]::Floor($uptime.TotalDays)) days" }
    } catch {}
    if ($score -lt 0) { $score = 0 }
    if ($issues.Count -eq 0) { $issues += "No issues detected" }
    return @{ Score = $score; Issues = $issues }
}

# ---------------------------------------------------------------------------
#  SPEED TEST HELPERS
#  Download and upload speed use Cloudflare's public speed-test endpoints
#  (the same ones speed.cloudflare.com uses in the browser) - no account,
#  no SDK, and openly documented as a public test service, unlike Ookla's
#  speedtest.net which restricts automated use to their own licensed tools.
# ---------------------------------------------------------------------------
function Test-InternetLatency {
    try {
        $pings = Test-Connection -ComputerName "1.1.1.1" -Count 4 -ErrorAction Stop
        $avg = [math]::Round(($pings | Measure-Object -Property ResponseTime -Average).Average)
        return $avg
    } catch {
        return $null
    }
}

function Test-InternetDownloadSpeed {
    $bytes = 25000000
    $url = "https://speed.cloudflare.com/__down?bytes=$bytes"
    try {
        $wc = New-Object System.Net.WebClient
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $data = $wc.DownloadData($url)
        $sw.Stop()
        $seconds = [math]::Max($sw.Elapsed.TotalSeconds, 0.01)
        $mbps = [math]::Round((($data.Length * 8) / $seconds) / 1MB, 1)
        return @{ Success = $true; Mbps = $mbps }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Test-InternetUploadSpeed {
    $bytes = 10000000
    $url = "https://speed.cloudflare.com/__up"
    try {
        $payload = New-Object byte[] $bytes
        (New-Object System.Random).NextBytes($payload)
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("Content-Type", "application/octet-stream")
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $wc.UploadData($url, "POST", $payload) | Out-Null
        $sw.Stop()
        $seconds = [math]::Max($sw.Elapsed.TotalSeconds, 0.01)
        $mbps = [math]::Round((($payload.Length * 8) / $seconds) / 1MB, 1)
        return @{ Success = $true; Mbps = $mbps }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# ---------------------------------------------------------------------------
#  WPF LAYOUT - Professional sidebar, dashboard, dark theme
# ---------------------------------------------------------------------------
[xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Kangaroo Boost - PC Optimizer"
        Height="820" Width="1100" MinHeight="650" MinWidth="900"
        WindowStartupLocation="CenterScreen"
        Background="#0b1120" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="14"
        TextOptions.TextFormattingMode="Display" UseLayoutRounding="True" SnapsToDevicePixels="True"
        WindowStyle="None" AllowsTransparency="True" ResizeMode="CanResizeWithGrip">

    <Window.Resources>
        <SolidColorBrush x:Key="AccentBrush"      Color="#3b82f6"/>
        <SolidColorBrush x:Key="AccentHoverBrush"  Color="#60a5fa"/>
        <SolidColorBrush x:Key="AccentDimBrush"    Color="#1e3a5f"/>
        <SolidColorBrush x:Key="GreenBrush"        Color="#22c55e"/>
        <SolidColorBrush x:Key="GreenDimBrush"     Color="#15803d"/>
        <SolidColorBrush x:Key="OrangeBrush"       Color="#f97316"/>
        <SolidColorBrush x:Key="RedBrush"          Color="#ef4444"/>
        <SolidColorBrush x:Key="SidebarBg"         Color="#070d1a"/>
        <SolidColorBrush x:Key="ContentBg"         Color="#0b1120"/>
        <SolidColorBrush x:Key="CardBg"            Color="#111b2e"/>
        <SolidColorBrush x:Key="CardBorder"        Color="#1c2d47"/>
        <SolidColorBrush x:Key="TextPrimary"       Color="#f1f5f9"/>
        <SolidColorBrush x:Key="TextSecondary"     Color="#94a3b8"/>
        <SolidColorBrush x:Key="TextMuted"         Color="#64748b"/>
        <SolidColorBrush x:Key="NavHoverBg"        Color="#111b2e"/>
        <SolidColorBrush x:Key="NavActiveBg"       Color="#0f1d36"/>

        <!-- Fluent-style gradients & depth effects -->
        <LinearGradientBrush x:Key="AccentGradientBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#60a5fa" Offset="0"/>
            <GradientStop Color="#2563eb" Offset="1"/>
        </LinearGradientBrush>
        <LinearGradientBrush x:Key="AccentGradientHoverBrush" StartPoint="0,0" EndPoint="1,1">
            <GradientStop Color="#93c5fd" Offset="0"/>
            <GradientStop Color="#3b82f6" Offset="1"/>
        </LinearGradientBrush>
        <LinearGradientBrush x:Key="SidebarGradientBrush" StartPoint="0,0" EndPoint="0,1">
            <GradientStop Color="#0a1224" Offset="0"/>
            <GradientStop Color="#05080f" Offset="1"/>
        </LinearGradientBrush>
        <DropShadowEffect x:Key="CardShadowEffect" Color="#000000" BlurRadius="18" ShadowDepth="4" Direction="270" Opacity="0.32"/>
        <DropShadowEffect x:Key="GlowSoftBlue" Color="#3b82f6" BlurRadius="10" ShadowDepth="0" Opacity="0.55"/>

        <!-- Card Style -->
        <Style x:Key="CardStyle" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource CardBg}"/>
            <Setter Property="BorderBrush" Value="{StaticResource CardBorder}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="18"/>
            <Setter Property="Effect" Value="{StaticResource CardShadowEffect}"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <!-- Checkbox -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextPrimary}"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="6,6,6,6"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="RowBorder" Background="Transparent" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <StackPanel Orientation="Horizontal">
                                <Border x:Name="Box" Width="18" Height="18" CornerRadius="5"
                                        BorderBrush="#475569" BorderThickness="1.5" Background="#0b1120" VerticalAlignment="Center"
                                        RenderTransformOrigin="0.5,0.5">
                                    <Border.RenderTransform>
                                        <ScaleTransform x:Name="BoxScale" ScaleX="1" ScaleY="1"/>
                                    </Border.RenderTransform>
                                    <Path x:Name="CheckMark" Data="M3,7 L7,11 L14,3" Stroke="White" StrokeThickness="2"
                                          StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"
                                          Visibility="Collapsed" Margin="0,1,0,0"/>
                                </Border>
                                <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Box" Property="Background" Value="{StaticResource AccentGradientBrush}"/>
                                <Setter TargetName="Box" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="Box" Property="Effect" Value="{StaticResource GlowSoftBlue}"/>
                                <Setter TargetName="CheckMark" Property="Visibility" Value="Visible"/>
                                <Trigger.EnterActions>
                                    <BeginStoryboard>
                                        <Storyboard>
                                            <DoubleAnimationUsingKeyFrames Storyboard.TargetName="BoxScale" Storyboard.TargetProperty="ScaleX">
                                                <EasingDoubleKeyFrame KeyTime="0" Value="1"/>
                                                <EasingDoubleKeyFrame KeyTime="0:0:0.08" Value="1.25"/>
                                                <EasingDoubleKeyFrame KeyTime="0:0:0.18" Value="1"/>
                                            </DoubleAnimationUsingKeyFrames>
                                            <DoubleAnimationUsingKeyFrames Storyboard.TargetName="BoxScale" Storyboard.TargetProperty="ScaleY">
                                                <EasingDoubleKeyFrame KeyTime="0" Value="1"/>
                                                <EasingDoubleKeyFrame KeyTime="0:0:0.08" Value="1.25"/>
                                                <EasingDoubleKeyFrame KeyTime="0:0:0.18" Value="1"/>
                                            </DoubleAnimationUsingKeyFrames>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.EnterActions>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="RowBorder" Property="Background" Value="#15223a"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Primary Button -->
        <Style x:Key="PrimaryButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentGradientBrush}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="20,11"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}" CornerRadius="8"
                                RenderTransformOrigin="0.5,0.5">
                            <Border.RenderTransform>
                                <ScaleTransform x:Name="BgScale" ScaleX="1" ScaleY="1"/>
                            </Border.RenderTransform>
                            <Border.Effect>
                                <DropShadowEffect x:Name="BgGlow" Color="#3b82f6" BlurRadius="12" ShadowDepth="0" Opacity="0.3"/>
                            </Border.Effect>
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                               Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="{StaticResource AccentGradientHoverBrush}"/>
                                <Trigger.EnterActions>
                                    <BeginStoryboard>
                                        <Storyboard>
                                            <DoubleAnimation Storyboard.TargetName="BgGlow" Storyboard.TargetProperty="Opacity" To="0.65" Duration="0:0:0.15"/>
                                            <DoubleAnimation Storyboard.TargetName="BgGlow" Storyboard.TargetProperty="BlurRadius" To="20" Duration="0:0:0.15"/>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.EnterActions>
                                <Trigger.ExitActions>
                                    <BeginStoryboard>
                                        <Storyboard>
                                            <DoubleAnimation Storyboard.TargetName="BgGlow" Storyboard.TargetProperty="Opacity" To="0.3" Duration="0:0:0.15"/>
                                            <DoubleAnimation Storyboard.TargetName="BgGlow" Storyboard.TargetProperty="BlurRadius" To="12" Duration="0:0:0.15"/>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.ExitActions>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bg" Property="Opacity" Value="0.9"/>
                                <Trigger.EnterActions>
                                    <BeginStoryboard Name="PressStoryboard">
                                        <Storyboard>
                                            <DoubleAnimation Storyboard.TargetName="BgScale" Storyboard.TargetProperty="ScaleX" To="0.97" Duration="0:0:0.05"/>
                                            <DoubleAnimation Storyboard.TargetName="BgScale" Storyboard.TargetProperty="ScaleY" To="0.97" Duration="0:0:0.05"/>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.EnterActions>
                                <Trigger.ExitActions>
                                    <StopStoryboard BeginStoryboardName="PressStoryboard"/>
                                    <BeginStoryboard>
                                        <Storyboard>
                                            <DoubleAnimation Storyboard.TargetName="BgScale" Storyboard.TargetProperty="ScaleX" To="1" Duration="0:0:0.08"/>
                                            <DoubleAnimation Storyboard.TargetName="BgScale" Storyboard.TargetProperty="ScaleY" To="1" Duration="0:0:0.08"/>
                                        </Storyboard>
                                    </BeginStoryboard>
                                </Trigger.ExitActions>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bg" Property="Background" Value="#334155"/>
                                <Setter TargetName="Bg" Property="Effect" Value="{x:Null}"/>
                                <Setter Property="Foreground" Value="#64748b"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="Button" BasedOn="{StaticResource PrimaryButtonStyle}"/>

        <!-- Ghost Button -->
        <Style x:Key="GhostButtonStyle" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource AccentBrush}"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="8,4"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="#15223a"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary Button -->
        <Style x:Key="SecondaryButtonStyle" TargetType="Button" BasedOn="{StaticResource PrimaryButtonStyle}">
            <Setter Property="Background" Value="#1c2d47"/>
        </Style>

        <!-- Progress Bar -->
        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="22"/>
            <Setter Property="Minimum" Value="0"/>
            <Setter Property="Maximum" Value="100"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Grid>
                            <Border CornerRadius="11" Background="#111b2e" BorderBrush="#1c2d47" BorderThickness="1"/>
                            <Border CornerRadius="10" Margin="2" ClipToBounds="True">
                                <Grid HorizontalAlignment="Left">
                                    <Rectangle x:Name="PART_Indicator" Fill="{StaticResource AccentGradientBrush}"
                                               HorizontalAlignment="Left" RadiusX="9" RadiusY="9"/>
                                </Grid>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Scrollbars -->
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="8"/>
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ScrollBar">
                        <Grid Background="Transparent">
                            <Track Name="PART_Track" IsDirectionReversed="True">
                                <Track.DecreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageUpCommand" Opacity="0"/>
                                </Track.DecreaseRepeatButton>
                                <Track.IncreaseRepeatButton>
                                    <RepeatButton Command="ScrollBar.PageDownCommand" Opacity="0"/>
                                </Track.IncreaseRepeatButton>
                                <Track.Thumb>
                                    <Thumb>
                                        <Thumb.Template>
                                            <ControlTemplate TargetType="Thumb">
                                                <Border CornerRadius="4" Background="#334155" Width="6"/>
                                            </ControlTemplate>
                                        </Thumb.Template>
                                    </Thumb>
                                </Track.Thumb>
                            </Track>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Border CornerRadius="12" Background="#0b1120" BorderBrush="#1c2d47" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- Title Bar / Drag Area - spans the full window so the window controls sit top-right -->
            <Border Grid.Row="0" Name="TitleBar" Background="Transparent" Height="38" Cursor="Hand">
                <Grid>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,6,10,0">
                        <Button Name="BtnMinimize" Width="28" Height="28" Background="Transparent" Foreground="#64748b"
                                FontFamily="Segoe MDL2 Assets" Content="&#xE921;" FontSize="10" Padding="0"
                                ToolTip="Minimize"/>
                        <Button Name="BtnMaximize" Width="28" Height="28" Background="Transparent" Foreground="#64748b"
                                FontFamily="Segoe MDL2 Assets" Content="&#xE922;" FontSize="10" Padding="0" Margin="2,0,0,0"
                                ToolTip="Maximize"/>
                        <Button Name="BtnCloseWindow" Width="28" Height="28" Background="Transparent" Foreground="#64748b"
                                FontFamily="Segoe MDL2 Assets" Content="&#xE8BB;" FontSize="10" Padding="0" Margin="2,0,0,0"
                                ToolTip="Close"/>
                    </StackPanel>
                </Grid>
            </Border>

            <Grid Grid.Row="1">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="230"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- ============ LEFT SIDEBAR ============ -->
            <Border Grid.Column="0" Background="{StaticResource SidebarGradientBrush}" CornerRadius="0,0,0,12">
                <Grid>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>

                    <!-- Logo -->
                    <StackPanel Grid.Row="0" Margin="20,16,20,24">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Border Grid.Column="0" Width="42" Height="42" CornerRadius="10" Effect="{StaticResource GlowSoftBlue}">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="#60a5fa" Offset="0"/>
                                        <GradientStop Color="#3b82f6" Offset="0.5"/>
                                        <GradientStop Color="#1d4ed8" Offset="1"/>
                                    </LinearGradientBrush>
                                </Border.Background>
                                <TextBlock Text="KB" FontSize="16" FontWeight="Bold" Foreground="White"
                                           HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                            <StackPanel Grid.Column="1" Margin="12,0,0,0" VerticalAlignment="Center">
                                <TextBlock Text="Kangaroo Boost" FontSize="15" FontWeight="Bold" Foreground="White"/>
                                <TextBlock Text="by Kangaroo Co" FontSize="11" Foreground="#64748b" Margin="0,-1,0,0"/>
                            </StackPanel>
                        </Grid>
                    </StackPanel>

                    <!-- Navigation -->
                    <StackPanel Grid.Row="1" Margin="10,0,10,0">
                        <!-- Dashboard -->
                        <Border Name="NavDashboard" Background="#0f1d36" CornerRadius="8" Margin="0,1" Cursor="Hand">
                            <Grid Margin="14,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Width="3" HorizontalAlignment="Left" Margin="-14,0,0,0"
                                        CornerRadius="0,2,2,0" Name="NavDashboardBar" Effect="{StaticResource GlowSoftBlue}">
                                    <Border.Background>
                                        <SolidColorBrush Color="#3b82f6"/>
                                    </Border.Background>
                                </Border>
                                <TextBlock Grid.Column="0" Text="&#xE80F;" FontFamily="Segoe MDL2 Assets" FontSize="16"
                                           Foreground="#3b82f6" VerticalAlignment="Center"/>
                                <TextBlock Grid.Column="1" Text="Dashboard" Foreground="White" FontWeight="SemiBold"
                                           FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center"/>
                            </Grid>
                        </Border>
                        <!-- Install Apps -->
                        <Border Name="NavInstall" Background="Transparent" CornerRadius="8" Margin="0,1" Cursor="Hand">
                            <Grid Margin="14,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Width="3" HorizontalAlignment="Left" Margin="-14,0,0,0"
                                        CornerRadius="0,2,2,0" Name="NavInstallBar" Background="Transparent" Effect="{StaticResource GlowSoftBlue}"/>
                                <TextBlock Grid.Column="0" Text="&#xE896;" FontFamily="Segoe MDL2 Assets" FontSize="16"
                                           Foreground="#64748b" VerticalAlignment="Center" Name="NavInstallIcon"/>
                                <TextBlock Grid.Column="1" Text="Install Apps" Foreground="#94a3b8"
                                           FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center" Name="NavInstallText"/>
                            </Grid>
                        </Border>
                        <!-- Tweaks -->
                        <Border Name="NavTweaks" Background="Transparent" CornerRadius="8" Margin="0,1" Cursor="Hand">
                            <Grid Margin="14,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Width="3" HorizontalAlignment="Left" Margin="-14,0,0,0"
                                        CornerRadius="0,2,2,0" Name="NavTweaksBar" Background="Transparent" Effect="{StaticResource GlowSoftBlue}"/>
                                <TextBlock Grid.Column="0" Text="&#xE713;" FontFamily="Segoe MDL2 Assets" FontSize="16"
                                           Foreground="#64748b" VerticalAlignment="Center" Name="NavTweaksIcon"/>
                                <TextBlock Grid.Column="1" Text="Tweaks" Foreground="#94a3b8"
                                           FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center" Name="NavTweaksText"/>
                            </Grid>
                        </Border>
                        <!-- Clean-Up -->
                        <Border Name="NavCleanup" Background="Transparent" CornerRadius="8" Margin="0,1" Cursor="Hand">
                            <Grid Margin="14,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Width="3" HorizontalAlignment="Left" Margin="-14,0,0,0"
                                        CornerRadius="0,2,2,0" Name="NavCleanupBar" Background="Transparent" Effect="{StaticResource GlowSoftBlue}"/>
                                <TextBlock Grid.Column="0" Text="&#xE74D;" FontFamily="Segoe MDL2 Assets" FontSize="16"
                                           Foreground="#64748b" VerticalAlignment="Center" Name="NavCleanupIcon"/>
                                <TextBlock Grid.Column="1" Text="Clean-Up" Foreground="#94a3b8"
                                           FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center" Name="NavCleanupText"/>
                            </Grid>
                        </Border>
                        <!-- Speed Test -->
                        <Border Name="NavSpeedTest" Background="Transparent" CornerRadius="8" Margin="0,1" Cursor="Hand">
                            <Grid Margin="14,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Width="3" HorizontalAlignment="Left" Margin="-14,0,0,0"
                                        CornerRadius="0,2,2,0" Name="NavSpeedTestBar" Background="Transparent" Effect="{StaticResource GlowSoftBlue}"/>
                                <TextBlock Grid.Column="0" Text="&#xE774;" FontFamily="Segoe MDL2 Assets" FontSize="16"
                                           Foreground="#64748b" VerticalAlignment="Center" Name="NavSpeedTestIcon"/>
                                <TextBlock Grid.Column="1" Text="Speed Test" Foreground="#94a3b8"
                                           FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center" Name="NavSpeedTestText"/>
                            </Grid>
                        </Border>

                        <!-- Separator -->
                        <Border Height="1" Background="#1c2d47" Margin="6,12,6,12"/>

                        <!-- About -->
                        <Border Name="NavAbout" Background="Transparent" CornerRadius="8" Margin="0,1" Cursor="Hand">
                            <Grid Margin="14,10">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Border Grid.Column="0" Width="3" HorizontalAlignment="Left" Margin="-14,0,0,0"
                                        CornerRadius="0,2,2,0" Name="NavAboutBar" Background="Transparent" Effect="{StaticResource GlowSoftBlue}"/>
                                <TextBlock Grid.Column="0" Text="&#xE946;" FontFamily="Segoe MDL2 Assets" FontSize="16"
                                           Foreground="#64748b" VerticalAlignment="Center" Name="NavAboutIcon"/>
                                <TextBlock Grid.Column="1" Text="About" Foreground="#94a3b8"
                                           FontSize="14" Margin="12,0,0,0" VerticalAlignment="Center" Name="NavAboutText"/>
                            </Grid>
                        </Border>
                    </StackPanel>

                    <!-- Bottom Version -->
                    <StackPanel Grid.Row="2" Margin="20,0,20,16">
                        <Border Height="1" Background="#1c2d47" Margin="0,0,0,12"/>
                        <TextBlock Text="Simple. Safe. Free." Foreground="#475569" FontSize="11" HorizontalAlignment="Center"/>
                        <TextBlock Text="Kangaroo Co - v1.0" Foreground="#334155" FontSize="10" HorizontalAlignment="Center" Margin="0,2,0,0"/>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- ============ MAIN CONTENT ============ -->
            <Grid Grid.Column="1" Margin="24,16,24,20">

                <!-- ===== PAGE: DASHBOARD ===== -->
                <Grid Name="PageDashboard">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>

                    <!-- Header -->
                    <StackPanel Grid.Row="0" Margin="0,20,0,20">
                        <TextBlock Text="System Health" FontSize="26" FontWeight="Bold" Foreground="White"/>
                        <TextBlock Name="TxtWinVersion" Text="Windows" Foreground="#64748b" FontSize="13" Margin="0,2,0,0"/>
                    </StackPanel>

                    <!-- Gauge Row -->
                    <Border Grid.Row="1" Style="{StaticResource CardStyle}" Margin="0,0,0,16" Padding="24">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="Auto"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <!-- Gauge Canvas -->
                            <Canvas Grid.Column="0" Name="GaugeCanvas" Width="200" Height="120" Margin="10,0,30,0"/>
                            <!-- Issues List -->
                            <StackPanel Grid.Column="1" VerticalAlignment="Center">
                                <TextBlock Text="System Status" FontSize="16" FontWeight="SemiBold" Foreground="White" Margin="0,0,0,6"/>
                                <TextBlock Name="TxtScanSummary" Text="Not scanned yet" FontSize="14" FontWeight="SemiBold" Foreground="#94a3b8" Margin="0,0,0,10" TextWrapping="Wrap"/>
                                <StackPanel Name="IssuesPanel"/>
                                <Button Name="BtnScanNow" Content="Scan Now" Style="{StaticResource SecondaryButtonStyle}"
                                        HorizontalAlignment="Left" Margin="0,4,0,0" Padding="16,8"/>
                            </StackPanel>
                        </Grid>
                    </Border>

                    <!-- Stat Cards Row -->
                    <Grid Grid.Row="2" Margin="0,0,0,16">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="12"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="12"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="12"/>
                            <ColumnDefinition Width="*"/>
                        </Grid.ColumnDefinitions>

                        <!-- Disk Space -->
                        <Border Grid.Column="0" Style="{StaticResource CardStyle}">
                            <StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                    <TextBlock Text="&#xEDA2;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#3b82f6" VerticalAlignment="Center"/>
                                    <TextBlock Text="Disk Space" Foreground="#94a3b8" FontSize="12" Margin="8,0,0,0" VerticalAlignment="Center"/>
                                </StackPanel>
                                <TextBlock Name="TxtDiskValue" Text="--" FontSize="22" FontWeight="Bold" Foreground="White"/>
                                <TextBlock Name="TxtDiskSub" Text="free of -- GB" Foreground="#64748b" FontSize="11" Margin="0,2,0,6"/>
                                <Border Height="4" CornerRadius="2" Background="#1c2d47">
                                    <Border Name="DiskBar" Height="4" CornerRadius="2" Background="#3b82f6" HorizontalAlignment="Left" Width="0"/>
                                </Border>
                            </StackPanel>
                        </Border>

                        <!-- Memory -->
                        <Border Grid.Column="2" Style="{StaticResource CardStyle}">
                            <StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                    <TextBlock Text="&#xE7F4;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#a855f7" VerticalAlignment="Center"/>
                                    <TextBlock Text="Memory" Foreground="#94a3b8" FontSize="12" Margin="8,0,0,0" VerticalAlignment="Center"/>
                                </StackPanel>
                                <TextBlock Name="TxtMemValue" Text="--" FontSize="22" FontWeight="Bold" Foreground="White"/>
                                <TextBlock Name="TxtMemSub" Text="used of -- GB" Foreground="#64748b" FontSize="11" Margin="0,2,0,6"/>
                                <Border Height="4" CornerRadius="2" Background="#1c2d47">
                                    <Border Name="MemBar" Height="4" CornerRadius="2" Background="#a855f7" HorizontalAlignment="Left" Width="0"/>
                                </Border>
                            </StackPanel>
                        </Border>

                        <!-- Uptime -->
                        <Border Grid.Column="4" Style="{StaticResource CardStyle}">
                            <StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                    <TextBlock Text="&#xE823;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#22c55e" VerticalAlignment="Center"/>
                                    <TextBlock Text="Uptime" Foreground="#94a3b8" FontSize="12" Margin="8,0,0,0" VerticalAlignment="Center"/>
                                </StackPanel>
                                <TextBlock Name="TxtUptime" Text="--" FontSize="22" FontWeight="Bold" Foreground="White"/>
                                <TextBlock Text="since last restart" Foreground="#64748b" FontSize="11" Margin="0,2,0,0"/>
                            </StackPanel>
                        </Border>

                        <!-- Protection -->
                        <Border Grid.Column="6" Style="{StaticResource CardStyle}">
                            <StackPanel>
                                <StackPanel Orientation="Horizontal" Margin="0,0,0,6">
                                    <TextBlock Text="&#xE72E;" FontFamily="Segoe MDL2 Assets" FontSize="14" Foreground="#f59e0b" VerticalAlignment="Center"/>
                                    <TextBlock Text="Restore Point" Foreground="#94a3b8" FontSize="12" Margin="8,0,0,0" VerticalAlignment="Center"/>
                                </StackPanel>
                                <TextBlock Name="TxtProtection" Text="Ready" FontSize="22" FontWeight="Bold" Foreground="White"/>
                                <TextBlock Text="safety net active" Foreground="#64748b" FontSize="11" Margin="0,2,0,0"/>
                            </StackPanel>
                        </Border>
                    </Grid>

                    <!-- Quick Actions -->
                    <Border Grid.Row="3" Style="{StaticResource CardStyle}" VerticalAlignment="Top">
                        <Grid>
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="*"/>
                            </Grid.ColumnDefinitions>
                            <Button Grid.Column="0" Name="BtnQuickInstall" Content="Install Apps" Margin="0,0,6,0"
                                    Style="{StaticResource SecondaryButtonStyle}" Padding="0,14"/>
                            <Button Grid.Column="1" Name="BtnQuickTweaks" Content="Apply Tweaks" Margin="6,0,6,0"
                                    Style="{StaticResource SecondaryButtonStyle}" Padding="0,14"/>
                            <Button Grid.Column="2" Name="BtnQuickCleanup" Content="Run Clean-Up" Margin="6,0,6,0"
                                    Style="{StaticResource SecondaryButtonStyle}" Padding="0,14"/>
                            <Button Grid.Column="3" Name="BtnQuickSpeedTest" Content="Speed Test" Margin="6,0,0,0"
                                    Style="{StaticResource SecondaryButtonStyle}" Padding="0,14"/>
                        </Grid>
                    </Border>
                </Grid>

                <!-- ===== PAGE: INSTALL APPS ===== -->
                <Grid Name="PageInstall" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid Grid.Row="0" Margin="0,20,0,14">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <TextBlock Text="Install Apps" FontSize="26" FontWeight="Bold" Foreground="White"/>
                            <TextBlock Text="Select apps to install via winget (Microsoft's official installer)."
                                       Foreground="#64748b" FontSize="13" Margin="0,2,0,0"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Bottom">
                            <TextBlock Name="TxtAppsSelectedCount" Text="0 selected" Foreground="#64748b" FontSize="12"
                                       VerticalAlignment="Center" Margin="0,0,12,0"/>
                            <Button Name="BtnAppsSelectAll" Content="Select All" Style="{StaticResource GhostButtonStyle}"/>
                            <Button Name="BtnAppsClearAll" Content="Clear All" Style="{StaticResource GhostButtonStyle}" Margin="4,0,0,0"/>
                        </StackPanel>
                    </Grid>
                    <Border Grid.Row="1" Style="{StaticResource CardStyle}" Padding="8">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="AppsPanel" Margin="6"/>
                        </ScrollViewer>
                    </Border>
                    <Grid Grid.Row="2" Margin="0,12,0,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Button Grid.Column="0" Name="BtnInstallApps" Content="Install Selected Apps"/>
                        <Grid Grid.Column="1" Margin="14,0,14,0" VerticalAlignment="Center">
                            <ProgressBar Name="PbApps"/>
                            <TextBlock Name="TxtAppsPercent" Text="0%" Foreground="White" FontWeight="Bold" FontSize="11"
                                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Grid>
                        <TextBlock Grid.Column="2" Name="TxtAppsStatus" Text="Tick apps, then click Install."
                                   Foreground="#64748b" FontSize="12" VerticalAlignment="Center" MaxWidth="260" TextWrapping="Wrap"/>
                    </Grid>
                </Grid>

                <!-- ===== PAGE: TWEAKS ===== -->
                <Grid Name="PageTweaks" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid Grid.Row="0" Margin="0,20,0,14">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <TextBlock Text="Tweaks" FontSize="26" FontWeight="Bold" Foreground="White"/>
                            <TextBlock Text="Optimize your Windows settings for better performance and privacy."
                                       Foreground="#64748b" FontSize="13" Margin="0,2,0,0"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Bottom">
                            <TextBlock Name="TxtTweaksSelectedCount" Text="0 selected" Foreground="#64748b" FontSize="12"
                                       VerticalAlignment="Center" Margin="0,0,12,0"/>
                            <Button Name="BtnTweaksSelectAll" Content="Select All" Style="{StaticResource GhostButtonStyle}"/>
                            <Button Name="BtnTweaksClearAll" Content="Clear All" Style="{StaticResource GhostButtonStyle}" Margin="4,0,0,0"/>
                        </StackPanel>
                    </Grid>
                    <Border Grid.Row="1" Style="{StaticResource CardStyle}" Padding="8">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="TweaksPanel" Margin="6"/>
                        </ScrollViewer>
                    </Border>
                    <Grid Grid.Row="2" Margin="0,12,0,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Button Grid.Column="0" Name="BtnApplyTweaks" Content="Apply Selected Tweaks"/>
                        <Grid Grid.Column="1" Margin="14,0,14,0" VerticalAlignment="Center">
                            <ProgressBar Name="PbTweaks"/>
                            <TextBlock Name="TxtTweaksPercent" Text="0%" Foreground="White" FontWeight="Bold" FontSize="11"
                                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Grid>
                        <TextBlock Grid.Column="2" Name="TxtTweaksStatus" Text="Tick tweaks, then click Apply."
                                   Foreground="#64748b" FontSize="12" VerticalAlignment="Center" MaxWidth="260" TextWrapping="Wrap"/>
                    </Grid>
                </Grid>

                <!-- ===== PAGE: CLEAN-UP ===== -->
                <Grid Name="PageCleanup" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid Grid.Row="0" Margin="0,20,0,14">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <StackPanel Grid.Column="0">
                            <TextBlock Text="Clean-Up" FontSize="26" FontWeight="Bold" Foreground="White"/>
                            <TextBlock Text="Remove junk files and free up disk space safely."
                                       Foreground="#64748b" FontSize="13" Margin="0,2,0,0"/>
                        </StackPanel>
                        <StackPanel Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Bottom">
                            <TextBlock Name="TxtCleanupSelectedCount" Text="0 selected" Foreground="#64748b" FontSize="12"
                                       VerticalAlignment="Center" Margin="0,0,12,0"/>
                            <Button Name="BtnCleanupSelectAll" Content="Select All" Style="{StaticResource GhostButtonStyle}"/>
                            <Button Name="BtnCleanupClearAll" Content="Clear All" Style="{StaticResource GhostButtonStyle}" Margin="4,0,0,0"/>
                        </StackPanel>
                    </Grid>
                    <Border Grid.Row="1" Style="{StaticResource CardStyle}" Padding="8">
                        <ScrollViewer VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="CleanupPanel" Margin="6"/>
                        </ScrollViewer>
                    </Border>
                    <Grid Grid.Row="2" Margin="0,12,0,0">
                        <Grid.ColumnDefinitions>
                            <ColumnDefinition Width="Auto"/>
                            <ColumnDefinition Width="*"/>
                            <ColumnDefinition Width="Auto"/>
                        </Grid.ColumnDefinitions>
                        <Button Grid.Column="0" Name="BtnRunCleanup" Content="Run Cleanup"/>
                        <Grid Grid.Column="1" Margin="14,0,14,0" VerticalAlignment="Center">
                            <ProgressBar Name="PbCleanup"/>
                            <TextBlock Name="TxtCleanupPercent" Text="0%" Foreground="White" FontWeight="Bold" FontSize="11"
                                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Grid>
                        <TextBlock Grid.Column="2" Name="TxtCleanupStatus" Text="Tick items, then click Run Cleanup."
                                   Foreground="#64748b" FontSize="12" VerticalAlignment="Center" MaxWidth="260" TextWrapping="Wrap"/>
                    </Grid>
                </Grid>

                <!-- ===== PAGE: SPEED TEST ===== -->
                <Grid Name="PageSpeedTest" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Row="0" Margin="0,20,0,14">
                        <TextBlock Text="Speed Test" FontSize="26" FontWeight="Bold" Foreground="White"/>
                        <TextBlock Text="Check your internet download speed, upload speed, and latency." Foreground="#64748b" FontSize="13" Margin="0,2,0,0"/>
                    </StackPanel>
                    <Border Grid.Row="1" Style="{StaticResource CardStyle}" Padding="28" VerticalAlignment="Top">
                        <StackPanel HorizontalAlignment="Center">
                            <Grid Margin="0,0,0,20">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="140"/>
                                    <ColumnDefinition Width="140"/>
                                    <ColumnDefinition Width="140"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" HorizontalAlignment="Center">
                                    <TextBlock Text="Download" Foreground="#94a3b8" FontSize="13" HorizontalAlignment="Center"/>
                                    <TextBlock Name="TxtDownloadSpeed" Text="--" FontSize="30" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                                    <TextBlock Text="Mbps" Foreground="#64748b" FontSize="12" HorizontalAlignment="Center"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" HorizontalAlignment="Center">
                                    <TextBlock Text="Upload" Foreground="#94a3b8" FontSize="13" HorizontalAlignment="Center"/>
                                    <TextBlock Name="TxtUploadSpeed" Text="--" FontSize="30" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                                    <TextBlock Text="Mbps" Foreground="#64748b" FontSize="12" HorizontalAlignment="Center"/>
                                </StackPanel>
                                <StackPanel Grid.Column="2" HorizontalAlignment="Center">
                                    <TextBlock Text="Ping" Foreground="#94a3b8" FontSize="13" HorizontalAlignment="Center"/>
                                    <TextBlock Name="TxtPingResult" Text="--" FontSize="30" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                                    <TextBlock Text="ms" Foreground="#64748b" FontSize="12" HorizontalAlignment="Center"/>
                                </StackPanel>
                            </Grid>
                            <Button Name="BtnRunSpeedTest" Content="Run Speed Test" Padding="30,12" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtSpeedTestStatus" Text="Tests your connection using a public speed-test service. Nothing is downloaded or kept - the data is only used to time the connection."
                                       Foreground="#64748b" FontSize="12" Margin="0,14,0,0" TextWrapping="Wrap" TextAlignment="Center" Width="340"/>
                        </StackPanel>
                    </Border>
                </Grid>

                <!-- ===== PAGE: ABOUT ===== -->
                <Grid Name="PageAbout" Visibility="Collapsed">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="*"/>
                    </Grid.RowDefinitions>
                    <StackPanel Grid.Row="0" Margin="0,20,0,14">
                        <TextBlock Text="About" FontSize="26" FontWeight="Bold" Foreground="White"/>
                    </StackPanel>
                    <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <Border Style="{StaticResource CardStyle}" Margin="0,0,0,12">
                                <StackPanel>
                                    <Grid Margin="0,0,0,14">
                                        <Grid.ColumnDefinitions>
                                            <ColumnDefinition Width="Auto"/>
                                            <ColumnDefinition Width="*"/>
                                        </Grid.ColumnDefinitions>
                                        <Grid Grid.Column="0" Width="64" Height="64" ClipToBounds="False">
                                            <Ellipse Width="86" Height="86" HorizontalAlignment="Center" VerticalAlignment="Center">
                                                <Ellipse.Fill>
                                                    <RadialGradientBrush>
                                                        <GradientStop Color="#553b82f6" Offset="0"/>
                                                        <GradientStop Color="#003b82f6" Offset="1"/>
                                                    </RadialGradientBrush>
                                                </Ellipse.Fill>
                                            </Ellipse>
                                            <Ellipse Name="AboutLogoEllipse" Width="64" Height="64" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Grid>
                                        <StackPanel Grid.Column="1" Margin="16,0,0,0" VerticalAlignment="Center">
                                            <TextBlock Text="Kangaroo Boost" FontSize="20" FontWeight="Bold" Foreground="White"/>
                                            <TextBlock Text="PC Optimizer  -  by Kangaroo Co" FontSize="13" Foreground="#64748b" Margin="0,2,0,0"/>
                                        </StackPanel>
                                    </Grid>
                                    <TextBlock Text="Built with care, shared with everyone - free and open-source."
                                               Foreground="#cbd5e1" FontSize="14" TextWrapping="Wrap"/>
                                    <TextBlock Text="Kangaroo Boost is built by Owais Humayun and is part of the Kangaroo Co group of companies, based in Melbourne, Australia."
                                               Foreground="#cbd5e1" FontSize="14" TextWrapping="Wrap" Margin="0,8,0,0"/>
                                    <TextBlock Text="This tool only installs apps through winget (Microsoft's Official Installer) and only changes settings you choose."
                                               Foreground="#94a3b8" FontSize="13" TextWrapping="Wrap" Margin="0,10,0,0"/>
                                </StackPanel>
                            </Border>
                            <Border Style="{StaticResource CardStyle}" Margin="0,0,0,12">
                                <StackPanel>
                                    <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                                        <TextBlock Text="&#xE72E;" FontFamily="Segoe MDL2 Assets" FontSize="18" Foreground="#22c55e" VerticalAlignment="Center"/>
                                        <TextBlock Text="Restore Point Safety Net" FontSize="16" FontWeight="SemiBold"
                                                   Foreground="#22c55e" Margin="10,0,0,0" VerticalAlignment="Center"/>
                                    </StackPanel>
                                    <TextBlock Text="A System Restore Point is created automatically before any install, tweak, or cleanup. You can also make one manually."
                                               Foreground="#94a3b8" FontSize="13" TextWrapping="Wrap" Margin="0,0,0,14"/>
                                    <Button Name="BtnCreateRestorePoint" Content="Create Restore Point Now"
                                            HorizontalAlignment="Left" Style="{StaticResource SecondaryButtonStyle}"/>
                                    <TextBlock Name="TxtRestoreStatus" Text="" Foreground="#64748b" FontSize="12"
                                               Margin="0,10,0,0" TextWrapping="Wrap"/>
                                </StackPanel>
                            </Border>
                            <Border Style="{StaticResource CardStyle}">
                                <StackPanel>
                                    <TextBlock Text="A System Restore Point is created automatically before any change is made."
                                               Foreground="#475569" FontSize="12" TextWrapping="Wrap"/>
                                </StackPanel>
                            </Border>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>
            </Grid>
        </Grid>
        </Grid>
    </Border>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $Xaml

try {
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
} catch {
    Write-Host ""
    Write-Host "=== Kangaroo Boost failed to load the window. Full error details: ===" -ForegroundColor Red
    $ex = $_.Exception
    $level = 0
    while ($ex) {
        Write-Host "[$level] $($ex.GetType().FullName): $($ex.Message)" -ForegroundColor Yellow
        $ex = $ex.InnerException
        $level++
    }
    Write-Host ""
    Write-Host "Please copy everything above and share it so this can be fixed." -ForegroundColor Cyan
    Read-Host "Press Enter to close"
    exit
}

# ---------------------------------------------------------------------------
#  FIND ALL NAMED ELEMENTS
# ---------------------------------------------------------------------------
$PageDashboard = $Window.FindName("PageDashboard")
$PageInstall   = $Window.FindName("PageInstall")
$PageTweaks    = $Window.FindName("PageTweaks")
$PageCleanup   = $Window.FindName("PageCleanup")
$PageSpeedTest = $Window.FindName("PageSpeedTest")
$PageAbout     = $Window.FindName("PageAbout")

$NavDashboard    = $Window.FindName("NavDashboard")
$NavInstall      = $Window.FindName("NavInstall")
$NavTweaks       = $Window.FindName("NavTweaks")
$NavCleanup      = $Window.FindName("NavCleanup")
$NavSpeedTest    = $Window.FindName("NavSpeedTest")
$NavAbout        = $Window.FindName("NavAbout")

$NavDashboardBar = $Window.FindName("NavDashboardBar")
$NavInstallBar   = $Window.FindName("NavInstallBar")
$NavTweaksBar    = $Window.FindName("NavTweaksBar")
$NavCleanupBar   = $Window.FindName("NavCleanupBar")
$NavSpeedTestBar = $Window.FindName("NavSpeedTestBar")
$NavAboutBar     = $Window.FindName("NavAboutBar")

$NavInstallIcon  = $Window.FindName("NavInstallIcon")
$NavTweaksIcon   = $Window.FindName("NavTweaksIcon")
$NavCleanupIcon  = $Window.FindName("NavCleanupIcon")
$NavSpeedTestIcon = $Window.FindName("NavSpeedTestIcon")
$NavAboutIcon    = $Window.FindName("NavAboutIcon")

$NavInstallText  = $Window.FindName("NavInstallText")
$NavTweaksText   = $Window.FindName("NavTweaksText")
$NavCleanupText  = $Window.FindName("NavCleanupText")
$NavSpeedTestText = $Window.FindName("NavSpeedTestText")
$NavAboutText    = $Window.FindName("NavAboutText")

$AppsPanel       = $Window.FindName("AppsPanel")
$TweaksPanel     = $Window.FindName("TweaksPanel")
$CleanupPanel    = $Window.FindName("CleanupPanel")
$IssuesPanel     = $Window.FindName("IssuesPanel")
$GaugeCanvas     = $Window.FindName("GaugeCanvas")

$BtnInstallApps  = $Window.FindName("BtnInstallApps")
$BtnApplyTweaks  = $Window.FindName("BtnApplyTweaks")
$BtnRunCleanup   = $Window.FindName("BtnRunCleanup")
$BtnCreateRestorePoint = $Window.FindName("BtnCreateRestorePoint")

$PbApps          = $Window.FindName("PbApps")
$PbTweaks        = $Window.FindName("PbTweaks")
$PbCleanup       = $Window.FindName("PbCleanup")

$TxtAppsPercent     = $Window.FindName("TxtAppsPercent")
$TxtTweaksPercent   = $Window.FindName("TxtTweaksPercent")
$TxtCleanupPercent  = $Window.FindName("TxtCleanupPercent")

$TxtAppsStatus      = $Window.FindName("TxtAppsStatus")
$TxtTweaksStatus    = $Window.FindName("TxtTweaksStatus")
$TxtCleanupStatus   = $Window.FindName("TxtCleanupStatus")
$TxtRestoreStatus   = $Window.FindName("TxtRestoreStatus")

$TxtAppsSelectedCount    = $Window.FindName("TxtAppsSelectedCount")
$TxtTweaksSelectedCount  = $Window.FindName("TxtTweaksSelectedCount")
$TxtCleanupSelectedCount = $Window.FindName("TxtCleanupSelectedCount")

$BtnAppsSelectAll    = $Window.FindName("BtnAppsSelectAll")
$BtnAppsClearAll     = $Window.FindName("BtnAppsClearAll")
$BtnTweaksSelectAll  = $Window.FindName("BtnTweaksSelectAll")
$BtnTweaksClearAll   = $Window.FindName("BtnTweaksClearAll")
$BtnCleanupSelectAll = $Window.FindName("BtnCleanupSelectAll")
$BtnCleanupClearAll  = $Window.FindName("BtnCleanupClearAll")

$BtnScanNow          = $Window.FindName("BtnScanNow")
$TxtScanSummary      = $Window.FindName("TxtScanSummary")
$BtnQuickInstall     = $Window.FindName("BtnQuickInstall")
$BtnQuickTweaks      = $Window.FindName("BtnQuickTweaks")
$BtnQuickCleanup     = $Window.FindName("BtnQuickCleanup")
$BtnQuickSpeedTest   = $Window.FindName("BtnQuickSpeedTest")

$BtnRunSpeedTest     = $Window.FindName("BtnRunSpeedTest")
$TxtDownloadSpeed    = $Window.FindName("TxtDownloadSpeed")
$TxtUploadSpeed      = $Window.FindName("TxtUploadSpeed")
$TxtPingResult       = $Window.FindName("TxtPingResult")
$TxtSpeedTestStatus  = $Window.FindName("TxtSpeedTestStatus")

$BtnMinimize    = $Window.FindName("BtnMinimize")
$BtnMaximize    = $Window.FindName("BtnMaximize")
$BtnCloseWindow = $Window.FindName("BtnCloseWindow")
$TitleBar       = $Window.FindName("TitleBar")

$TxtWinVersion  = $Window.FindName("TxtWinVersion")
$TxtDiskValue   = $Window.FindName("TxtDiskValue")
$TxtDiskSub     = $Window.FindName("TxtDiskSub")
$DiskBar        = $Window.FindName("DiskBar")
$TxtMemValue    = $Window.FindName("TxtMemValue")
$TxtMemSub      = $Window.FindName("TxtMemSub")
$MemBar         = $Window.FindName("MemBar")
$TxtUptime      = $Window.FindName("TxtUptime")
$TxtProtection  = $Window.FindName("TxtProtection")

# ---------------------------------------------------------------------------
#  WINDOW CHROME (custom title bar)
# ---------------------------------------------------------------------------
$TitleBar.Add_MouseLeftButtonDown({ $Window.DragMove() })
$BtnMinimize.Add_Click({ $Window.WindowState = 'Minimized' })
$BtnMaximize.Add_Click({
    if ($Window.WindowState -eq 'Maximized') { $Window.WindowState = 'Normal' }
    else { $Window.WindowState = 'Maximized' }
})
$BtnCloseWindow.Add_Click({ $Window.Close() })

# ---------------------------------------------------------------------------
#  NAVIGATION - sidebar page switching
# ---------------------------------------------------------------------------
$NavItems = @{
    Dashboard = @{ Border = $NavDashboard; Bar = $NavDashboardBar; Icon = $null;            Text = $null;            Page = $PageDashboard }
    Install   = @{ Border = $NavInstall;   Bar = $NavInstallBar;   Icon = $NavInstallIcon;   Text = $NavInstallText;   Page = $PageInstall }
    Tweaks    = @{ Border = $NavTweaks;    Bar = $NavTweaksBar;    Icon = $NavTweaksIcon;    Text = $NavTweaksText;    Page = $PageTweaks }
    Cleanup   = @{ Border = $NavCleanup;   Bar = $NavCleanupBar;   Icon = $NavCleanupIcon;   Text = $NavCleanupText;   Page = $PageCleanup }
    SpeedTest = @{ Border = $NavSpeedTest; Bar = $NavSpeedTestBar; Icon = $NavSpeedTestIcon; Text = $NavSpeedTestText; Page = $PageSpeedTest }
    About     = @{ Border = $NavAbout;     Bar = $NavAboutBar;     Icon = $NavAboutIcon;     Text = $NavAboutText;     Page = $PageAbout }
}

$AccentColor = [System.Windows.Media.ColorConverter]::ConvertFromString("#3b82f6")
$MutedColor  = [System.Windows.Media.ColorConverter]::ConvertFromString("#64748b")
$TextColor   = [System.Windows.Media.ColorConverter]::ConvertFromString("#94a3b8")
$WhiteColor  = [System.Windows.Media.ColorConverter]::ConvertFromString("White")
$TransColor  = [System.Windows.Media.Colors]::Transparent

# Shared brush instances - a Brush isn't animated per-element here, so reusing
# one object across whichever single nav row is active at a time is safe.
$ActiveNavBrush = New-Object System.Windows.Media.LinearGradientBrush
$ActiveNavBrush.StartPoint = New-Object System.Windows.Point(0, 0)
$ActiveNavBrush.EndPoint   = New-Object System.Windows.Point(1, 0)
$ActiveNavBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop(
    [System.Windows.Media.ColorConverter]::ConvertFromString("#15294d"), 0)))
$ActiveNavBrush.GradientStops.Add((New-Object System.Windows.Media.GradientStop(
    [System.Windows.Media.ColorConverter]::ConvertFromString("#0c1a33"), 1)))
$TransBrush = New-Object System.Windows.Media.SolidColorBrush $TransColor

function Show-Page {
    param([string]$PageName)
    foreach ($key in $NavItems.Keys) {
        $item = $NavItems[$key]
        $isActive = ($key -eq $PageName)
        $item.Page.Visibility = if ($isActive) { "Visible" } else { "Collapsed" }
        $item.Border.Background = if ($isActive) { $ActiveNavBrush } else { $TransBrush }
        $item.Bar.Background    = New-Object System.Windows.Media.SolidColorBrush $(if ($isActive) { $AccentColor } else { $TransColor })
        if ($item.Icon) {
            $item.Icon.Foreground = New-Object System.Windows.Media.SolidColorBrush $(if ($isActive) { $AccentColor } else { $MutedColor })
        }
        if ($item.Text) {
            $item.Text.Foreground = New-Object System.Windows.Media.SolidColorBrush $(if ($isActive) { $WhiteColor } else { $TextColor })
            $item.Text.FontWeight = if ($isActive) { "SemiBold" } else { "Normal" }
        }
    }
}

$NavDashboard.Add_MouseLeftButtonDown({ Show-Page "Dashboard" })
$NavInstall.Add_MouseLeftButtonDown({   Show-Page "Install" })
$NavTweaks.Add_MouseLeftButtonDown({    Show-Page "Tweaks" })
$NavCleanup.Add_MouseLeftButtonDown({   Show-Page "Cleanup" })
$NavSpeedTest.Add_MouseLeftButtonDown({ Show-Page "SpeedTest" })
$NavAbout.Add_MouseLeftButtonDown({     Show-Page "About" })

$BtnQuickInstall.Add_Click({ Show-Page "Install" })
$BtnQuickTweaks.Add_Click({  Show-Page "Tweaks" })
$BtnQuickCleanup.Add_Click({ Show-Page "Cleanup" })
$BtnQuickSpeedTest.Add_Click({ Show-Page "SpeedTest" })

# ---------------------------------------------------------------------------
#  GAUGE DRAWING
# ---------------------------------------------------------------------------
function Draw-Gauge {
    param($Score)  # $null means "not scanned yet" - draws an empty placeholder dial
    $GaugeCanvas.Children.Clear()

    $cx = 100; $cy = 105; $r = 80; $thickness = 14

    # Helper: angle in degrees (0=right of gauge, 180=left) to point
    # Gauge sweeps from 180deg (left) to 0deg (right) through the top
    function Get-GaugePoint {
        param([double]$AngleDeg)
        $rad = $AngleDeg * [Math]::PI / 180
        $x = $cx + $r * [Math]::Cos($rad)
        $y = $cy - $r * [Math]::Sin($rad)
        return @{ X = $x; Y = $y }
    }

    # Draw arc helper
    function New-ArcPath {
        param([double]$StartAngle, [double]$EndAngle, [string]$Color, [double]$Thick)
        $start = Get-GaugePoint -AngleDeg $StartAngle
        $end   = Get-GaugePoint -AngleDeg $EndAngle

        $figure = New-Object System.Windows.Media.PathFigure
        $figure.StartPoint = New-Object System.Windows.Point($start.X, $start.Y)
        $figure.IsClosed = $false

        $arc = New-Object System.Windows.Media.ArcSegment
        $arc.Point = New-Object System.Windows.Point($end.X, $end.Y)
        $arc.Size = New-Object System.Windows.Size($r, $r)
        $sweep = $StartAngle - $EndAngle
        $arc.IsLargeArc = ($sweep -gt 180)
        $arc.SweepDirection = "Clockwise"
        $figure.Segments.Add($arc) | Out-Null

        $geo = New-Object System.Windows.Media.PathGeometry
        $geo.Figures.Add($figure) | Out-Null

        $path = New-Object System.Windows.Shapes.Path
        $path.Data = $geo
        $path.Stroke = New-Object System.Windows.Media.SolidColorBrush(
            [System.Windows.Media.ColorConverter]::ConvertFromString($Color))
        $path.StrokeThickness = $Thick
        $path.StrokeStartLineCap = "Round"
        $path.StrokeEndLineCap = "Round"
        $path.Fill = $null
        return $path
    }

    # Background arc (full semicircle)
    $bgArc = New-ArcPath -StartAngle 175 -EndAngle 5 -Color "#1c2d47" -Thick $thickness
    $GaugeCanvas.Children.Add($bgArc) | Out-Null

    if ($null -eq $Score) {
        # Not scanned yet - neutral placeholder, no progress arc
        $scoreColor = "#475569"
        $scoreText = "?"
        $label = "Not Scanned"
        $scoreLeft = 82
    } else {
        # Score arc
        $scoreAngle = 175 - (($Score / 100.0) * 170)
        if ($scoreAngle -lt 5) { $scoreAngle = 5 }

        $scoreColor = if ($Score -ge 75) { "#22c55e" } elseif ($Score -ge 50) { "#f59e0b" } else { "#ef4444" }
        if ($Score -gt 2) {
            $scoreArc = New-ArcPath -StartAngle 175 -EndAngle $scoreAngle -Color $scoreColor -Thick $thickness
            $GaugeCanvas.Children.Add($scoreArc) | Out-Null
        }
        $scoreText = "$Score"
        $label = if ($Score -ge 80) { "Excellent" } elseif ($Score -ge 60) { "Good" } elseif ($Score -ge 40) { "Fair" } else { "Needs Work" }
        $scoreLeft = if ($Score -eq 100) { 62 } elseif ($Score -ge 10) { 72 } else { 82 }
    }

    # Score text
    $scoreTb = New-Object System.Windows.Controls.TextBlock
    $scoreTb.Text = $scoreText
    $scoreTb.FontSize = 36
    $scoreTb.FontWeight = "Bold"
    $scoreTb.Foreground = New-Object System.Windows.Media.SolidColorBrush(
        [System.Windows.Media.ColorConverter]::ConvertFromString($scoreColor))
    $scoreTb.TextAlignment = "Center"
    [System.Windows.Controls.Canvas]::SetLeft($scoreTb, $scoreLeft)
    [System.Windows.Controls.Canvas]::SetTop($scoreTb, 52)
    $GaugeCanvas.Children.Add($scoreTb) | Out-Null

    # Label
    $labelTb = New-Object System.Windows.Controls.TextBlock
    $labelTb.Text = $label
    $labelTb.FontSize = 13
    $labelTb.Foreground = New-Object System.Windows.Media.SolidColorBrush(
        [System.Windows.Media.ColorConverter]::ConvertFromString("#94a3b8"))
    $labelTb.TextAlignment = "Center"
    $labelTb.Width = 100
    [System.Windows.Controls.Canvas]::SetLeft($labelTb, 50)
    [System.Windows.Controls.Canvas]::SetTop($labelTb, 92)
    $GaugeCanvas.Children.Add($labelTb) | Out-Null
}

# ---------------------------------------------------------------------------
#  DASHBOARD POPULATION
# ---------------------------------------------------------------------------
# Refreshes the factual stat cards (disk/memory/uptime/version). This is just
# reading current system info, not a "scan" claim, so it's safe to run on load.
function Update-DashboardStats {
    $TxtWinVersion.Text = Get-WindowsVersionText

    $disk = Get-DiskInfo
    $TxtDiskValue.Text = "$($disk.FreeGB) GB"
    $TxtDiskSub.Text = "free of $($disk.TotalGB) GB"
    try {
        $parentWidth = $DiskBar.Parent.ActualWidth
        if ($parentWidth -gt 0) { $DiskBar.Width = ($disk.PctUsed / 100.0) * $parentWidth }
    } catch {}

    $mem = Get-MemoryInfo
    $TxtMemValue.Text = "$($mem.PctUsed)%"
    $TxtMemSub.Text = "$($mem.UsedGB) of $($mem.TotalGB) GB used"
    try {
        $parentWidth = $MemBar.Parent.ActualWidth
        if ($parentWidth -gt 0) { $MemBar.Width = ($mem.PctUsed / 100.0) * $parentWidth }
    } catch {}

    $TxtUptime.Text = Get-UptimeText
}

# Runs the actual health scan - only ever called from an explicit user action
# (the Scan button, or right after Install/Tweaks/Cleanup complete), never on
# a cold window load, so the dashboard never claims a scan that didn't happen.
function Invoke-HealthScan {
    $BtnScanNow.IsEnabled = $false
    $TxtScanSummary.Text = "Scanning..."
    $TxtScanSummary.Foreground = New-Object System.Windows.Media.SolidColorBrush(
        [System.Windows.Media.ColorConverter]::ConvertFromString("#94a3b8"))
    $IssuesPanel.Children.Clear()
    $TxtScanSummary.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})

    Update-DashboardStats
    $health = Get-HealthScore
    Draw-Gauge -Score $health.Score

    $realIssues = @($health.Issues | Where-Object { $_ -ne "No issues detected" })
    if ($realIssues.Count -eq 0) {
        $TxtScanSummary.Text = "No issues detected"
        $TxtScanSummary.Foreground = New-Object System.Windows.Media.SolidColorBrush(
            [System.Windows.Media.ColorConverter]::ConvertFromString("#22c55e"))
    } else {
        $summaryColor = if ($health.Score -ge 75) { "#22c55e" } elseif ($health.Score -ge 50) { "#f59e0b" } else { "#ef4444" }
        $TxtScanSummary.Text = "$($realIssues.Count) issue$(if ($realIssues.Count -ne 1) { 's' } else { '' }) found"
        $TxtScanSummary.Foreground = New-Object System.Windows.Media.SolidColorBrush(
            [System.Windows.Media.ColorConverter]::ConvertFromString($summaryColor))

        foreach ($issue in $realIssues) {
            $row = New-Object System.Windows.Controls.StackPanel
            $row.Orientation = "Horizontal"
            $row.Margin = "0,3"

            $dot = New-Object System.Windows.Controls.TextBlock
            $dot.Text = [char]0xEA39
            $dot.FontFamily = New-Object System.Windows.Media.FontFamily("Segoe MDL2 Assets")
            $dot.FontSize = 12
            $dot.Foreground = New-Object System.Windows.Media.SolidColorBrush(
                [System.Windows.Media.ColorConverter]::ConvertFromString("#f59e0b"))
            $dot.VerticalAlignment = "Center"
            $dot.Margin = "0,0,8,0"
            $row.Children.Add($dot) | Out-Null

            $txt = New-Object System.Windows.Controls.TextBlock
            $txt.Text = $issue
            $txt.FontSize = 13
            $txt.Foreground = New-Object System.Windows.Media.SolidColorBrush(
                [System.Windows.Media.ColorConverter]::ConvertFromString("#cbd5e1"))
            $txt.VerticalAlignment = "Center"
            $txt.TextWrapping = "Wrap"
            $row.Children.Add($txt) | Out-Null

            $IssuesPanel.Children.Add($row) | Out-Null
        }
    }

    $BtnScanNow.Content = "Scan Again"
    $BtnScanNow.IsEnabled = $true
}

$BtnScanNow.Add_Click({ Invoke-HealthScan })

# ---------------------------------------------------------------------------
#  HELPER FUNCTIONS
# ---------------------------------------------------------------------------
function Update-SelectionCount {
    param($Checkboxes, $CountText)
    $count = @($Checkboxes.Values | Where-Object { $_.IsChecked }).Count
    $CountText.Text = "$count selected"
}

function New-CheckboxLabel {
    param([string]$Text)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.TextWrapping = "Wrap"
    return $tb
}

function New-SectionCard {
    param([string]$HeaderText, [string]$HeaderColor)
    $border = New-Object System.Windows.Controls.Border
    $border.Background = New-Object System.Windows.Media.SolidColorBrush(
        [System.Windows.Media.ColorConverter]::ConvertFromString("#0e1a2e"))
    $border.BorderBrush = New-Object System.Windows.Media.SolidColorBrush(
        [System.Windows.Media.ColorConverter]::ConvertFromString("#182a44"))
    $border.BorderThickness = "1"
    $border.CornerRadius = "8"
    $border.Padding = "12"
    $border.Margin = "0,0,0,10"

    $stack = New-Object System.Windows.Controls.StackPanel
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = $HeaderText
    $header.FontSize = 15
    $header.FontWeight = "SemiBold"
    $header.Foreground = New-Object System.Windows.Media.SolidColorBrush(
        [System.Windows.Media.ColorConverter]::ConvertFromString($HeaderColor))
    $header.Margin = "0,0,0,6"
    $stack.Children.Add($header) | Out-Null
    $border.Child = $stack
    return [pscustomobject]@{ Border = $border; Stack = $stack }
}

# ---------------------------------------------------------------------------
#  POPULATE APPS
# ---------------------------------------------------------------------------
$AppCheckboxes = @{}
foreach ($category in $AppCategories.Keys) {
    $card = New-SectionCard -HeaderText $category -HeaderColor "#3b82f6"
    foreach ($app in $AppCategories[$category]) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = New-CheckboxLabel "$($app.Name)  -  $($app.Desc)"
        $cb.ToolTip = $app.Desc
        $cb.Add_Checked({ Update-SelectionCount -Checkboxes $AppCheckboxes -CountText $TxtAppsSelectedCount })
        $cb.Add_Unchecked({ Update-SelectionCount -Checkboxes $AppCheckboxes -CountText $TxtAppsSelectedCount })
        $card.Stack.Children.Add($cb) | Out-Null
        $AppCheckboxes[$app.Id] = $cb
    }
    $AppsPanel.Children.Add($card.Border) | Out-Null
}

# ---------------------------------------------------------------------------
#  POPULATE TWEAKS
# ---------------------------------------------------------------------------
$TweakCheckboxes = @{}
foreach ($tier in @("Safe", "Advanced")) {
    $tierLabel = if ($tier -eq "Safe") { "Recommended" } else { "Advanced" }
    $tierColor = if ($tier -eq "Safe") { "#22c55e" } else { "#f59e0b" }
    $card = New-SectionCard -HeaderText $tierLabel -HeaderColor $tierColor
    foreach ($tweak in ($Tweaks | Where-Object { $_.Tier -eq $tier })) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = New-CheckboxLabel "$($tweak.Name)  -  $($tweak.Desc)"
        $cb.ToolTip = $tweak.Desc
        $cb.Add_Checked({ Update-SelectionCount -Checkboxes $TweakCheckboxes -CountText $TxtTweaksSelectedCount })
        $cb.Add_Unchecked({ Update-SelectionCount -Checkboxes $TweakCheckboxes -CountText $TxtTweaksSelectedCount })
        $card.Stack.Children.Add($cb) | Out-Null
        $TweakCheckboxes[$tweak.Name] = $cb
    }
    $TweaksPanel.Children.Add($card.Border) | Out-Null
}

# ---------------------------------------------------------------------------
#  POPULATE CLEANUP
# ---------------------------------------------------------------------------
$CleanupCheckboxes = @{}
foreach ($item in $CleanupItems) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = New-CheckboxLabel "$($item.Name)  -  $($item.Desc)"
    $cb.ToolTip = $item.Desc
    $cb.Margin = "6,2,0,2"
    $cb.Add_Checked({ Update-SelectionCount -Checkboxes $CleanupCheckboxes -CountText $TxtCleanupSelectedCount })
    $cb.Add_Unchecked({ Update-SelectionCount -Checkboxes $CleanupCheckboxes -CountText $TxtCleanupSelectedCount })
    $CleanupPanel.Children.Add($cb) | Out-Null
    $CleanupCheckboxes[$item.Name] = $cb
}

if (-not $WingetAvailable) {
    $BtnInstallApps.IsEnabled = $false
    $TxtAppsStatus.Text = "winget not available. Install 'App Installer' from the Microsoft Store."
}

# ---------------------------------------------------------------------------
#  SELECT ALL / CLEAR ALL
# ---------------------------------------------------------------------------
$BtnAppsSelectAll.Add_Click({ $AppCheckboxes.Values | ForEach-Object { $_.IsChecked = $true } })
$BtnAppsClearAll.Add_Click({ $AppCheckboxes.Values | ForEach-Object { $_.IsChecked = $false } })
$BtnTweaksSelectAll.Add_Click({ $TweakCheckboxes.Values | ForEach-Object { $_.IsChecked = $true } })
$BtnTweaksClearAll.Add_Click({ $TweakCheckboxes.Values | ForEach-Object { $_.IsChecked = $false } })
$BtnCleanupSelectAll.Add_Click({ $CleanupCheckboxes.Values | ForEach-Object { $_.IsChecked = $true } })
$BtnCleanupClearAll.Add_Click({ $CleanupCheckboxes.Values | ForEach-Object { $_.IsChecked = $false } })

# ---------------------------------------------------------------------------
#  INSTALL APPS
# ---------------------------------------------------------------------------
$BtnInstallApps.Add_Click({
    if (-not $WingetAvailable) {
        [System.Windows.MessageBox]::Show("winget isn't available on this PC. Install 'App Installer' from the Microsoft Store, then try again.", "Kangaroo Boost")
        return
    }
    $selected = @()
    foreach ($category in $AppCategories.Keys) {
        foreach ($app in $AppCategories[$category]) {
            if ($AppCheckboxes[$app.Id].IsChecked) { $selected += $app }
        }
    }
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Tick at least one app first.", "Kangaroo Boost")
        return
    }

    $BtnInstallApps.IsEnabled = $false
    Set-Progress -Bar $PbApps -PercentText $TxtAppsPercent -Percent 0
    New-SafetyRestorePoint | Out-Null

    $failed = @()
    $i = 0
    foreach ($app in $selected) {
        $i++
        $TxtAppsStatus.Text = "Installing $($app.Name)... ($i of $($selected.Count))"
        Set-Progress -Bar $PbApps -PercentText $TxtAppsPercent -Percent ((($i - 1) / $selected.Count) * 100)
        Write-Host "[KangarooBoost] Installing $($app.Name)..." -ForegroundColor Cyan
        try {
            $proc = Start-Process winget -ArgumentList "install --id $($app.Id) --source winget --silent --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow -PassThru
            if ($proc.ExitCode -ne 0) {
                $failed += $app.Name
                Write-Host "[KangarooBoost] $($app.Name) exited with code $($proc.ExitCode)" -ForegroundColor Yellow
            }
        } catch {
            $failed += $app.Name
            Write-Host "[KangarooBoost] Failed to install $($app.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        Set-Progress -Bar $PbApps -PercentText $TxtAppsPercent -Percent (($i / $selected.Count) * 100)
    }

    $succeeded = $selected.Count - $failed.Count
    if ($failed.Count -eq 0) {
        $TxtAppsStatus.Text = "Done! Installed $succeeded app$(if ($succeeded -ne 1) { 's' })."
        [System.Windows.MessageBox]::Show("Finished installing $succeeded app(s).", "Kangaroo Boost")
    } else {
        $TxtAppsStatus.Text = "Installed $succeeded of $($selected.Count). Failed: $($failed -join ', ')."
        [System.Windows.MessageBox]::Show("Installed $succeeded of $($selected.Count) app(s).`n`nFailed: $($failed -join ', ')`n`nCheck the console for details.", "Kangaroo Boost")
    }
    $BtnInstallApps.IsEnabled = $true
    Invoke-HealthScan
})

# ---------------------------------------------------------------------------
#  APPLY TWEAKS
# ---------------------------------------------------------------------------
$BtnApplyTweaks.Add_Click({
    $selected = @($Tweaks | Where-Object { $TweakCheckboxes[$_.Name].IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Tick at least one tweak first.", "Kangaroo Boost")
        return
    }

    $BtnApplyTweaks.IsEnabled = $false
    Set-Progress -Bar $PbTweaks -PercentText $TxtTweaksPercent -Percent 0
    New-SafetyRestorePoint | Out-Null

    $failed = @()
    $i = 0
    foreach ($tweak in $selected) {
        $i++
        $TxtTweaksStatus.Text = "Applying: $($tweak.Name) ($i of $($selected.Count))"
        Set-Progress -Bar $PbTweaks -PercentText $TxtTweaksPercent -Percent ((($i - 1) / $selected.Count) * 100)
        Write-Host "[KangarooBoost] Applying: $($tweak.Name)" -ForegroundColor Cyan
        try { & $tweak.Apply }
        catch {
            $failed += $tweak.Name
            Write-Host "[KangarooBoost] Failed: $($tweak.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        Set-Progress -Bar $PbTweaks -PercentText $TxtTweaksPercent -Percent (($i / $selected.Count) * 100)
    }

    $succeeded = $selected.Count - $failed.Count
    if ($failed.Count -eq 0) {
        $TxtTweaksStatus.Text = "Done! Applied $succeeded tweak$(if ($succeeded -ne 1) { 's' })."
        [System.Windows.MessageBox]::Show("Applied $succeeded tweak(s).", "Kangaroo Boost")
    } else {
        $TxtTweaksStatus.Text = "Applied $succeeded of $($selected.Count). Failed: $($failed -join ', ')."
        [System.Windows.MessageBox]::Show("Applied $succeeded of $($selected.Count) tweak(s).`n`nFailed: $($failed -join ', ')", "Kangaroo Boost")
    }
    $BtnApplyTweaks.IsEnabled = $true
    Invoke-HealthScan
})

# ---------------------------------------------------------------------------
#  RUN CLEANUP
# ---------------------------------------------------------------------------
$BtnRunCleanup.Add_Click({
    $selected = @($CleanupItems | Where-Object { $CleanupCheckboxes[$_.Name].IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Tick at least one cleanup item first.", "Kangaroo Boost")
        return
    }

    $BtnRunCleanup.IsEnabled = $false
    Set-Progress -Bar $PbCleanup -PercentText $TxtCleanupPercent -Percent 0
    New-SafetyRestorePoint | Out-Null

    $failed = @()
    $i = 0
    foreach ($item in $selected) {
        $i++
        $TxtCleanupStatus.Text = "Cleaning: $($item.Name) ($i of $($selected.Count))"
        Set-Progress -Bar $PbCleanup -PercentText $TxtCleanupPercent -Percent ((($i - 1) / $selected.Count) * 100)
        Write-Host "[KangarooBoost] Cleaning: $($item.Name)" -ForegroundColor Cyan
        try { & $item.Apply }
        catch {
            $failed += $item.Name
            Write-Host "[KangarooBoost] Failed: $($item.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        Set-Progress -Bar $PbCleanup -PercentText $TxtCleanupPercent -Percent (($i / $selected.Count) * 100)
    }

    $succeeded = $selected.Count - $failed.Count
    if ($failed.Count -eq 0) {
        $TxtCleanupStatus.Text = "Done! Cleaned $succeeded item$(if ($succeeded -ne 1) { 's' })."
        [System.Windows.MessageBox]::Show("Cleanup finished! Your PC should have more free space.", "Kangaroo Boost")
    } else {
        $TxtCleanupStatus.Text = "Cleaned $succeeded of $($selected.Count). Failed: $($failed -join ', ')."
        [System.Windows.MessageBox]::Show("Cleaned $succeeded of $($selected.Count).`n`nFailed: $($failed -join ', ')", "Kangaroo Boost")
    }
    $BtnRunCleanup.IsEnabled = $true
    Invoke-HealthScan
})

# ---------------------------------------------------------------------------
#  RESTORE POINT (About page)
# ---------------------------------------------------------------------------
$BtnCreateRestorePoint.Add_Click({
    $BtnCreateRestorePoint.IsEnabled = $false
    $TxtRestoreStatus.Text = "Creating restore point..."
    $TxtRestoreStatus.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
    switch (New-SafetyRestorePoint) {
        "created"  { $TxtRestoreStatus.Text = "Restore point created. You're safe to make changes."; $TxtProtection.Text = "Active" }
        "existing" { $TxtRestoreStatus.Text = "You already have a restore point from the last 24 hours, so Windows won't create another yet. You're still covered."; $TxtProtection.Text = "Active" }
        "failed"   { $TxtRestoreStatus.Text = "Couldn't create a restore point. Check that System Restore is enabled for this drive." }
    }
    $BtnCreateRestorePoint.IsEnabled = $true
})

# ---------------------------------------------------------------------------
#  SPEED TEST (download speed via a public test file, latency via ping)
# ---------------------------------------------------------------------------
$BtnRunSpeedTest.Add_Click({
    $BtnRunSpeedTest.IsEnabled = $false
    $TxtDownloadSpeed.Text = "--"
    $TxtUploadSpeed.Text = "--"
    $TxtPingResult.Text = "--"
    $TxtSpeedTestStatus.Text = "Testing latency..."
    $TxtSpeedTestStatus.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})

    $ping = Test-InternetLatency
    $TxtPingResult.Text = if ($null -ne $ping) { "$ping" } else { "N/A" }

    $TxtSpeedTestStatus.Text = "Testing download speed... this can take a few seconds."
    $TxtSpeedTestStatus.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})

    $downloadResult = Test-InternetDownloadSpeed
    $downloadOk = $downloadResult.Success
    if ($downloadOk) {
        $TxtDownloadSpeed.Text = "$($downloadResult.Mbps)"
    } else {
        $TxtDownloadSpeed.Text = "N/A"
        Write-Host "[KangarooBoost] Download speed test failed: $($downloadResult.Error)" -ForegroundColor Yellow
    }

    $TxtSpeedTestStatus.Text = "Testing upload speed... this can take a few seconds."
    $TxtSpeedTestStatus.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})

    $uploadResult = Test-InternetUploadSpeed
    $uploadOk = $uploadResult.Success
    if ($uploadOk) {
        $TxtUploadSpeed.Text = "$($uploadResult.Mbps)"
    } else {
        $TxtUploadSpeed.Text = "N/A"
        Write-Host "[KangarooBoost] Upload speed test failed: $($uploadResult.Error)" -ForegroundColor Yellow
    }

    if ($downloadOk -or $uploadOk) {
        $TxtSpeedTestStatus.Text = "Done! Speeds can vary depending on your connection and current network load."
    } else {
        $TxtSpeedTestStatus.Text = "Couldn't reach the speed test service. Check your internet connection, or a firewall/VPN may be blocking it."
    }
    $BtnRunSpeedTest.IsEnabled = $true
})

# ---------------------------------------------------------------------------
#  LOGO - Owais Humayun logo shown on the About page
# ---------------------------------------------------------------------------
try {
    $LogoBytes = [Convert]::FromBase64String($OwaisLogoBase64)
    $LogoStream = New-Object System.IO.MemoryStream(, $LogoBytes)
    $LogoBitmap = New-Object System.Windows.Media.Imaging.BitmapImage
    $LogoBitmap.BeginInit()
    $LogoBitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $LogoBitmap.StreamSource = $LogoStream
    $LogoBitmap.EndInit()
    $LogoBitmap.Freeze()

    $LogoBrush = New-Object System.Windows.Media.ImageBrush $LogoBitmap
    $LogoBrush.Stretch = [System.Windows.Media.Stretch]::UniformToFill
    $LogoBrush.Freeze()

    $AboutLogoEllipse = $Window.FindName("AboutLogoEllipse")
    if ($AboutLogoEllipse) { $AboutLogoEllipse.Fill = $LogoBrush }
} catch {
    Write-Host "[KangarooBoost] Could not load the About page logo: $($_.Exception.Message)" -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
#  INITIALIZE DASHBOARD & SHOW WINDOW
# ---------------------------------------------------------------------------
$Window.Add_ContentRendered({
    Update-DashboardStats
    Draw-Gauge -Score $null
})

$Window.ShowDialog() | Out-Null
