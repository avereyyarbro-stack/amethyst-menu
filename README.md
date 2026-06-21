# Amethyst

Sideload-compatible overlay mod menu for **War Robots**, styled after the [bus next-gen](https://bus.anotheraxiom.org) aesthetic.

No Substrate or jailbreak required — inject the dylib into the IPA and sign with **Sideloadly**.

UI toggles persist settings locally. They do **not** include game memory hooks.

## Mods

| Toggle | Description |
|--------|-------------|
| **enemy team health numbers** | Display numeric HP above enemy robots |
| **anaksor invisibility highlight** | Outline Anaksor while stealth is active |

## Sideloadly (recommended)

### 1. Download the real dylib

GitHub → **Actions** → latest green build → download **amethyst-deb** → copy `Amethyst.dylib` to:

```
C:\Users\Averey\amethyst-menu\packages\inject\Amethyst.dylib
```

### 2. Inject into War Robots IPA

```powershell
cd C:\Users\Averey\amethyst-menu
powershell -ExecutionPolicy Bypass -File scripts\inject_ipa.ps1
```

Output: `C:\Users\Averey\Downloads\War Robots Amethsyt\WarRobots-Amethyst-injected.ipa`

### 3. Sign with Sideloadly

Open the injected IPA in **Sideloadly**, sign with your Apple ID, install, launch War Robots, tap **menu** top-right.

## Preview (Windows browser)

```
C:\Users\Averey\amethyst-menu\preview\index.html
```

## Build from source

GitHub Actions builds the sideload dylib automatically on push. See [BUILD_GITHUB.md](BUILD_GITHUB.md).

```bash
make
python3 scripts/build_deb.py --dylib $(find .theos -name 'Amethyst.dylib' | head -n1)
```

## In-game controls

- **Open menu:** tap **menu** in the top-right corner
- **Close menu:** tap **close** or tap outside the panel

## Disclaimer

UI overlay only. Use at your own risk. Modifying online games may violate terms of service.
