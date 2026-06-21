#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${THEOS:-}" ]; then
  echo "Set THEOS to your Theos install path, e.g. export THEOS=~/theos"
  exit 1
fi

make clean
make
DYLIB="$(find .theos -name 'Amethyst.dylib' -type f | head -n1)"
python3 scripts/build_deb.py --dylib "$DYLIB"
echo "Done. Sideload: inject IPA with packages/inject/Amethyst.dylib"
