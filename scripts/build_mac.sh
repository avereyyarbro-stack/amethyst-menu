#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${THEOS:-}" ]; then
  echo "Set THEOS to your Theos install path, e.g. export THEOS=~/theos"
  exit 1
fi

make clean package
DYLIB="$(find .theos/obj -name 'Amethyst.dylib' | head -n1)"
python3 scripts/build_deb.py --dylib "$DYLIB"
echo "Done. Install: dpkg -i packages/com.amethyst.menu_1.0.0_iphoneos-arm64.deb"
