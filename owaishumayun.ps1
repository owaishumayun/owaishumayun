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

# winget ships as "App Installer" - present on almost all Win10/11 PCs, but not
# guaranteed on older or heavily stripped-down installs. Check once up front so
# we can disable the Install button with a clear explanation instead of letting
# every single install silently fail.
$WingetAvailable = $null -ne (Get-Command winget -ErrorAction SilentlyContinue)

# ---------------------------------------------------------------------------
#  SAFETY: Create a restore point before anything else runs
# ---------------------------------------------------------------------------
function New-SafetyRestorePoint {
    try {
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Owais Humayun - Snapshot" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Write-Host "[OwaisHumayun] Restore point created. You can undo everything if needed." -ForegroundColor Green
        return $true
    } catch {
        Write-Host "[OwaisHumayun] Could not create a new restore point (Windows only allows one every 24h). Continuing safely." -ForegroundColor Yellow
        return $false
    }
}

# ---------------------------------------------------------------------------
#  Pumps the WPF dispatcher so a progress bar/label actually repaints while
#  we're in the middle of a blocking loop (winget/registry calls are
#  synchronous, so without this the UI would freeze until the loop ends).
# ---------------------------------------------------------------------------
function Set-Progress {
    param($Bar, $PercentText, [double]$Percent)
    $Bar.Value = $Percent
    $PercentText.Text = "$([math]::Round($Percent))%"
    $Bar.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
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

    @{ Name = "Reset Network Adapters"; Tier = "Advanced";
       Desc = "Can fix internet connection problems. Briefly disconnects you from the network.";
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
#  WPF LAYOUT - modern dark theme: rounded cards, custom buttons/checkboxes/
#  tabs/scrollbars/progress bars, big fonts, high contrast, plain language.
# ---------------------------------------------------------------------------
[xml]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Owais Humayun"
        Height="800" Width="1000" MinHeight="620" MinWidth="820"
        WindowStartupLocation="CenterScreen"
        Background="#0f172a" FontFamily="Segoe UI Variable Text, Segoe UI" FontSize="16"
        TextOptions.TextFormattingMode="Display" UseLayoutRounding="True" SnapsToDevicePixels="True">
    <Window.Resources>
        <SolidColorBrush x:Key="AccentBrush" Color="#f97316"/>
        <SolidColorBrush x:Key="AccentHoverBrush" Color="#fb923c"/>
        <SolidColorBrush x:Key="SafeBrush" Color="#4ade80"/>
        <SolidColorBrush x:Key="AdvancedBrush" Color="#fb923c"/>

        <!-- Cards -->
        <Style x:Key="TabCardStyle" TargetType="Border">
            <Setter Property="Background" Value="#16233b"/>
            <Setter Property="BorderBrush" Value="#243347"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="12"/>
            <Setter Property="Padding" Value="18"/>
            <Setter Property="Margin" Value="0,10,0,0"/>
        </Style>
        <Style x:Key="CardStyle" TargetType="Border">
            <Setter Property="Background" Value="#1e293b"/>
            <Setter Property="BorderBrush" Value="#334155"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="10"/>
            <Setter Property="Padding" Value="14"/>
            <Setter Property="Margin" Value="0,0,0,12"/>
        </Style>
        <Style x:Key="SectionHeaderStyle" TargetType="TextBlock">
            <Setter Property="FontSize" Value="18"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Margin" Value="0,0,0,8"/>
        </Style>

        <!-- Checkbox -->
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#f1f5f9"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Padding" Value="8,5,4,5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Border x:Name="RowBorder" Background="Transparent" CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <StackPanel Orientation="Horizontal">
                                <Border x:Name="Box" Width="20" Height="20" CornerRadius="5"
                                        BorderBrush="#64748b" BorderThickness="1.5" Background="#0f172a" VerticalAlignment="Center">
                                    <Path x:Name="CheckMark" Data="M3,8 L7,12 L15,3" Stroke="White" StrokeThickness="2.2"
                                          StrokeStartLineCap="Round" StrokeEndLineCap="Round" StrokeLineJoin="Round" Visibility="Collapsed"/>
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
                                <Setter TargetName="RowBorder" Property="Background" Value="#25324a"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Buttons -->
        <Style TargetType="Button">
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="FontSize" Value="15"/>
            <Setter Property="Padding" Value="18,11"/>
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
                                <Setter TargetName="Bg" Property="Background" Value="#475569"/>
                                <Setter Property="Foreground" Value="#94a3b8"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="SecondaryButtonStyle" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#334155"/>
        </Style>
        <Style x:Key="LinkButtonStyle" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="{StaticResource AccentBrush}"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="8,4"/>
        </Style>

        <!-- Progress bar -->
        <Style TargetType="ProgressBar">
            <Setter Property="Height" Value="26"/>
            <Setter Property="Minimum" Value="0"/>
            <Setter Property="Maximum" Value="100"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Grid>
                            <Border CornerRadius="13" Background="#1e293b" BorderBrush="#334155" BorderThickness="1"/>
                            <Border x:Name="PART_Track" CornerRadius="12" Margin="2" ClipToBounds="True">
                                <Grid HorizontalAlignment="Left">
                                    <Rectangle x:Name="PART_Indicator" Fill="{StaticResource AccentBrush}"
                                               HorizontalAlignment="Left" RadiusX="11" RadiusY="11"/>
                                </Grid>
                            </Border>
                        </Grid>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Tabs -->
        <Style TargetType="TabItem">
            <Setter Property="Foreground" Value="#94a3b8"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TabItem">
                        <Border x:Name="Bd" Background="Transparent" BorderThickness="0,0,0,3" BorderBrush="Transparent"
                                Padding="16,10,16,10" Margin="0,0,4,0">
                            <ContentPresenter ContentSource="Header" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsSelected" Value="True">
                                <Setter Property="Foreground" Value="White"/>
                                <Setter TargetName="Bd" Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
                                <Setter TargetName="Bd" Property="Background" Value="#16233b"/>
                            </Trigger>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="Bd" Property="Background" Value="#1b2a45"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TabControl">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="0"/>
        </Style>

        <!-- Scrollbars -->
        <Style TargetType="ScrollBar">
            <Setter Property="Width" Value="10"/>
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
                                                <Border CornerRadius="5" Background="#475569" Width="8"/>
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

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <Grid Grid.Row="0" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Border Grid.Column="0" Width="52" Height="52" CornerRadius="14" VerticalAlignment="Center">
                <Border.Background>
                    <LinearGradientBrush StartPoint="0,0" EndPoint="1,1">
                        <GradientStop Color="#f97316" Offset="0"/>
                        <GradientStop Color="#ea580c" Offset="1"/>
                    </LinearGradientBrush>
                </Border.Background>
                <TextBlock Text="OH" FontSize="20" FontWeight="Bold" Foreground="White"
                           HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <StackPanel Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                <TextBlock Text="Owais Humayun" FontSize="26" FontWeight="Bold" Foreground="White"/>
                <TextBlock Text="Simple. Safe. Free." FontSize="13" Foreground="#94a3b8"/>
            </StackPanel>
        </Grid>

        <TabControl Grid.Row="1" Name="MainTabs">
            <TabItem Header="Install Apps">
                <Border Style="{StaticResource TabCardStyle}">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <Grid Grid.Row="0" Margin="2,0,2,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" Name="TxtAppsSelectedCount" Text="0 selected" Foreground="#94a3b8" FontSize="13" VerticalAlignment="Center"/>
                            <StackPanel Grid.Column="1" Orientation="Horizontal">
                                <Button Name="BtnAppsSelectAll" Content="Select All" Style="{StaticResource LinkButtonStyle}"/>
                                <Button Name="BtnAppsClearAll" Content="Clear All" Style="{StaticResource LinkButtonStyle}" Margin="4,0,0,0"/>
                            </StackPanel>
                        </Grid>
                        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="AppsPanel" Margin="2"/>
                        </ScrollViewer>
                        <StackPanel Grid.Row="2" Margin="0,14,0,0">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Button Grid.Column="0" Name="BtnInstallApps" Content="Install Selected Apps"
                                        ToolTip="Installs every app you've ticked above via winget."/>
                                <Grid Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                                    <ProgressBar Name="PbApps"/>
                                    <TextBlock Name="TxtAppsPercent" Text="0%" Foreground="White" FontWeight="Bold" FontSize="12"
                                               HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Grid>
                            </Grid>
                            <TextBlock Name="TxtAppsStatus" Text="Tick the apps you want, then click Install."
                                       Foreground="#94a3b8" FontSize="13" Margin="0,8,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </TabItem>

            <TabItem Header="Tweaks">
                <Border Style="{StaticResource TabCardStyle}">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <Grid Grid.Row="0" Margin="2,0,2,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" Name="TxtTweaksSelectedCount" Text="0 selected" Foreground="#94a3b8" FontSize="13" VerticalAlignment="Center"/>
                            <StackPanel Grid.Column="1" Orientation="Horizontal">
                                <Button Name="BtnTweaksSelectAll" Content="Select All" Style="{StaticResource LinkButtonStyle}"/>
                                <Button Name="BtnTweaksClearAll" Content="Clear All" Style="{StaticResource LinkButtonStyle}" Margin="4,0,0,0"/>
                            </StackPanel>
                        </Grid>
                        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="TweaksPanel" Margin="2"/>
                        </ScrollViewer>
                        <StackPanel Grid.Row="2" Margin="0,14,0,0">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Button Grid.Column="0" Name="BtnApplyTweaks" Content="Apply Selected Tweaks"
                                        ToolTip="Applies every tweak you've ticked above."/>
                                <Grid Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                                    <ProgressBar Name="PbTweaks"/>
                                    <TextBlock Name="TxtTweaksPercent" Text="0%" Foreground="White" FontWeight="Bold" FontSize="12"
                                               HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Grid>
                            </Grid>
                            <TextBlock Name="TxtTweaksStatus" Text="Tick the tweaks you want, then click Apply."
                                       Foreground="#94a3b8" FontSize="13" Margin="0,8,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </TabItem>

            <TabItem Header="Clean-Up">
                <Border Style="{StaticResource TabCardStyle}">
                    <Grid>
                        <Grid.RowDefinitions>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="Auto"/>
                            <RowDefinition Height="*"/>
                            <RowDefinition Height="Auto"/>
                        </Grid.RowDefinitions>
                        <TextBlock Grid.Row="0" Text="Quick Clean-Up" Style="{StaticResource SectionHeaderStyle}"
                                   Foreground="{StaticResource SafeBrush}" Margin="2,0,0,10"/>
                        <Grid Grid.Row="1" Margin="2,0,2,10">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Grid.Column="0" Name="TxtCleanupSelectedCount" Text="0 selected" Foreground="#94a3b8" FontSize="13" VerticalAlignment="Center"/>
                            <StackPanel Grid.Column="1" Orientation="Horizontal">
                                <Button Name="BtnCleanupSelectAll" Content="Select All" Style="{StaticResource LinkButtonStyle}"/>
                                <Button Name="BtnCleanupClearAll" Content="Clear All" Style="{StaticResource LinkButtonStyle}" Margin="4,0,0,0"/>
                            </StackPanel>
                        </Grid>
                        <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                            <StackPanel Name="CleanupPanel" Margin="2"/>
                        </ScrollViewer>
                        <StackPanel Grid.Row="3" Margin="0,14,0,0">
                            <Grid>
                                <Grid.ColumnDefinitions>
                                    <ColumnDefinition Width="Auto"/>
                                    <ColumnDefinition Width="*"/>
                                </Grid.ColumnDefinitions>
                                <Button Grid.Column="0" Name="BtnRunCleanup" Content="Run Cleanup"
                                        ToolTip="Runs every cleanup item you've ticked above."/>
                                <Grid Grid.Column="1" Margin="14,0,0,0" VerticalAlignment="Center">
                                    <ProgressBar Name="PbCleanup"/>
                                    <TextBlock Name="TxtCleanupPercent" Text="0%" Foreground="White" FontWeight="Bold" FontSize="12"
                                               HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Grid>
                            </Grid>
                            <TextBlock Name="TxtCleanupStatus" Text="Tick what you'd like to clean, then click Run Cleanup."
                                       Foreground="#94a3b8" FontSize="13" Margin="0,8,0,0" TextWrapping="Wrap"/>
                        </StackPanel>
                    </Grid>
                </Border>
            </TabItem>

            <TabItem Header="About">
                <Border Style="{StaticResource TabCardStyle}">
                    <StackPanel>
                        <TextBlock Text="Owais Humayun" FontSize="22" FontWeight="Bold" Foreground="White"/>
                        <TextBlock Text="Built with care, shared with everyone - free and open-source." Foreground="White" Margin="0,10,0,0" FontSize="16" TextWrapping="Wrap"/>
                        <TextBlock Text="This open source tool is designed by Owais Humayun." Foreground="White" Margin="0,10,0,0" FontSize="16" TextWrapping="Wrap"/>
                        <TextBlock Text="This tool only installs apps through winget (Microsoft's Official Installer) and only changes settings you choose." Foreground="#cbd5e1" Margin="0,15,0,0" FontSize="15" TextWrapping="Wrap"/>
                        <Border Style="{StaticResource CardStyle}" Margin="0,20,0,0">
                            <StackPanel>
                                <TextBlock Text="Restore Point Safety Net" Style="{StaticResource SectionHeaderStyle}" Foreground="{StaticResource SafeBrush}"/>
                                <TextBlock Text="A System Restore Point is created automatically before any install, tweak, or cleanup. You can also make one manually right now."
                                           Foreground="#cbd5e1" FontSize="14" TextWrapping="Wrap" Margin="0,0,0,12"/>
                                <Button Name="BtnCreateRestorePoint" Content="Create Restore Point Now" HorizontalAlignment="Left"
                                        ToolTip="Creates a System Restore Point you can roll back to later."/>
                                <TextBlock Name="TxtRestoreStatus" Text="" Foreground="#94a3b8" FontSize="13" Margin="0,10,0,0" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>
                    </StackPanel>
                </Border>
            </TabItem>
        </TabControl>

        <Grid Grid.Row="2" Margin="0,14,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Text="A System Restore Point is created automatically before any change is made."
                       Foreground="#64748b" FontSize="12" VerticalAlignment="Center" TextWrapping="Wrap"/>
            <Button Grid.Column="1" Name="BtnClose" Content="Close" Style="{StaticResource SecondaryButtonStyle}"
                    ToolTip="Closes the window."/>
        </Grid>
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

$AppsPanel            = $Window.FindName("AppsPanel")
$TweaksPanel          = $Window.FindName("TweaksPanel")
$CleanupPanel         = $Window.FindName("CleanupPanel")
$BtnInstallApps       = $Window.FindName("BtnInstallApps")
$BtnApplyTweaks       = $Window.FindName("BtnApplyTweaks")
$BtnRunCleanup        = $Window.FindName("BtnRunCleanup")
$BtnCreateRestorePoint = $Window.FindName("BtnCreateRestorePoint")
$BtnClose             = $Window.FindName("BtnClose")
$PbApps               = $Window.FindName("PbApps")
$PbTweaks             = $Window.FindName("PbTweaks")
$PbCleanup            = $Window.FindName("PbCleanup")
$TxtAppsPercent       = $Window.FindName("TxtAppsPercent")
$TxtTweaksPercent     = $Window.FindName("TxtTweaksPercent")
$TxtCleanupPercent    = $Window.FindName("TxtCleanupPercent")
$TxtAppsStatus        = $Window.FindName("TxtAppsStatus")
$TxtTweaksStatus      = $Window.FindName("TxtTweaksStatus")
$TxtCleanupStatus     = $Window.FindName("TxtCleanupStatus")
$TxtRestoreStatus     = $Window.FindName("TxtRestoreStatus")
$TxtAppsSelectedCount    = $Window.FindName("TxtAppsSelectedCount")
$TxtTweaksSelectedCount  = $Window.FindName("TxtTweaksSelectedCount")
$TxtCleanupSelectedCount = $Window.FindName("TxtCleanupSelectedCount")
$BtnAppsSelectAll     = $Window.FindName("BtnAppsSelectAll")
$BtnAppsClearAll      = $Window.FindName("BtnAppsClearAll")
$BtnTweaksSelectAll   = $Window.FindName("BtnTweaksSelectAll")
$BtnTweaksClearAll    = $Window.FindName("BtnTweaksClearAll")
$BtnCleanupSelectAll  = $Window.FindName("BtnCleanupSelectAll")
$BtnCleanupClearAll   = $Window.FindName("BtnCleanupClearAll")

if (-not $WingetAvailable) {
    $BtnInstallApps.IsEnabled = $false
    $TxtAppsStatus.Text = "winget isn't available on this PC. Install 'App Installer' from the Microsoft Store, then reopen this tool to install apps."
}

# --- Small helper: builds a rounded "card" with a colored header, returns the card and its inner stack ---
function New-Card {
    param([string]$HeaderText, [string]$HeaderColor)
    $border = New-Object System.Windows.Controls.Border
    $border.Style = $Window.FindResource("CardStyle")
    $stack = New-Object System.Windows.Controls.StackPanel
    $header = New-Object System.Windows.Controls.TextBlock
    $header.Text = $HeaderText
    $header.Style = $Window.FindResource("SectionHeaderStyle")
    $header.Foreground = $HeaderColor
    $stack.Children.Add($header) | Out-Null
    $border.Child = $stack
    return [pscustomobject]@{ Border = $border; Stack = $stack }
}

# --- Keeps each tab's "N selected" label in sync with its checkboxes ---
function Update-SelectionCount {
    param($Checkboxes, $CountText)
    $count = @($Checkboxes.Values | Where-Object { $_.IsChecked }).Count
    $CountText.Text = "$count selected"
}

# --- Builds a wrapping text label for a checkbox's Content (a plain string won't wrap) ---
function New-CheckboxLabel {
    param([string]$Text)
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.TextWrapping = "Wrap"
    return $tb
}

# --- Populate Apps, grouped by category with card-style headers ---
$AppCheckboxes = @{}
foreach ($category in $AppCategories.Keys) {
    $card = New-Card -HeaderText $category -HeaderColor "#f97316"
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

# --- Populate Tweaks, Safe first then Advanced, each in its own card ---
$TweakCheckboxes = @{}
foreach ($tier in @("Safe", "Advanced")) {
    $tierLabel = if ($tier -eq "Safe") { "Standard" } else { "Advanced" }
    $tierColor = if ($tier -eq "Safe") { "#4ade80" } else { "#fb923c" }
    $card = New-Card -HeaderText $tierLabel -HeaderColor $tierColor
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

# --- Populate Cleanup checklist ---
$CleanupCheckboxes = @{}
foreach ($item in $CleanupItems) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = New-CheckboxLabel "$($item.Name)  -  $($item.Desc)"
    $cb.ToolTip = $item.Desc
    $cb.Margin = "10,4,0,4"
    $cb.Add_Checked({ Update-SelectionCount -Checkboxes $CleanupCheckboxes -CountText $TxtCleanupSelectedCount })
    $cb.Add_Unchecked({ Update-SelectionCount -Checkboxes $CleanupCheckboxes -CountText $TxtCleanupSelectedCount })
    $CleanupPanel.Children.Add($cb) | Out-Null
    $CleanupCheckboxes[$item.Name] = $cb
}

# --- Select All / Clear All ---
$BtnAppsSelectAll.Add_Click({ $AppCheckboxes.Values | ForEach-Object { $_.IsChecked = $true } })
$BtnAppsClearAll.Add_Click({ $AppCheckboxes.Values | ForEach-Object { $_.IsChecked = $false } })
$BtnTweaksSelectAll.Add_Click({ $TweakCheckboxes.Values | ForEach-Object { $_.IsChecked = $true } })
$BtnTweaksClearAll.Add_Click({ $TweakCheckboxes.Values | ForEach-Object { $_.IsChecked = $false } })
$BtnCleanupSelectAll.Add_Click({ $CleanupCheckboxes.Values | ForEach-Object { $_.IsChecked = $true } })
$BtnCleanupClearAll.Add_Click({ $CleanupCheckboxes.Values | ForEach-Object { $_.IsChecked = $false } })

# --- Install Selected Apps ---
$BtnInstallApps.Add_Click({
    if (-not $WingetAvailable) {
        [System.Windows.MessageBox]::Show("winget isn't available on this PC. Install 'App Installer' from the Microsoft Store, then try again.", "Owais Humayun")
        return
    }
    $selected = @()
    foreach ($category in $AppCategories.Keys) {
        foreach ($app in $AppCategories[$category]) {
            if ($AppCheckboxes[$app.Id].IsChecked) { $selected += $app }
        }
    }
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Tick at least one app first.", "Owais Humayun")
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
        Write-Host "[OwaisHumayun] Installing $($app.Name)..." -ForegroundColor Cyan
        try {
            # --source winget locks this to Microsoft's official, vetted app source only.
            # No --version is passed, so winget always grabs the newest available release.
            $proc = Start-Process winget -ArgumentList "install --id $($app.Id) --source winget --silent --accept-package-agreements --accept-source-agreements" -Wait -NoNewWindow -PassThru
            if ($proc.ExitCode -ne 0) {
                $failed += $app.Name
                Write-Host "[OwaisHumayun] $($app.Name) exited with code $($proc.ExitCode)" -ForegroundColor Yellow
            }
        } catch {
            $failed += $app.Name
            Write-Host "[OwaisHumayun] Failed to install $($app.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        Set-Progress -Bar $PbApps -PercentText $TxtAppsPercent -Percent (($i / $selected.Count) * 100)
    }

    $succeeded = $selected.Count - $failed.Count
    if ($failed.Count -eq 0) {
        $TxtAppsStatus.Text = "Done! Installed $succeeded app$(if ($succeeded -ne 1) { 's' })."
        [System.Windows.MessageBox]::Show("Finished installing $succeeded app(s).", "Owais Humayun")
    } else {
        $TxtAppsStatus.Text = "Installed $succeeded of $($selected.Count). Couldn't install: $($failed -join ', ')."
        [System.Windows.MessageBox]::Show("Installed $succeeded of $($selected.Count) app(s).`n`nCouldn't install: $($failed -join ', ')`n`nCheck the console window for details.", "Owais Humayun")
    }
    $BtnInstallApps.IsEnabled = $true
})

# --- Apply Selected Tweaks ---
$BtnApplyTweaks.Add_Click({
    $selected = @($Tweaks | Where-Object { $TweakCheckboxes[$_.Name].IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Tick at least one tweak first.", "Owais Humayun")
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
        Write-Host "[OwaisHumayun] Applying: $($tweak.Name)" -ForegroundColor Cyan
        try {
            & $tweak.Apply
        } catch {
            $failed += $tweak.Name
            Write-Host "[OwaisHumayun] Failed to apply $($tweak.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        Set-Progress -Bar $PbTweaks -PercentText $TxtTweaksPercent -Percent (($i / $selected.Count) * 100)
    }

    $succeeded = $selected.Count - $failed.Count
    if ($failed.Count -eq 0) {
        $TxtTweaksStatus.Text = "Done! Applied $succeeded tweak$(if ($succeeded -ne 1) { 's' })."
        [System.Windows.MessageBox]::Show("Applied $succeeded tweak(s).", "Owais Humayun")
    } else {
        $TxtTweaksStatus.Text = "Applied $succeeded of $($selected.Count). Couldn't apply: $($failed -join ', ')."
        [System.Windows.MessageBox]::Show("Applied $succeeded of $($selected.Count) tweak(s).`n`nCouldn't apply: $($failed -join ', ')`n`nCheck the console window for details.", "Owais Humayun")
    }
    $BtnApplyTweaks.IsEnabled = $true
})

# --- Run Cleanup ---
$BtnRunCleanup.Add_Click({
    $selected = @($CleanupItems | Where-Object { $CleanupCheckboxes[$_.Name].IsChecked })
    if ($selected.Count -eq 0) {
        [System.Windows.MessageBox]::Show("Tick at least one cleanup item first.", "Owais Humayun")
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
        Write-Host "[OwaisHumayun] Cleaning: $($item.Name)" -ForegroundColor Cyan
        try {
            & $item.Apply
        } catch {
            $failed += $item.Name
            Write-Host "[OwaisHumayun] Failed to clean $($item.Name): $($_.Exception.Message)" -ForegroundColor Red
        }
        Set-Progress -Bar $PbCleanup -PercentText $TxtCleanupPercent -Percent (($i / $selected.Count) * 100)
    }

    $succeeded = $selected.Count - $failed.Count
    if ($failed.Count -eq 0) {
        $TxtCleanupStatus.Text = "Done! Cleaned $succeeded item$(if ($succeeded -ne 1) { 's' })."
        [System.Windows.MessageBox]::Show("Cleanup finished! Your PC should have a bit more free space and run a little smoother.", "Owais Humayun")
    } else {
        $TxtCleanupStatus.Text = "Cleaned $succeeded of $($selected.Count). Couldn't clean: $($failed -join ', ')."
        [System.Windows.MessageBox]::Show("Cleaned $succeeded of $($selected.Count) item(s).`n`nCouldn't clean: $($failed -join ', ')`n`nCheck the console window for details.", "Owais Humayun")
    }
    $BtnRunCleanup.IsEnabled = $true
})

# --- Manual restore point button (About tab) ---
$BtnCreateRestorePoint.Add_Click({
    $BtnCreateRestorePoint.IsEnabled = $false
    $TxtRestoreStatus.Text = "Creating restore point..."
    $TxtRestoreStatus.Dispatcher.Invoke([Windows.Threading.DispatcherPriority]::Background, [action]{})
    $ok = New-SafetyRestorePoint
    if ($ok) {
        $TxtRestoreStatus.Text = "Restore point created. You're safe to make changes."
    } else {
        $TxtRestoreStatus.Text = "Windows only allows one restore point every 24 hours - you likely already have a recent one."
    }
    $BtnCreateRestorePoint.IsEnabled = $true
})

# --- Close ---
$BtnClose.Add_Click({
    $Window.Close()
})

$Window.ShowDialog() | Out-Null
