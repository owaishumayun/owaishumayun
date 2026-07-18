#Requires -RunAsAdministrator
<#
    Owais Humayun
    Install Programs, Tweaks, Fixes, and Updates for Windows 10/11
    Designed to be usable by anyone - from kids to grandparents.
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
        @{ Name = "Discord";            Id = "Discord.Discord";            Desc = "Chat app popular with gamers and communities." }
        @{ Name = "Skype";              Id = "Microsoft.Skype";            Desc = "Classic video calling app." }
    )
    "Music and Video" = @(
        @{ Name = "VLC Media Player";   Id = "VideoLAN.VLC";               Desc = "Plays almost any video or audio file." }
        @{ Name = "Spotify";            Id = "Spotify.Spotify";            Desc = "Stream and listen to music." }
        @{ Name = "OBS Studio";         Id = "OBSProject.OBSStudio";       Desc = "Record your screen or stream online." }
    )
    "Everyday Tools" = @(
        @{ Name = "7-Zip";              Id = "7zip.7zip";                  Desc = "Open zip files and compress your own." }
        @{ Name = "Adobe Acrobat Reader"; Id = "Adobe.Acrobat.Reader.64-bit"; Desc = "Open and read PDF files." }
        @{ Name = "PowerToys";          Id = "Microsoft.PowerToys";        Desc = "Handy extra tools made by Microsoft." }
        @{ Name = "Notepad++";          Id = "Notepad++.Notepad++";        Desc = "A simple, powerful text editor." }
        @{ Name = "ShareX";             Id = "ShareX.ShareX";              Desc = "Take and save screenshots easily." }
    )
    "Developer Tools" = @(
        @{ Name = "Visual Studio Code"; Id = "Microsoft.VisualStudioCode"; Desc = "Popular code editor for programmers." }
        @{ Name = "Git";                Id = "Git.Git";                    Desc = "Tool for tracking changes in code projects." }
        @{ Name = "Python";             Id = "Python.Python.3.12";        Desc = "Programming language, great for beginners." }
        @{ Name = "Node.js";            Id = "OpenJS.NodeJS.LTS";          Desc = "Runs JavaScript outside of a web browser." }
        @{ Name = "Docker Desktop";     Id = "Docker.DockerDesktop";       Desc = "Run apps in isolated containers." }
    )
    "Security and Privacy" = @(
        @{ Name = "Malwarebytes";       Id = "Malwarebytes.Malwarebytes"; Desc = "Scans and removes malware." }
        @{ Name = "Bitwarden";          Id = "Bitwarden.Bitwarden";        Desc = "Free password manager, keeps passwords safe." }
    )
    "Gaming" = @(
        @{ Name = "Steam";              Id = "Valve.Steam";                Desc = "Store for buying and playing PC games." }
        @{ Name = "Epic Games Launcher"; Id = "EpicGames.EpicGamesLauncher"; Desc = "Store for Epic Games titles, incl. Fortnite." }
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

    @{ Name = "Empty the Recycle Bin"; Desc = "Permanently deletes everything currently in the Recycle Bin.";
       Apply = { Clear-RecycleBin -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Windows Update Leftovers"; Desc = "Frees up a lot of space by deleting old, already-installed update files."; 
       Apply = {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
       } }

    @{ Name = "Clear Thumbnail Cache"; Desc = "Clears cached picture previews - Windows regenerates them next time you browse folders.";
       Apply = { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Clear Browser/System Internet Cache"; Desc = "Clears cached web files stored by Windows components.";
       Apply = { Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue } }

    @{ Name = "Flush DNS Cache"; Desc = "Clears stored website addresses - can fix websites failing to load."; 
       Apply = { Start-Process ipconfig -ArgumentList "/flushdns" -Wait -NoNewWindow } }
)

# ---------------------------------------------------------------------------
#  DIAGNOSTIC TOOLS - heavier one-off jobs, run individually with their own
#  button since they take longer, print their own output, or need a restart.
# ---------------------------------------------------------------------------
$DiagnosticTools = @(
    @{ Name = "Open Disk Cleanup Tool"; Desc = "Opens Windows' built-in Disk Cleanup window so you can pick what to remove.";
       Confirm = $false;
       Action = { Start-Process cleanmgr -ArgumentList "/d $env:SystemDrive" } }

    @{ Name = "Scan and Repair System Files (SFC)"; Desc = "Checks Windows system files for corruption and repairs them. Takes several minutes.";
       Confirm = $false;
       Action = { Start-Process powershell -ArgumentList "-NoExit","-Command","sfc /scannow" -Verb RunAs } }

    @{ Name = "Check Disk for Errors (restart required)"; Desc = "Schedules a disk error check on your next restart. Your PC will restart to run it - save your work first!";
       Confirm = $true;
       Action = { Start-Process powershell -ArgumentList "-NoExit","-Command","chkdsk C: /f /r" -Verb RunAs } }

    @{ Name = "Show Startup Programs"; Desc = "Lists the apps that automatically start when Windows boots up.";
       Confirm = $false;
       Action = {
            $items = Get-CimInstance Win32_StartupCommand | Select-Object Name, Command, Location
            $text = ($items | Format-Table -AutoSize | Out-String)
            [System.Windows.MessageBox]::Show($text, "Startup Programs")
       } }

    @{ Name = "Defragment Drive (HDD only - skip for SSD)"; Desc = "Reorganizes files on a spinning hard drive for faster access. Do NOT run this on an SSD.";
       Confirm = $true;
       Action = { Start-Process powershell -ArgumentList "-NoExit","-Command","defrag C: /O" -Verb RunAs } }

    @{ Name = "Clean Up Windows Component Store"; Desc = "Removes old, unneeded versions of system files left behind by updates. Frees disk space.";
       Confirm = $false;
       Action = { Start-Process Dism.exe -ArgumentList "/online","/Cleanup-Image","/StartComponentCleanup" -Verb RunAs -Wait } }
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
                <TextBlock Text="Simple. Safe. Free for everyone - kids to grandparents." FontSize="14" Foreground="#f97316"/>
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
            <TabItem Header="Cleanup and Repair">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="12">
                        <TextBlock Text="Quick Cleanup (safe, reversible - Windows rebuilds all of this automatically)"
                                   FontSize="19" FontWeight="Bold" Foreground="#4ade80" Margin="0,4,0,6" TextWrapping="Wrap"/>
                        <StackPanel Name="CleanupPanel"/>
                        <Button Name="BtnRunCleanup" Content="Run Selected Cleanup" Padding="14,8" Margin="0,10,0,20"
                                FontSize="16" FontWeight="Bold" HorizontalAlignment="Left"
                                ToolTip="Runs every cleanup item you've ticked above."/>

                        <TextBlock Text="Deeper Repair Tools (run one at a time, each explains itself)"
                                   FontSize="19" FontWeight="Bold" Foreground="#fb923c" Margin="0,4,0,6" TextWrapping="Wrap"/>
                        <StackPanel Name="DiagnosticsPanel"/>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
            <TabItem Header="Updates">
                <StackPanel Margin="20">
                    <TextBlock Text="Windows sometimes needs a break from installing updates while you finish something important."
                               TextWrapping="Wrap" Foreground="White" Margin="0,0,0,15" FontSize="16"/>
                    <Button Name="BtnDisableUpdates" Content="Pause Updates for 35 Days" Margin="0,6" Padding="12" FontSize="16"
                            ToolTip="Windows will not install new updates for 35 days."/>
                    <Button Name="BtnEnableUpdates" Content="Turn Updates Back On" Margin="0,6" Padding="12" FontSize="16"
                            ToolTip="Restores normal automatic updates. Do this once you're ready!"/>
                </StackPanel>
            </TabItem>
            <TabItem Header="About">
                <StackPanel Margin="20">
                    <TextBlock Text="Owais Humayun" FontSize="22" FontWeight="Bold" Foreground="White"/>
                    <TextBlock Text="Free and open-source, forever." Foreground="White" Margin="0,10,0,0" FontSize="16" TextWrapping="Wrap"/>
                    <TextBlock Text="This tool only installs apps through winget (Microsoft's official installer) and only changes settings you choose. A restore point is made automatically, so you can always undo everything." Foreground="#cbd5e1" Margin="0,15,0,0" FontSize="15" TextWrapping="Wrap"/>
                </StackPanel>
            </TabItem>
        </TabControl>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,14,0,0">
            <Button Name="BtnApply" Content="Apply Everything I Checked" Padding="16,10" Margin="6" FontSize="17" FontWeight="Bold"
                    ToolTip="Installs the apps and applies the tweaks you ticked."/>
            <Button Name="BtnRestorePoint" Content="Make a Safety Backup Point" Padding="16,10" Margin="6" FontSize="17"
                    ToolTip="Creates a Windows Restore Point so you can undo changes later."/>
        </StackPanel>
    </Grid>
</Window>
"@

$Reader = New-Object System.Xml.XmlNodeReader $Xaml
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$AppsPanel        = $Window.FindName("AppsPanel")
$TweaksPanel      = $Window.FindName("TweaksPanel")
$CleanupPanel     = $Window.FindName("CleanupPanel")
$DiagnosticsPanel = $Window.FindName("DiagnosticsPanel")
$BtnApply         = $Window.FindName("BtnApply")
$BtnRestore       = $Window.FindName("BtnRestorePoint")
$BtnPause         = $Window.FindName("BtnDisableUpdates")
$BtnResume        = $Window.FindName("BtnEnableUpdates")
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
    $header.Text = if ($tier -eq "Safe") { "Recommended for Everyone" } else { "Advanced (know what you're doing)" }
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

# --- Populate Diagnostic tool buttons (one-off actions, not checkboxes) ---
foreach ($tool in $DiagnosticTools) {
    $panel = New-Object System.Windows.Controls.StackPanel
    $panel.Orientation = "Horizontal"
    $panel.Margin = "0,6,0,6"

    $btn = New-Object System.Windows.Controls.Button
    $btn.Content = $tool.Name
    $btn.Padding = "10,6"
    $btn.FontSize = 15
    $btn.ToolTip = $tool.Desc
    $btn.Tag = $tool

    $btn.Add_Click({
        param($sender, $e)
        $t = $sender.Tag
        $proceed = $true
        if ($t.Confirm) {
            $result = [System.Windows.MessageBox]::Show("$($t.Desc)`n`nDo you want to continue?", "Please Confirm", "YesNo", "Warning")
            $proceed = ($result -eq "Yes")
        }
        if ($proceed) {
            Write-Host "[OwaisHumayun] Running: $($t.Name)" -ForegroundColor Cyan
            & $t.Action
        }
    })

    $desc = New-Object System.Windows.Controls.TextBlock
    $desc.Text = $tool.Desc
    $desc.Foreground = "#cbd5e1"
    $desc.FontSize = 13
    $desc.VerticalAlignment = "Center"
    $desc.Margin = "12,0,0,0"
    $desc.TextWrapping = "Wrap"
    $desc.MaxWidth = 550

    $panel.Children.Add($btn) | Out-Null
    $panel.Children.Add($desc) | Out-Null
    $DiagnosticsPanel.Children.Add($panel) | Out-Null
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
    New-SafetyRestorePoint
    [System.Windows.MessageBox]::Show("A safety backup point was created. If anything goes wrong, you can restore your PC to this moment.", "Owais Humayun")
})

$BtnApply.Add_Click({
    New-SafetyRestorePoint

    foreach ($category in $AppCategories.Keys) {
        foreach ($app in $AppCategories[$category]) {
            if ($AppCheckboxes[$app.Id].IsChecked) {
                Write-Host "[OwaisHumayun] Installing $($app.Name)..." -ForegroundColor Cyan
                Start-Process winget -ArgumentList "install --id $($app.Id) --silent --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow
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

$BtnPause.Add_Click({
    $date = (Get-Date).AddDays(35).ToString("yyyy-MM-dd")
    New-Item -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -Value $date -Force
    [System.Windows.MessageBox]::Show("Updates are paused until $date. Don't forget to turn them back on!", "Owais Humayun")
})

$BtnResume.Add_Click({
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
    [System.Windows.MessageBox]::Show("Updates are back to normal. Your PC will stay up to date.", "Owais Humayun")
})

$Window.ShowDialog() | Out-Null
