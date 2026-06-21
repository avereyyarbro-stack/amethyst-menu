# Amethyst — Sideloadly Setup

## 1. Download the dylib

1. Open [Actions](https://github.com/avereyyarbro-stack/amethyst-menu/actions)
2. Click the latest green **Build Amethyst** run
3. Download **amethyst-deb** artifact
4. Unzip and copy `Amethyst.dylib` to:

```
C:\Users\Averey\amethyst-menu\packages\inject\Amethyst.dylib
```

## 2. Inject into War Robots IPA

```powershell
cd C:\Users\Averey\amethyst-menu
powershell -ExecutionPolicy Bypass -File scripts\inject_ipa.ps1
```

Output IPA:

```
C:\Users\Averey\Downloads\War Robots Amethsyt\WarRobots-Amethyst-injected.ipa
```

## 3. Sign with Sideloadly

1. Open **Sideloadly**
2. Select `WarRobots-Amethyst-injected.ipa`
3. Enter your Apple ID and install
4. Launch War Robots — tap **menu** in the top-right corner

## Notes

- No jailbreak or Substrate required
- Re-download and re-inject after each code update
- Re-sign in Sideloadly when the app expires (7 days free account)
