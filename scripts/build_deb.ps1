# Build Amethyst .deb on Windows
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $Root
python scripts/build_deb.py
Write-Host ""
Write-Host "Install on jailbroken device:"
Write-Host "  dpkg -i packages/com.amethyst.menu_1.0.0_iphoneos-arm64.deb"
Write-Host ""
Write-Host "For IPA injection, use files in packages/inject/:"
Write-Host "  Amethyst.dylib + Amethyst.plist"
