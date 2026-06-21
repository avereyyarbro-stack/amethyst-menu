$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Dylib = Join-Path $Root "packages\inject\Amethyst.dylib"
$Ipa = "C:\Users\Averey\Downloads\War Robots Amethsyt\com.pixonic.wwr-12.1.0-Decrypted.ipa"
$Out = "C:\Users\Averey\Downloads\War Robots Amethsyt\WarRobots-Amethyst-injected.ipa"

if (-not (Test-Path $Dylib)) {
  Write-Host "Missing dylib: $Dylib"
  Write-Host "Download amethyst-deb from GitHub Actions and copy Amethyst.dylib there first."
  exit 1
}

python (Join-Path $Root "scripts\inject_ipa.py") --ipa $Ipa --dylib $Dylib --out $Out
