# Build on GitHub (no Mac needed)

GitHub Actions compiles the real `Amethyst.dylib` on a cloud Mac and uploads the `.deb` for you.

## One-time setup

### 1. Create a GitHub repository

1. Open [https://github.com/new](https://github.com/new)
2. Name it `amethyst-menu` (or anything you like)
3. Leave it **empty** — no README, no `.gitignore`, no license
4. Click **Create repository**

### 2. Push this project from PowerShell

Replace `YOUR_USERNAME` with your GitHub username:

```powershell
cd C:\Users\Averey\amethyst-menu

git add .
git commit -m "Add Amethyst mod menu with GitHub Actions build"

git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/amethyst-menu.git
git push -u origin main
```

If GitHub asks you to sign in, use a **Personal Access Token** as the password (not your GitHub account password):

1. GitHub → **Settings** → **Developer settings** → **Personal access tokens**
2. Generate a token with `repo` scope
3. Paste it when `git push` asks for a password

### 3. Download the built `.deb`

1. Open your repo on GitHub
2. Click the **Actions** tab
3. Open the latest **Build Amethyst** run (green checkmark)
4. Scroll to **Artifacts**
5. Download **amethyst-deb**
6. Unzip — you get:
   - `com.amethyst.menu_1.0.0_iphoneos-arm64.deb`
   - `Amethyst.dylib`
   - `Amethyst.plist`

## Rebuild anytime

Push any change:

```powershell
cd C:\Users\Averey\amethyst-menu
git add .
git commit -m "Update menu"
git push
```

Or rebuild without changing code:

1. GitHub → **Actions** → **Build Amethyst**
2. **Run workflow** → **Run workflow**

## Install on device

**Jailbreak:**

```bash
dpkg -i com.amethyst.menu_1.0.0_iphoneos-arm64.deb
killall -9 WarRobots
```

**IPA injection:** use `Amethyst.dylib` + `Amethyst.plist` from the artifact with your injector.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Push rejected (auth) | Use a Personal Access Token, not your GitHub password |
| Workflow fails on SDK | Open the failed run log; we may need to adjust `TARGET` in `Makefile` |
| No Artifacts | Wait for the job to finish; failed builds don't upload files |
