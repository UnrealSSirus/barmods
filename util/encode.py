"""
Encode one or more mod files to base64 and produce a single `!bset` command.
The command is printed and copied to the clipboard.

Usage (from repo root):
  python util/encode.py sirus-ranker.lua
  python util/encode.py mods/sirus-ranker.lua mods/prefix-pack1.lua
  python util/encode.py sirus-ranker prefix-pack1

Notes:
- Uses URL-safe base64 and strips "=" padding so the output won't contain "+" or "=".
- Encodes mods in the order provided on the command line.
"""

from __future__ import annotations

import argparse
import base64
import ctypes
import os
import subprocess
import sys
from pathlib import Path


def _repo_root() -> Path:
    # `util/encode.py` -> repo root is parent of `util/`
    return Path(__file__).resolve().parents[1]


def _resolve_input_file(user_arg: str, mods_dir: Path) -> Path:
    """
    Resolve `user_arg` as either:
    - a direct path (absolute or relative), if it exists
    - a file inside mods_dir (with optional ".lua" appended)
    """
    direct = Path(user_arg)
    if direct.is_file():
        return direct.resolve()

    candidate = mods_dir / user_arg
    if candidate.is_file():
        return candidate.resolve()

    if direct.suffix == "":
        candidate_lua = mods_dir / f"{user_arg}.lua"
        if candidate_lua.is_file():
            return candidate_lua.resolve()

    tried = [str(direct), str(candidate)]
    if direct.suffix == "":
        tried.append(str(mods_dir / f"{user_arg}.lua"))
    raise FileNotFoundError(
        "Could not find input file. Tried:\n- " + "\n- ".join(tried)
    )


def _copy_to_clipboard(text: str) -> None:
    """
    Copy to clipboard using tkinter (cross-platform when available).
    If tkinter isn't available (common on minimal Python installs), fall back to
    Windows 'clip' when running on Windows.
    """
    if text is None or text == "":
        raise ValueError("Refusing to copy empty text to clipboard.")

    # Prefer Windows-native clipboard API on Windows (more reliable than tkinter for large payloads).
    if os.name == "nt":
        try:
            _copy_to_clipboard_windows(text)
            return
        except Exception:
            # Fall back to clip below.
            pass

    try:
        import tkinter  # type: ignore

        r = tkinter.Tk()
        r.withdraw()
        r.clipboard_clear()
        r.clipboard_append(text)
        # Keep the clipboard after program exits.
        r.update()
        r.destroy()
        return
    except Exception:
        pass

    if os.name == "nt":
        # 'clip' reads from stdin and updates the Windows clipboard.
        # Avoid shell=True; call the executable directly.
        subprocess.run(["clip"], input=text, text=True, check=True)
        return

    raise RuntimeError(
        "Clipboard copy failed (tkinter unavailable), and no OS fallback is implemented."
    )


def _copy_to_clipboard_windows(text: str) -> None:
    """
    Copy Unicode text to the Windows clipboard using Win32 APIs.

    This is intentionally dependency-free and avoids the common failure mode of
    clipboard being cleared but not set.
    """
    CF_UNICODETEXT = 13
    GMEM_MOVEABLE = 0x0002

    user32 = ctypes.windll.user32
    kernel32 = ctypes.windll.kernel32

    # Set proper return/argument types for 64-bit compatibility.
    # Without this, ctypes defaults to c_int which truncates 64-bit pointers.
    kernel32.GlobalAlloc.argtypes = [ctypes.c_uint, ctypes.c_size_t]
    kernel32.GlobalAlloc.restype = ctypes.c_void_p
    kernel32.GlobalLock.argtypes = [ctypes.c_void_p]
    kernel32.GlobalLock.restype = ctypes.c_void_p
    kernel32.GlobalUnlock.argtypes = [ctypes.c_void_p]
    kernel32.GlobalFree.argtypes = [ctypes.c_void_p]
    user32.SetClipboardData.argtypes = [ctypes.c_uint, ctypes.c_void_p]
    user32.SetClipboardData.restype = ctypes.c_void_p

    if not user32.OpenClipboard(None):
        raise OSError("OpenClipboard failed")

    try:
        if not user32.EmptyClipboard():
            raise OSError("EmptyClipboard failed")

        # Allocate global memory for the text (UTF-16LE + NUL terminator).
        data = text.encode("utf-16le") + b"\x00\x00"
        hglobal = kernel32.GlobalAlloc(GMEM_MOVEABLE, len(data))
        if not hglobal:
            raise MemoryError("GlobalAlloc failed")

        locked = kernel32.GlobalLock(hglobal)
        if not locked:
            kernel32.GlobalFree(hglobal)
            raise MemoryError("GlobalLock failed")

        try:
            ctypes.memmove(locked, data, len(data))
        finally:
            kernel32.GlobalUnlock(hglobal)

        if not user32.SetClipboardData(CF_UNICODETEXT, hglobal):
            kernel32.GlobalFree(hglobal)
            raise OSError("SetClipboardData failed")

        # On success, ownership transfers to the system; do not free hglobal.
    finally:
        user32.CloseClipboard()


def _encode_payload(raw: bytes) -> str:
    # URL-safe and strip "=" padding so chat commands don't include "+" or "=".
    return base64.urlsafe_b64encode(raw).decode("ascii").rstrip("=")


def build_bset_command(file_args: list[str], mods_dir: Path) -> tuple[str, list[Path]]:
    resolved: list[Path] = [_resolve_input_file(f, mods_dir) for f in file_args]
    payloads = [_encode_payload(p.read_bytes()) for p in resolved]
    cmd = "!bset"
    for i, payload in enumerate(payloads, start=1):
        mod_priority = 8 if file_args[i-1].startswith("attribute-resolver") else 1
        if(file_args[i-1].startswith("prefix-pack1")):
            mod_priority = 5
        print(f"Mod {i} size: {len(payload)} characters", file=sys.stderr)
        if len(payload) > 15000:
            print(
                f"Warning: Mod {i} exceeds 15000 character limit ({len(payload)} chars)!",
                file=sys.stderr,
            )
        cmd += f" tweakdefs{mod_priority} {payload}"
    return cmd, resolved


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        description="Encode one or more mod files and copy a single `!bset` command to the clipboard."
    )
    parser.add_argument(
        "files",
        nargs="+",
        help="One or more mod filenames in `mods/` (e.g. sirus-ranker.lua) or direct paths (e.g. mods/sirus-ranker.lua).",
    )
    args = parser.parse_args(argv)

    mods_dir = (_repo_root() / "mods").resolve()
    cmd, resolved = build_bset_command(args.files, mods_dir)

    _copy_to_clipboard(cmd)
    print(cmd)


    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))