#Requires -RunAsAdministrator
<#
    Owais Humayun
    Install Programs, Tweaks, and Fixes for Windows 10/11
    Simple. Safe. Free.
    License: MIT
    Repo:    https://github.com/owaishumayun/owaishumayun
#>

# ---------------------------------------------------------------------------
#  WPF requires the console to be running in STA (Single-Threaded Apartment)
#  mode. Running via "irm | iex" can sometimes land in the wrong mode. If
#  that happens, relaunch this exact script correctly instead of crashing.
# ---------------------------------------------------------------------------
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    Write-Host "[OwaisHumayun] Restarting in the correct mode, one moment..." -ForegroundColor Yellow
    Start-Process powershell.exe -ArgumentList @(
        "-NoProfile", "-ExecutionPolicy", "Bypass", "-STA", "-Command",
        "irm 'https://raw.githubusercontent.com/owaishumayun/owaishumayun/main/owaishumayun.ps1' | iex"
    )
    exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# Force a standard culture for parsing the XAML - fixes "FontSize threw an exception"
# on PCs set to regional formats that use a comma instead of a period for numbers.
[System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
[System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::InvariantCulture

# ---------------------------------------------------------------------------
#  SAFETY: Create a restore point before anything else runs
# ---------------------------------------------------------------------------
function New-SafetyRestorePoint {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Owais Humayun - Snapshot" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[OwaisHumayun] Restore point created. You can undo everything if needed." -ForegroundColor Green
    } catch {
        Write-Host "[OwaisHumayun] Could not create a new restore point (Windows only allows one every 24h). Continuing safely." -ForegroundColor Yellow
    }
}

# ---------------------------------------------------------------------------
#  APP CATALOG - grouped into friendly categories
#  Each app installs through winget, Microsoft's official, trusted installer.
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
#  TWEAKS - grouped Safe (recommended for everyone) and Advanced (power users)
#  Written in plain English so anyone can understand what they do.
# ---------------------------------------------------------------------------
$Tweaks = @(
    # --- Safe / Recommended ---
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

    @{ Name = "Remove Annoying 'Tips & Suggestions'"; Tier = "Safe";
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

    # --- Advanced / Power Users ---
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
       Desc = "Prioritizes speed over battery savings - best for desktops, less ideal for laptops on battery.";
       Apply = { Start-Process powercfg -ArgumentList "/s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -Wait -NoNewWindow } }

    @{ Name = "Reset Network Adapters (Release and Renew IP)"; Tier = "Advanced";
       Desc = "Releases and renews your IP address and flushes DNS - can fix internet connection problems. Briefly disconnects you from the network.";
       Apply = {
            Start-Process ipconfig -ArgumentList "/release" -Wait -NoNewWindow
            Start-Process ipconfig -ArgumentList "/renew" -Wait -NoNewWindow
            Start-Process ipconfig -ArgumentList "/flushdns" -Wait -NoNewWindow
       } }
)

# ---------------------------------------------------------------------------
#  CLEANUP CHECKLIST - quick, safe, one-tick-box junk removal.
#  Windows rebuilds all of these automatically, nothing important is lost.
# ---------------------------------------------------------------------------
$CleanupItems = @(
    @{ Name = "Clear Your Personal Temp Files"; Desc = "Deletes leftover temporary files in your user folder.";
       Apply = { Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Windows Temp Folder"; Desc = "Deletes temporary files Windows itself created.";
       Apply = { Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Prefetch Files"; Desc = "Safe to delete - Windows quietly rebuilds these to help apps start faster.";
       Apply = { Remove-Item -Path "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Recent Files List"; Desc = "Clears the list of recently opened files shown in File Explorer."; 
       Apply = { Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Empty Recycle Bin"; Desc = "Permanently deletes everything currently in the Recycle Bin.";
       Apply = { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Windows Update Leftovers"; Desc = "Frees up a lot of space by deleting old, already-installed update files."; 
       Apply = {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
       } }

    @{ Name = "Clear Thumbnail Cache"; Desc = "Clears cached picture previews - Windows regenerates them next time you browse folders.";
       Apply = { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Internet Cache"; Desc = "Clears cached web files stored by Windows components.";
       Apply = { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Flush DNS Cache"; Desc = "Clears stored website addresses - can fix websites failing to load."; 
       Apply = { Start-Process ipconfig -ArgumentList "/flushdns" -Wait -NoNewWindow } }

    @{ Name = "Clear Clipboard"; Desc = "Empties whatever text or image is currently copied to your clipboard.";
       Apply = { Set-Clipboard -Value $null -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Jump Lists"; Desc = "Clears the recent-file shortcuts that show when you right-click a taskbar icon.";
       Apply = {
            Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\AutomaticDestinations\*" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\CustomDestinations\*" -Force -ErrorAction SilentlyContinue
       } }

    @{ Name = "Clear Windows Error Reporting Files"; Desc = "Deletes old crash and error report files Windows has saved up over time.";
       Apply = { Remove-Item -Path "$env:ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Memory Dump Files"; Desc = "Deletes crash-dump files left behind after a system error - these can be several GB in size.";
       Apply = {
            Remove-Item -Path "$env:SystemRoot\Minidump\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:SystemRoot\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
       } }

    @{ Name = "Rebuild Icon Cache"; Desc = "Fixes broken, blank, or wrong-looking icons by rebuilding Windows' icon cache.";
       Apply = {
            Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*.db" -Force -ErrorAction SilentlyContinue
            Start-Process explorer
       } }

    @{ Name = "Rebuild Font Cache"; Desc = "Fixes fonts that look wrong or fail to display properly by refreshing the font cache.";
       Apply = {
            Stop-Service -Name FontCache -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\FontCache*" -Force -ErrorAction SilentlyContinue
            Start-Service -Name FontCache -ErrorAction SilentlyContinue
       } }
)

# ---------------------------------------------------------------------------
#  WPF LAYOUT - big fonts, high contrast, simple language, tooltips everywhere
# ---------------------------------------------------------------------------
[xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Owais Humayun"
        Height="750" Width="950" WindowStartupLocation="CenterScreen"
        Background="#1e293b" FontSize="16">
    <Grid Margin="14">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,12">
            <StackPanel>
                <TextBlock Text="Owais Humayun" FontSize="28" FontWeight="Bold" Foreground="White"/>
                <TextBlock Text="Simple. Safe. Free" FontSize="14" Foreground="#f97316"/>
            </StackPanel>
        </StackPanel>

        <TabControl Grid.Row="1" Name="MainTabs" Background="#334155" FontSize="17">
            <TabItem Header="Install Apps">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Name="AppsPanel" Margin="12"/>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="Tweaks">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Name="TweaksPanel" Margin="12"/>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="Clean-Up">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="12">
                        <TextBlock Text="Quick Clean-Up"
                                   FontSize="19" FontWeight="Bold" Foreground="#4ade80" Margin="0,4,0,6" TextWrapping="Wrap"/>
                        <StackPanel Name="CleanupPanel"/>
                        <Button Name="BtnRunCleanup" Content="Run" Padding="14,8" Margin="0,10,0,20"
                                FontSize="16" FontWeight="Bold" HorizontalAlignment="Left"
                                ToolTip="Runs every cleanup item you've ticked above."/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="About">
                <StackPanel Margin="20">
                    <TextBlock Text="Owais Humayun" FontSize="22" FontWeight="Bold" Foreground="White"/>
                    <TextBlock Text="Built with care, shared with everyone - free and open-source, forever." Foreground="White" Margin="0,10,0,0" FontSize="16" TextWrapping="Wrap"/>
                    <TextBlock Text="This open source tool is designed by Owais Humayun." Foreground="White" Margin="0,10,0,0" FontSize="16" TextWrapping="Wrap"/>
                    <TextBlock Text="This tool only installs apps through winget (Microsoft's official installer) and only changes settings you choose." Foreground="#cbd5e1" Margin="0,15,0,0" FontSize="15" TextWrapping="Wrap"/>
                </StackPanel>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
            <Button Name="BtnApply" Content="Apply" Padding="16,10" Margin="6" FontSize="17"
                    ToolTip="Installs the apps and applies the tweaks you ticked."/>
            <Button Name="BtnRestorePoint" Content="Cancel" Padding="16,10" Margin="6" FontSize="17"
                    ToolTip="Closes without applying anything."/>
        </StackPanel>
    </Grid>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $Xaml

try {
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
} catch {
    Write-Host ""
    Write-Host "=== OwaisHumayun failed to load the window. Full error details: ===" -ForegroundColor Red
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

$AppsPanel        = $Window.FindName("AppsPanel")
$TweaksPanel      = $Window.FindName("TweaksPanel")
$CleanupPanel     = $Window.FindName("CleanupPanel")
$BtnApply         = $Window.FindName("BtnApply")
$BtnRestore       = $Window.FindName("BtnRestorePoint")
$BtnRunCleanup    = $Window.FindName("BtnRunCleanup")

# --- Populate Apps, grouped by category with big friendly headers ---
$AppCheckboxes = @{}
foreach ($category in $AppCategories.Keys) {
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = $category
    $header.FontSize = 19
    $header.FontWeight = "Bold"
    $header.Foreground = "#f97316"
    $header.Margin = "0,14,0,6"
    $AppsPanel.Children.Add($header) | Out-Null

    foreach ($app in $AppCategories[$category]) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = "$($app.Name)  -  $($app.Desc)"
        $cb.Foreground = "White"
        $cb.FontSize = 15
        $cb.Margin = "10,4,0,4"
        $cb.ToolTip = $app.Desc
        $AppsPanel.Children.Add($cb) | Out-Null
        $AppCheckboxes[$app.Id] = $cb
    }
}

# --- Populate Tweaks, Safe first then Advanced, each with plain description ---
$TweakCheckboxes = @{}
foreach ($tier in @("Safe", "Advanced")) {
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = if ($tier -eq "Safe") { "Standard" } else { "Advanced" }
    $header.FontSize = 19
    $header.FontWeight = "Bold"
    $header.Foreground = if ($tier -eq "Safe") { "#4ade80" } else { "#fb923c" }
    $header.Margin = "0,14,0,6"
    $TweaksPanel.Children.Add($header) | Out-Null

    foreach ($tweak in ($Tweaks | Where-Object { $_.Tier -eq $tier })) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = "$($tweak.Name)  -  $($tweak.Desc)"
        $cb.Foreground = "White"
        $cb.FontSize = 15
        $cb.Margin = "10,4,0,4"
        $cb.ToolTip = $tweak.Desc
        $TweaksPanel.Children.Add($cb) | Out-Null
        $TweakCheckboxes[$tweak.Name] = $cb
    }
}

# --- Populate Cleanup checklist ---
$CleanupCheckboxes = @{}
foreach ($item in $CleanupItems) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = "$($item.Name)  -  $($item.Desc)"
    $cb.Foreground = "White"
    $cb.FontSize = 15
    $cb.Margin = "10,4,0,4"
    $cb.ToolTip = $item.Desc
    $CleanupPanel.Children.Add($cb) | Out-Null
    $CleanupCheckboxes[$item.Name] = $cb
}

$BtnRunCleanup.Add_Click({
    New-SafetyRestorePoint
    foreach ($item in $CleanupItems) {
        if ($CleanupCheckboxes[$item.Name].IsChecked) {
            Write-Host "[OwaisHumayun] Cleaning: $($item.Name)" -ForegroundColor Cyan
            & $item.Apply
        }
    }
    [System.Windows.MessageBox]::Show("Cleanup finished! Your PC should have a bit more free space and run a little smoother.", "Owais Humayun")
})

# --- Button actions ---
$BtnRestore.Add_Click({
    $Window.Close()
})

$BtnApply.Add_Click({
    New-SafetyRestorePoint

    foreach ($category in $AppCategories.Keys) {
        foreach ($app in $AppCategories[$category]) {
            if ($AppCheckboxes[$app.Id].IsChecked) {
                Write-Host "[OwaisHumayun] Installing $($app.Name)..." -ForegroundColor Cyan
                # --source winget locks this to Microsoft's official, vetted app source only.
                # No --version is passed, so winget always grabs the newest available release.
                Start-Process winget -ArgumentList "install --id $($app.Id) --source winget --silent --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
            }
        }
    }

    foreach ($tweak in $Tweaks) {
        if ($TweakCheckboxes[$tweak.Name].IsChecked) {
            Write-Host "[OwaisHumayun] Applying: $($tweak.Name)" -ForegroundColor Cyan
            & $tweak.Apply
        }
    }

    [System.Windows.MessageBox]::Show("All done! Everything you checked has been installed or applied.", "Owais Humayun")
})

$Window.ShowDialog() | Out-Null
