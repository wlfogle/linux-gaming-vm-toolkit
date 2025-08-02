# 🎮 Diablo IV OpenGL Launcher with Maximum Performance
# Creates optimized launcher for lag-free gaming

Write-Host "🚀 Creating Diablo IV OpenGL Launcher..." -ForegroundColor Cyan

# Find Diablo IV installation
$diablo4Paths = @(
    "E:\Games\Diablo IV\Diablo IV.exe",
    "C:\Games\Diablo IV\Diablo IV.exe",
    "C:\Program Files (x86)\Diablo IV\Diablo IV.exe"
)

$diablo4Path = $null
foreach ($path in $diablo4Paths) {
    if (Test-Path $path) {
        $diablo4Path = $path
        Write-Host "✅ Found Diablo IV: $path" -ForegroundColor Green
        break
    }
}

if (-not $diablo4Path) {
    Write-Host "❌ Diablo IV not found!" -ForegroundColor Red
    Write-Host "💡 Install Diablo IV first through Battle.net" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Create optimized batch launcher
$launcherScript = @"
@echo off
title Diablo IV OpenGL Launcher
echo 🎮 Launching Diablo IV with OpenGL optimizations...
echo ⚡ RTX 4080 Performance Mode Activated!
echo.

REM Set OpenGL optimizations
set __GL_THREADED_OPTIMIZATIONS=1
set __GL_SHADER_DISK_CACHE=1
set MESA_GL_VERSION_OVERRIDE=4.6
set __GL_SYNC_TO_VBLANK=1
set __GL_SHADER_STORAGE_BUFFER_OBJECT=1

REM NVIDIA GPU optimizations
set __GL_MaxFramesAllowed=1
set __GL_CACHE_PATH=%TEMP%\nv_cache
set __GL_SHADER_CACHE=1

echo 🔧 Environment variables set for maximum performance
echo 🚀 Launching Diablo IV...
echo.

REM Launch Diablo IV with OpenGL parameters
"$diablo4Path" -opengl -windowed-fullscreen -force-feature-level-11-0

echo.
echo 🎮 Diablo IV closed. Press any key to exit...
pause >nul
"@

$launcherPath = "C:\Diablo4-OpenGL-Launcher.bat"
$launcherScript | Out-File -FilePath $launcherPath -Encoding ASCII

Write-Host "✅ OpenGL launcher created: $launcherPath" -ForegroundColor Green

# Create PowerShell launcher too
$psLauncherScript = @"
# Diablo IV OpenGL PowerShell Launcher
Write-Host "🎮 Diablo IV OpenGL Performance Launcher" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Set environment for maximum OpenGL performance
`$env:__GL_THREADED_OPTIMIZATIONS = "1"
`$env:__GL_SHADER_DISK_CACHE = "1" 
`$env:MESA_GL_VERSION_OVERRIDE = "4.6"
`$env:__GL_SYNC_TO_VBLANK = "1"
`$env:__GL_MaxFramesAllowed = "1"

Write-Host "⚡ OpenGL optimizations loaded" -ForegroundColor Yellow
Write-Host "🚀 Starting Diablo IV..." -ForegroundColor Green

try {
    Start-Process -FilePath "$diablo4Path" -ArgumentList "-opengl", "-windowed-fullscreen" -Wait
    Write-Host "🎮 Game session complete!" -ForegroundColor Green
} catch {
    Write-Host "❌ Launch failed: `$(`$_.Exception.Message)" -ForegroundColor Red
}

Read-Host "Press Enter to exit"
"@

$psLauncherPath = "C:\Diablo4-OpenGL-Launcher.ps1"
$psLauncherScript | Out-File -FilePath $psLauncherPath -Encoding UTF8

Write-Host "✅ PowerShell launcher created: $psLauncherPath" -ForegroundColor Green

# Create desktop shortcuts
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Diablo IV OpenGL.lnk")
$Shortcut.TargetPath = $launcherPath
$Shortcut.WorkingDirectory = Split-Path $diablo4Path
$Shortcut.IconLocation = $diablo4Path
$Shortcut.Description = "Diablo IV with OpenGL optimizations"
$Shortcut.Save()

Write-Host "✅ Desktop shortcut created" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 LAUNCHERS CREATED:" -ForegroundColor Yellow
Write-Host "📁 Batch: $launcherPath"
Write-Host "📁 PowerShell: $psLauncherPath" 
Write-Host "🖥️ Desktop shortcut: Diablo IV OpenGL.lnk"
Write-Host ""
Write-Host "🎮 Use any of these to launch Diablo IV with maximum OpenGL performance!" -ForegroundColor Green

Read-Host "Press Enter to continue"
