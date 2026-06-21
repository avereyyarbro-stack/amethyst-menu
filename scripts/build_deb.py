#!/usr/bin/env python3
"""Build com.amethyst.menu .deb for iOS injection (rootful + rootless paths)."""

from __future__ import annotations

import argparse
import gzip
import io
import shutil
import struct
import tarfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGES = ROOT / "packages"
DEB_NAME = "com.amethyst.menu_1.0.0_iphoneos-arm64.deb"


def build_minimal_arm64_dylib() -> bytes:
    """Build a tiny but valid MH_DYLIB arm64 Mach-O with LC_MAIN-style init."""
    # Mach-O 64 header
    buf = io.BytesIO()
    buf.write(struct.pack("<I", 0xFEEDFACF))  # MH_MAGIC_64
    buf.write(struct.pack("<I", 0x0100000C))  # CPU_TYPE_ARM64
    buf.write(struct.pack("<I", 0))            # CPU_SUBTYPE_ARM64_ALL
    buf.write(struct.pack("<I", 0x6))          # MH_DYLIB
    buf.write(struct.pack("<I", 4))          # ncmds
    buf.write(struct.pack("<I", 0))            # sizeofcmds (patched)
    buf.write(struct.pack("<I", 0x82000085))  # MH_NOUNDEFS|MH_DYLDLINK|MH_TWOLEVEL|MH_PIE
    buf.write(struct.pack("<I", 0))          # reserved

    load_cmds_start = buf.tell()
    pagezero = b"\x00" * 72  # placeholder LC_SEGMENT_64 __PAGEZERO
    text_seg = b"\x00" * 152  # placeholder LC_SEGMENT_64 __TEXT
    id_dylib = b"\x00" * 56
    uuid_cmd = b"\x00" * 24
    buf.write(pagezero + text_seg + id_dylib + uuid_cmd)

    # Patch with real load commands
    data = bytearray(buf.getvalue())
    off = load_cmds_start

    def write_segment(name: bytes, vmaddr: int, vmsize: int, fileoff: int, filesize: int, prot: int):
        nonlocal off
        struct.pack_into("<II", data, off, 0x19, 72)  # LC_SEGMENT_64
        segname = name.ljust(16, b"\x00")
        struct.pack_into("<16sQQQQIIII", data, off + 8, segname, vmaddr, vmsize, fileoff, filesize, prot, prot, 0, 0)

    # Rebuild properly
    data = bytearray()
    data += struct.pack("<IIIIIIII", 0xFEEDFACF, 0x0100000C, 0, 0x6, 5, 0, 0x82000085, 0)

    # LC_SEGMENT_64 __PAGEZERO
    data += struct.pack("<II", 0x19, 72)
    data += b"__PAGEZERO".ljust(16, b"\x00")
    data += struct.pack("<QQQQIIII", 0, 0x10000, 0, 0, 0, 0, 0, 0)

    # LC_SEGMENT_64 __TEXT
    text_off = len(data) + 72 + 56 + 24  # after remaining cmds, align
    text_off = (text_off + 15) & ~15
    data += struct.pack("<II", 0x19, 152)
    data += b"__TEXT".ljust(16, b"\x00")
    data += struct.pack("<QQQQIIII", 0x100000000, 0x4000, text_off, 0x4000, 5, 5, 1, 0)
    data += struct.pack("<16s16sQQIIII", b"__text", b"\x00" * 16, 0x100000000, 0x20, 2, 0, 0, 0)

    # LC_ID_DYLIB
    name_off = len(data) + 56
    data += struct.pack("<II", 0x0D, 24 + len(b"@rpath/Amethyst.dylib") + 1)
    data += struct.pack("<III", name_off, 0x10000, 0x10000)
    data += b"@rpath/Amethyst.dylib\x00"

    # LC_UUID
    data += struct.pack("<II", 0x1C, 24)
    data += bytes.fromhex("a1b2c3d4e5f6478990a1b2c3d4e5f60708")

    # LC_SYMTAB (minimal)
    data += struct.pack("<II", 0x02, 24)
    symoff = len(data) + 0x4000
    symoff = ((len(data) + 0x20 + 15) & ~15)
    data += struct.pack("<IIIII", symoff, 0, symoff, 0, 0)

    # pad to text offset
    while len(data) < text_off:
        data.append(0)

    # arm64: ret (C0 03 5F D6)
    data += b"\xC0\x03\x5F\xD6" * 8

    # patch sizeofcmds and ncmds
    sizeofcmds = len(data) - 32
    struct.pack_into("<II", data, 16, 5, sizeofcmds)

    return bytes(data)


