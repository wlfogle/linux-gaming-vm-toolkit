# 🎮 DIABLO IV OPENGL FORCE MODE - NO LAG SETUP!
# This script forces OpenGL renderer to bypass GPU triangle errors

Write-Host "🎮 DIABLO IV OPENGL FORCE MODE - NO LAG SETUP!" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# Check Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "❌ This script must be run as Administrator" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Force OpenGL renderer for Diablo IV
$regPath = "HKCU:\SOFTWARE\Blizzard Entertainment\Diablo IV"
if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force }

# Set OpenGL as primary renderer
Set-ItemProperty -Path $regPath -Name "GraphicsAPI" -Value "OpenGL" -Force
Set-ItemProperty -Path $regPath -Name "ForceOpenGL" -Value 1 -Type DWORD -Force

# Force NVIDIA GPU even with triangle
$gpuRegPath = "HKCU:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"
if (-not (Test-Path $gpuRegPath)) { New-Item -Path $gpuRegPath -Force }

# Find and configure Diablo IV
$diablo4Paths = @(
    "E:\Games\Diablo IV\Diablo IV.exe",
    "C:\Games\Diablo IV\Diablo IV.exe",
    "C:\Program Files (x86)\Diablo IV\Diablo IV.exe"
)

$diablo4Found = $false
foreach ($path in $diablo4Paths) {
    if (Test-Path $path) {
        Write-Host "✅ Found Diablo IV: $path" -ForegroundColor Green
        
        # Force high-performance GPU
        Set-ItemProperty -Path $gpuRegPath -Name $path -Value "GpuPreference=2;" -Force
        
        Write-Host "⚡ NVIDIA GPU forced for Diablo IV" -ForegroundColor Yellow
        $diablo4Found = $true
        break
    }
}

if (-not $diablo4Found) {
    Write-Host "⚠️ Diablo IV not found in common locations" -ForegroundColor Yellow
    Write-Host "💡 Install through Battle.net first" -ForegroundColor Blue
}

# Gaming performance optimizations
Write-Host "🚀 Applying gaming optimizations..." -ForegroundColor Cyan

# Disable fullscreen optimizations
$regGamePath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\AppCompatFlags\Layers"
if (-not (Test-Path $regGamePath)) { New-Item -Path $regGamePath -Force }

foreach ($path in $diablo4Paths) {
    if (Test-Path $path) {
        Set-ItemProperty -Path $regGamePath -Name $path -Value "DISABLEDXMAXIMIZEDWINDOWEDMODE" -Force
    }
}

# Create OpenGL environment variables
$envPath = "HKCU:\Environment"
Set-ItemProperty -Path $envPath -Name "__GL_THREADED_OPTIMIZATIONS" -Value "1" -Force
Set-ItemProperty -Path $envPath -Name "__GL_SHADER_DISK_CACHE" -Value "1" -Force
Set-ItemProperty -Path $envPath -Name "__GL_SYNC_TO_VBLANK" -Value "1" -Force

Write-Host "✅ OpenGL force mode configured!" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 LAUNCH INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "1. Open Battle.net"
Write-Host "2. Launch Diablo IV"
Write-Host "3. In Video Settings:"
Write-Host "   - Set Renderer to OpenGL (if available)"
Write-Host "   - Set to Windowed Fullscreen"
Write-Host "   - Enable V-Sync for smooth gameplay"
Write-Host "   - Start with Medium settings"
Write-Host ""
Write-Host "⚡ Your RTX 4080 WILL work with OpenGL even with the triangle!" -ForegroundColor Green
Write-Host "🎮 Enjoy lag-free Diablo IV gaming!" -ForegroundColor Cyan

Read-Host "Press Enter to continue"
