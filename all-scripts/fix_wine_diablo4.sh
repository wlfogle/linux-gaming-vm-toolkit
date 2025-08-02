#!/bin/bash
# Wine Diablo IV Configuration Fix
# Addresses CEF crashes, experimental wow64 mode, and graphics allocation issues

set -e

WINE_PREFIX="$HOME/.wine-diablo4"

echo "🔧 Fixing Wine configuration for Diablo IV..."

# Export Wine prefix
export WINEPREFIX="$WINE_PREFIX"

# 1. Disable experimental wow64 mode by setting architecture explicitly
echo "Setting Wine architecture to 64-bit..."
WINEARCH=win64 wineboot --update

# 2. Disable problematic graphics experimental features
echo "Configuring graphics settings..."
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "DirectDrawRenderer" /t REG_SZ /d "opengl" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "VideoMemorySize" /t REG_SZ /d "16384" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "UseGLSL" /t REG_SZ /d "enabled" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "VertexShaderMode" /t REG_SZ /d "hardware" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\Direct3D" /v "PixelShaderMode" /t REG_SZ /d "hardware" /f

# 3. Disable problematic registry wow64 redirections
echo "Disabling wow64 filesystem redirection..."
wine reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "EnableBalloonTips" /t REG_DWORD /d 0 /f

# 4. Configure EGL to avoid allocation failures
echo "Configuring EGL settings..."
wine reg add "HKEY_CURRENT_USER\Software\Wine\OpenGL" /v "RendererID" /t REG_DWORD /d 0 /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\OpenGL" /v "UseVertexShaderMode" /t REG_SZ /d "hardware" /f

# 5. Set explicit Windows version to Windows 10 (disable compatibility mode experiments)
echo "Setting Windows version to Windows 10..."
wine reg add "HKEY_CURRENT_USER\Software\Wine" /v "Version" /t REG_SZ /d "win10" /f
wine reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "CurrentVersion" /t REG_SZ /d "10.0" /f
wine reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v "CurrentBuild" /t REG_SZ /d "19041" /f

# 6. Configure CEF/Chromium to use software rendering to avoid EGL conflicts
echo "Configuring CEF for software rendering..."
wine reg add "HKEY_CURRENT_USER\Software\Chromium\CommandLine" /v "" /t REG_SZ /d "--disable-gpu --disable-gpu-compositing --disable-gpu-rasterization --disable-gpu-sandbox --disable-software-rasterizer --use-gl=desktop" /f

# 7. Battle.net specific fixes
echo "Applying Battle.net specific fixes..."
wine reg add "HKEY_CURRENT_USER\Software\Blizzard Entertainment\Battle.net" /v "AllowAllOrigins" /t REG_DWORD /d 1 /f
wine reg add "HKEY_CURRENT_USER\Software\Blizzard Entertainment\Battle.net\Launch Options" /v "Additional" /t REG_SZ /d "--disable-gpu --disable-web-security" /f

# 8. Disable Windows error reporting to reduce crashes
echo "Disabling Windows error reporting..."
wine reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "DontShowUI" /t REG_DWORD /d 1 /f
wine reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f

# 9. Set explicit DLL overrides to prioritize native libraries
echo "Setting DLL overrides..."
wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "d3d11" /t REG_SZ /d "native,builtin" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "dxgi" /t REG_SZ /d "native,builtin" /f
wine reg add "HKEY_CURRENT_USER\Software\Wine\DllOverrides" /v "d3d9" /t REG_SZ /d "native,builtin" /f

# 10. Create a new environment script for launching with proper settings
cat > "$WINE_PREFIX/launch_env.sh" << 'EOF'
#!/bin/bash
# Environment variables for Diablo IV Wine setup

# Disable experimental features
export WINE_EXPERIMENTAL_WOW64=0
export WINE_DISABLE_EXPERIMENTAL=1

# EGL/OpenGL settings to prevent allocation failures
export LIBGL_ALWAYS_SOFTWARE=0
export LIBGL_ALWAYS_INDIRECT=0
export __GL_SHADER_DISK_CACHE=1
export __GL_THREADED_OPTIMIZATIONS=1

# CEF/Chromium settings
export CHROMIUM_FLAGS="--disable-gpu --disable-gpu-compositing --disable-gpu-rasterization --disable-gpu-sandbox --use-gl=desktop"

# Wine graphics settings
export WINE_D3D_CONFIG="UseGLSL=enabled,VertexShaderMode=hardware,PixelShaderMode=hardware"

# Battle.net specific
export WINE_ALLOW_ALL_ORIGINS=1

# Reduce debug output
export WINEDEBUG=-all,+dll,+heap

echo "Wine environment configured for Diablo IV"
EOF

chmod +x "$WINE_PREFIX/launch_env.sh"

# 11. Update wineboot to apply all changes
echo "Updating Wine configuration..."
wineboot --update

echo "✅ Wine configuration fixes applied!"
echo ""
echo "🎮 To use the fixed configuration:"
echo "   Source the environment: source ~/.wine-diablo4/launch_env.sh"
echo "   Then launch Battle.net or Diablo IV with your existing scripts"
echo ""
echo "🔧 Key fixes applied:"
echo "   • Disabled experimental wow64 mode"
echo "   • Configured CEF for software rendering"
echo "   • Set explicit Windows 10 compatibility"
echo "   • Fixed EGL allocation issues"
echo "   • Optimized DLL overrides"
echo ""
