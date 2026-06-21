# Amethyst

Informational overlay mod menu for **War Robots**, styled after the [bus next-gen](https://bus.anotheraxiom.org) aesthetic.

This package ships **UI-only toggles** that persist settings locally. It does **not** include game memory hooks, currency mods, or combat cheats.

## Mods

| Toggle | Description |
|--------|-------------|
| **enemy team health numbers** | Display numeric HP above enemy robots |
| **anaksor invisibility highlight** | Outline Anaksor while stealth is active |

> These toggles save preferences to `NSUserDefaults`. Wiring them to in-game rendering requires separate reverse-engineering work and is not included here.

## Preview (Windows / any browser)

Open the web mockup:

```
C:\Users\Averey\amethyst-menu\preview\index.html
```

Double-click the file or drag it into a browser. Toggles persist via `localStorage`.

## Build (.deb)

### Windows (package now)

```powershell
cd C:\Users\Averey\amethyst-menu
python scripts\build_deb.py
```

Output:

```
packages/com.amethyst.menu_1.0.0_iphoneos-arm64.deb
packages/inject/Amethyst.dylib
packages/inject/Amethyst.plist
```

A copy is also placed in your War Robots folder:

```
C:\Users\Averey\Downloads\War Robots Amethsyt\com.amethyst.menu_1.0.0_iphoneos-arm64.deb
```

### macOS (full compiled dylib)

Requires [Theos](https://theos.dev/) with an iOS SDK.

```bash
cd amethyst-menu
bash scripts/build_mac.sh
```

### GitHub Actions (no Mac — recommended)

Push to GitHub and let cloud macOS build the real dylib. Full steps:

**See [BUILD_GITHUB.md](BUILD_GITHUB.md)**

Quick version:

```powershell
cd C:\Users\Averey\amethyst-menu
git add .
git commit -m "Add Amethyst mod menu"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/amethyst-menu.git
git push -u origin main
```

Then download **amethyst-deb** from the **Actions** tab.

## Injection

The `.deb` installs to both rootful and rootless paths:

- `Library/MobileSubstrate/DynamicLibraries/`
- `var/jb/Library/MobileSubstrate/DynamicLibraries/`

**Jailbroken device:**

```bash
dpkg -i com.amethyst.menu_1.0.0_iphoneos-arm64.deb
killall -9 WarRobots
```

**IPA injection (sideload tools):** use the extracted files in `packages/inject/`:

1. `Amethyst.dylib` — inject into the app binary load chain
2. `Amethyst.plist` — bundle filter (`com.pixonic.wwr`)

Point your injector at the `.deb` or the `inject/` folder. Target IPA:

```
C:\Users\Averey\Downloads\War Robots Amethsyt\com.pixonic.wwr-12.1.0-Decrypted.ipa
```

> **Note:** The Windows-built `.deb` includes a minimal arm64 dylib stub so injectors accept the package. For the full Amethyst menu UI, rebuild on macOS with Theos and run `build_deb.py --dylib <path>`.

## In-game controls

- **Open menu:** tap **menu** in the top-right corner
- **Close menu:** tap **close** or tap outside the panel

## Target IPA

Reference build:

```
C:\Users\Averey\Downloads\War Robots Amethsyt\com.pixonic.wwr-12.1.0-Decrypted.ipa
```

Bundle filter: `com.pixonic.wwr`

## Disclaimer

This project provides a menu shell and preference storage only. Use at your own risk. Modifying online games may violate terms of service.