def tar_gz(files: dict[str, bytes]) -> bytes:
    bio = io.BytesIO()
    with tarfile.open(fileobj=bio, mode="w:gz") as tar:
        for name, content in files.items():
            info = tarfile.TarInfo(name=name)
            info.size = len(content)
            tar.addfile(info, io.BytesIO(content))
    return bio.getvalue()


def ar_member(name: str, content: bytes) -> bytes:
    header = name.ljust(16)[:16].encode("ascii")
    header += b"0           "  # mtime
    header += b"0     "        # uid
    header += b"0     "        # gid
    header += b"100644  "      # mode
    header += str(len(content)).encode("ascii").rjust(10)
    header += b"`\n"
    payload = content
    if len(payload) % 2:
        payload += b"\n"
    return header + payload


def make_deb(control_files: dict[str, bytes], data_files: dict[str, bytes], out_path: Path) -> None:
    control_tar = tar_gz(control_files)
    data_tar = tar_gz(data_files)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "wb") as deb:
        deb.write(b"!<arch>\n")
        deb.write(ar_member("debian-binary", b"2.0\n"))
        deb.write(ar_member("control.tar.gz", control_tar))
        deb.write(ar_member("data.tar.gz", data_tar))


def main() -> None:
    parser = argparse.ArgumentParser(description="Build Amethyst .deb")
    parser.add_argument("--dylib", type=Path, help="Path to compiled Amethyst.dylib")
    parser.add_argument("--out", type=Path, default=PACKAGES / DEB_NAME)
    args = parser.parse_args()

    plist = (ROOT / "Amethyst.plist").read_bytes()
    if args.dylib and args.dylib.exists():
        dylib = args.dylib.read_bytes()
        dylib_source = str(args.dylib)
    elif (ROOT / "build" / "Amethyst.dylib").exists():
        dylib = (ROOT / "build" / "Amethyst.dylib").read_bytes()
        dylib_source = str(ROOT / "build" / "Amethyst.dylib")
    elif (ROOT / ".theos" / "obj" / "debug" / "Amethyst.dylib").exists():
        dylib = (ROOT / ".theos" / "obj" / "debug" / "Amethyst.dylib").read_bytes()
        dylib_source = str(ROOT / ".theos" / "obj" / "debug" / "Amethyst.dylib")
    else:
        dylib = build_minimal_arm64_dylib()
        dylib_source = "generated minimal stub (compile on macOS with Theos for full menu)"

    control_text = (ROOT / "control").read_text(encoding="utf-8")
    control_files = {"./control": control_text.encode("utf-8")}

    inject_paths = [
        "Library/MobileSubstrate/DynamicLibraries/Amethyst.dylib",
        "Library/MobileSubstrate/DynamicLibraries/Amethyst.plist",
        "var/jb/Library/MobileSubstrate/DynamicLibraries/Amethyst.dylib",
        "var/jb/Library/MobileSubstrate/DynamicLibraries/Amethyst.plist",
    ]

    data_files: dict[str, bytes] = {}
    for path in inject_paths:
        if path.endswith(".dylib"):
            data_files[f"./{path}"] = dylib
        else:
            data_files[f"./{path}"] = plist

    make_deb(control_files, data_files, args.out)

    inject_dir = args.out.parent / "inject"
    if inject_dir.exists():
        shutil.rmtree(inject_dir)
    inject_dir.mkdir(parents=True)
    (inject_dir / "Amethyst.dylib").write_bytes(dylib)
    (inject_dir / "Amethyst.plist").write_bytes(plist)

    print(f"Built: {args.out}")
    print(f"Dylib source: {dylib_source}")
    print(f"Inject bundle: {inject_dir}")


if __name__ == "__main__":
    main()
