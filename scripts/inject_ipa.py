#!/usr/bin/env python3
"""Inject Amethyst.dylib into a War Robots IPA (Windows/macOS/Linux)."""

from __future__ import annotations

import argparse
import shutil
import struct
import sys
import tempfile
import zipfile
from pathlib import Path

LC_LOAD_DYLIB = 0xC
LC_CODE_SIGNATURE = 0x1D
MH_MAGIC_64 = 0xFEEDFACF

DEFAULT_IPA = Path(r"C:\Users\Averey\Downloads\War Robots Amethsyt\com.pixonic.wwr-12.1.0-Decrypted.ipa")
DEFAULT_DYLIB = Path(__file__).resolve().parents[1] / "packages" / "inject" / "Amethyst.dylib"
DEFAULT_OUT = Path(r"C:\Users\Averey\Downloads\War Robots Amethsyt\WarRobots-Amethyst-injected.ipa")

INSTALL_NAME = "@executable_path/Frameworks/Amethyst.dylib"
APP_BUNDLE = "Payload/WarRobots.app"
MAIN_BINARY = f"{APP_BUNDLE}/WarRobots"
DYLIB_ZIP_PATH = f"{APP_BUNDLE}/Frameworks/Amethyst.dylib"


def align8(n: int) -> int:
    return (n + 7) & ~7


def build_load_dylib_command(install_name: str) -> bytes:
    name = install_name.encode("utf-8") + b"\x00"
    cmdsize = align8(24 + len(name))
    cmd = bytearray(cmdsize)
    struct.pack_into("<II", cmd, 0, LC_LOAD_DYLIB, cmdsize)
    struct.pack_into("<I", cmd, 8, 24)
    struct.pack_into("<III", cmd, 12, 0, 0, 0)
    cmd[24 : 24 + len(name)] = name
    return bytes(cmd)


def insert_dylib_load_command(binary: bytearray, install_name: str) -> bytearray:
    magic = struct.unpack_from("<I", binary, 0)[0]
    if magic != MH_MAGIC_64:
        raise ValueError(f"Unsupported Mach-O magic: {hex(magic)} (expected thin arm64)")

    ncmds, sizeofcmds = struct.unpack_from("<II", binary, 16)
    off = 32
    commands: list[tuple[int, int, bytes]] = []
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", binary, off)
        commands.append((cmd, cmdsize, bytes(binary[off : off + cmdsize])))
        off += cmdsize

    filtered = [c for c in commands if c[0] != LC_CODE_SIGNATURE]
    if any(c[0] == LC_LOAD_DYLIB and install_name.encode() in c[2] for c in filtered):
        print(f"Already contains load command for {install_name}")
        return binary

    new_cmds_blob = b"".join(c[2] for c in filtered) + build_load_dylib_command(install_name)
    new_ncmds = len(filtered) + 1
    new_sizeofcmds = len(new_cmds_blob)

    old_cmd_end = 32 + sizeofcmds
    text_fileoff = min_segment_fileoff(binary)
    new_cmd_end = 32 + new_sizeofcmds
    if new_cmd_end > text_fileoff:
        raise ValueError(
            f"Not enough header space for LC_LOAD_DYLIB ({new_cmd_end} > {text_fileoff})"
        )

    out = bytearray(binary[:32])
    struct.pack_into("<II", out, 16, new_ncmds, new_sizeofcmds)
    out.extend(new_cmds_blob)
    out.extend(binary[old_cmd_end:])
    return out


def min_segment_fileoff(binary: bytes) -> int:
    ncmds = struct.unpack_from("<I", binary, 16)[0]
    off = 32
    min_off = len(binary)
    for _ in range(ncmds):
        cmd, cmdsize = struct.unpack_from("<II", binary, off)
        if cmd in (0x19, 0x1):  # LC_SEGMENT_64 / LC_SEGMENT
            fileoff = struct.unpack_from("<Q", binary, off + 32)[0]
            if fileoff:
                min_off = min(min_off, fileoff)
        off += cmdsize
    return min_off


def inject_ipa(ipa_path: Path, dylib_path: Path, out_path: Path) -> None:
    if not ipa_path.exists():
        raise FileNotFoundError(f"IPA not found: {ipa_path}")
    if not dylib_path.exists():
        raise FileNotFoundError(f"Dylib not found: {dylib_path}")
    if dylib_path.stat().st_size < 4096:
        print(
            "WARNING: Dylib looks like the Windows stub. "
            "Use the GitHub Actions Amethyst.dylib from the amethyst-deb artifact.",
            file=sys.stderr,
        )

    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(prefix="amethyst-inject-"))
    try:
        extract_dir = tmp / "ipa"
        extract_dir.mkdir()
        with zipfile.ZipFile(ipa_path, "r") as zin:
            zin.extractall(extract_dir)

        app_dir = extract_dir / APP_BUNDLE
        frameworks = app_dir / "Frameworks"
        frameworks.mkdir(exist_ok=True)
        shutil.copy2(dylib_path, frameworks / "Amethyst.dylib")

        binary_path = extract_dir / MAIN_BINARY
        original = bytearray(binary_path.read_bytes())
        patched = insert_dylib_load_command(original, INSTALL_NAME)
        binary_path.write_bytes(patched)
        print(f"Patched {MAIN_BINARY} with {INSTALL_NAME}")

        if out_path.exists():
            out_path.unlink()
        with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_DEFLATED) as zout:
            for file in sorted(extract_dir.rglob("*")):
                if file.is_file():
                    arc = file.relative_to(extract_dir).as_posix()
                    zout.write(file, arc)

        print(f"Created: {out_path}")
        print(f"Size: {out_path.stat().st_size / (1024*1024):.1f} MB")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main() -> None:
    parser = argparse.ArgumentParser(description="Inject Amethyst.dylib into War Robots IPA")
    parser.add_argument("--ipa", type=Path, default=DEFAULT_IPA)
    parser.add_argument("--dylib", type=Path, default=DEFAULT_DYLIB)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    inject_ipa(args.ipa, args.dylib, args.out)


if __name__ == "__main__":
    main()
