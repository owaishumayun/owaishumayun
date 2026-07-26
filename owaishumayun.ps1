#Requires -RunAsAdministrator
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

$WingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

# ---------------------------------------------------------------------------
#  SAFETY: Restore Point
# ---------------------------------------------------------------------------
function New-SafetyRestorePoint {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Kangaroo Boost - Snapshot" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[KangarooBoost] Restore point created." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[KangarooBoost] Could not create a new restore point (Windows only allows one every 24h)." -ForegroundColor Yellow
        return $false
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
#  Download speed is measured by timing a download of a public test file
#  (Tele2's speedtest server, a well-known host provided specifically for
#  this purpose). Upload speed isn't measured - a real upload benchmark
#  needs a paired server to receive the data, which this tool doesn't have.
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
    $url = "https://speedtest.tele2.net/10MB.zip"
    $tempFile = [System.IO.Path]::GetTempFileName()
    try {
        $wc = New-Object System.Net.WebClient
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $wc.DownloadFile($url, $tempFile)
        $sw.Stop()
        $bytes = (Get-Item $tempFile -ErrorAction Stop).Length
        $seconds = [math]::Max($sw.Elapsed.TotalSeconds, 0.01)
        $mbps = [math]::Round((($bytes * 8) / $seconds) / 1MB, 1)
        return @{ Success = $true; Mbps = $mbps }
    } catch {
        return @{ Success = $false; Error = $_.Exception.Message }
    } finally {
        Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
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

        <!-- Card Style -->
        <Style x:Key="CardStyle" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource CardBg}"/>
            <Setter Property="BorderBrush" Value="{StaticResource CardBorder}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="18"/>
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
                                <Border x:Name="Box" Width="18" Height="18" CornerRadius="4"
                                        BorderBrush="#475569" BorderThickness="1.5" Background="#0b1120" VerticalAlignment="Center">
                                    <Path x:Name="CheckMark" Data="M3,7 L7,11 L14,3" Stroke="White" StrokeThickness="2"
                                          StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round"
                                          Visibility="Collapsed" Margin="0,1,0,0"/>
                                </Border>
                                <ContentPresenter Margin="10,0,0,0" VerticalAlignment="Center"/>
                            </StackPanel>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter TargetName="Box" Property="Background" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="Box" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="CheckMark" Property="Visibility" Value="Visible"/>
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
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="Padding" Value="20,11"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="Bg" Background="{TemplateBinding Background}" CornerRadius="8">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"
                                               Margin="{TemplateBinding Padding}"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bg" Property="Background" Value="{StaticResource AccentHoverBrush}"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="Bg" Property="Opacity" Value="0.85"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="Bg" Property="Background" Value="#334155"/>
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
                                    <Rectangle x:Name="PART_Indicator" Fill="{StaticResource AccentBrush}"
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
            <Border Grid.Column="0" Background="#070d1a" CornerRadius="0,0,0,12">
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
                            <Border Grid.Column="0" Width="42" Height="42" CornerRadius="10">
                                <Border.Background>
                                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                        <GradientStop Color="#3b82f6" Offset="0"/>
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
                                        CornerRadius="0,2,2,0" Name="NavDashboardBar">
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
                                        CornerRadius="0,2,2,0" Name="NavInstallBar" Background="Transparent"/>
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
                                        CornerRadius="0,2,2,0" Name="NavTweaksBar" Background="Transparent"/>
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
                                        CornerRadius="0,2,2,0" Name="NavCleanupBar" Background="Transparent"/>
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
                                        CornerRadius="0,2,2,0" Name="NavSpeedTestBar" Background="Transparent"/>
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
                                        CornerRadius="0,2,2,0" Name="NavAboutBar" Background="Transparent"/>
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
                        <TextBlock Text="Check your internet download speed and latency." Foreground="#64748b" FontSize="13" Margin="0,2,0,0"/>
                    </StackPanel>
                    <Border Grid.Row="1" Style="{StaticResource CardStyle}" Padding="28" VerticalAlignment="Top">
                        <StackPanel HorizontalAlignment="Center">
                            <Grid Margin="0,0,0,20">
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="160"/>
                                    <ColumnDefinition Width="160"/>
                                </Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" HorizontalAlignment="Center">
                                    <TextBlock Text="Download" Foreground="#94a3b8" FontSize="13" HorizontalAlignment="Center"/>
                                    <TextBlock Name="TxtDownloadSpeed" Text="--" FontSize="34" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                                    <TextBlock Text="Mbps" Foreground="#64748b" FontSize="12" HorizontalAlignment="Center"/>
                                </StackPanel>
                                <StackPanel Grid.Column="1" HorizontalAlignment="Center">
                                    <TextBlock Text="Ping" Foreground="#94a3b8" FontSize="13" HorizontalAlignment="Center"/>
                                    <TextBlock Name="TxtPingResult" Text="--" FontSize="34" FontWeight="Bold" Foreground="White" HorizontalAlignment="Center"/>
                                    <TextBlock Text="ms" Foreground="#64748b" FontSize="12" HorizontalAlignment="Center"/>
                                </StackPanel>
                            </Grid>
                            <Button Name="BtnRunSpeedTest" Content="Run Speed Test" Padding="30,12" HorizontalAlignment="Center"/>
                            <TextBlock Name="TxtSpeedTestStatus" Text="Tests download speed and latency using a public test server. Upload speed isn't measured."
                                       Foreground="#64748b" FontSize="12" Margin="0,14,0,0" TextWrapping="Wrap" TextAlignment="Center" Width="320"/>
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
                                        <Border Grid.Column="0" Width="56" Height="56" CornerRadius="14">
                                            <Border.Background>
                                                <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                                                    <GradientStop Color="#3b82f6" Offset="0"/>
                                                    <GradientStop Color="#1d4ed8" Offset="1"/>
                                                </LinearGradientBrush>
                                            </Border.Background>
                                            <TextBlock Text="KB" FontSize="20" FontWeight="Bold" Foreground="White"
                                                       HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                        </Border>
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
$ActiveBg    = [System.Windows.Media.ColorConverter]::ConvertFromString("#0f1d36")
$TransColor  = [System.Windows.Media.Colors]::Transparent

function Show-Page {
    param([string]$PageName)
    foreach ($key in $NavItems.Keys) {
        $item = $NavItems[$key]
        $isActive = ($key -eq $PageName)
        $item.Page.Visibility = if ($isActive) { "Visible" } else { "Collapsed" }
        $item.Border.Background = New-Object System.Windows.Media.SolidColorBrush $(if ($isActive) { $ActiveBg } else { $TransColor })
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
    $ok = New-SafetyRestorePoint
    if ($ok) {
        $TxtRestoreStatus.Text = "Restore point created. You're safe to make changes."
        $TxtProtection.Text = "Active"
    } else {
        $TxtRestoreStatus.Text = "Windows only allows one restore point every 24 hours - you likely already have a recent one."
    }
    $BtnCreateRestorePoint.IsEnabled = $true
})

# ---------------------------------------------------------------------------
#  SPEED TEST (download speed via a public test file, latency via ping)
# ---------------------------------------------------------------------------
$BtnRunSpeedTest.Add_Click({
    $BtnRunSpeedTest.IsEnabled = $false
    $TxtDownloadSpeed.Text = "--"
    $TxtPingResult.Text = "--"
    $TxtSpeedTestStatus.Text = "Testing latency..."
    $TxtSpeedTestStatus.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})

    $ping = Test-InternetLatency
    $TxtPingResult.Text = if ($null -ne $ping) { "$ping" } else { "N/A" }

    $TxtSpeedTestStatus.Text = "Testing download speed... this can take a few seconds."
    $TxtSpeedTestStatus.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})

    $result = Test-InternetDownloadSpeed
    if ($result.Success) {
        $TxtDownloadSpeed.Text = "$($result.Mbps)"
        $TxtSpeedTestStatus.Text = "Done! Speeds can vary depending on your connection and current network load."
    } else {
        $TxtDownloadSpeed.Text = "N/A"
        $TxtSpeedTestStatus.Text = "Couldn't complete the speed test. Check your internet connection and try again."
    }
    $BtnRunSpeedTest.IsEnabled = $true
})

# ---------------------------------------------------------------------------
#  INITIALIZE DASHBOARD & SHOW WINDOW
# ---------------------------------------------------------------------------
$Window.Add_ContentRendered({
    Update-DashboardStats
    Draw-Gauge -Score $null
})

$Window.ShowDialog() | Out-Null
