#!/usr/bin/env python3
"""Resolve display names for Hyprland clients (app first, not window title)."""
from __future__ import annotations

import json
import pathlib
import re
import subprocess
import sys

ALIASES = {
    "org.telegram.desktop": "Telegram",
    "telegram-desktop": "Telegram",
    "telegramdesktop": "Telegram",
    "org.signal.Signal": "Signal",
    "signal": "Signal",
    "slack": "Slack",
    "spotify": "Spotify",
    "discord": "Discord",
    "zoom": "Zoom",
    "org.remmina.Remmina": "Remmina",
    "org.gnome.Nautilus": "Files",
    "org.omarchy.terminal": "Terminal",
    "org.omarchy.about": "About",
    "google-chrome": "Chrome",
    "chromium": "Chromium",
    "firefox": "Firefox",
    "cursor": "Cursor",
    "code": "VS Code",
    "code-oss": "VS Code",
    "code-url-handler": "VS Code",
    "dev.zed.Zed": "Zed",
    "foot": "Terminal",
    "alacritty": "Terminal",
    "kitty": "Terminal",
    "com.mitchellh.ghostty": "Terminal",
    "gymnite": "Gymnite",
}

# Known tokens inside dotted app ids (prefer these over trailing "desktop").
CLASS_TOKENS = {
    "telegram": "Telegram",
    "signal": "Signal",
    "slack": "Slack",
    "spotify": "Spotify",
    "discord": "Discord",
    "chrome": "Chrome",
    "chromium": "Chromium",
    "firefox": "Firefox",
    "nautilus": "Files",
    "remmina": "Remmina",
    "cursor": "Cursor",
    "thunderbird": "Thunderbird",
    "zoom": "Zoom",
}

AGENT_CMDS = [
    ("cursor-agent", "Cursor CLI"),
    ("claude", "Claude Code"),
    ("codex", "Codex"),
    ("gemini", "Gemini"),
    ("opencode", "OpenCode"),
    ("openclaw", "OpenClaw"),
    ("hermes", "Hermes"),
    ("crush", "Crush"),
    ("muse", "Muse"),
    ("grok", "Grok"),
    ("copilot", "Copilot"),
    ("pi", "Pi"),
]

BIDI_RE = re.compile(r"[\u200e\u200f\u202a-\u202e\u2066-\u2069]")


def read_cmdline(pid: int) -> str:
    try:
        raw = pathlib.Path(f"/proc/{pid}/cmdline").read_bytes()
    except OSError:
        return ""
    return raw.replace(b"\x00", b" ").decode("utf-8", "replace")


def agent_from_cmdline(cmd: str) -> str:
    low = cmd.lower()
    # Prefer longer / more specific matches first (already ordered).
    for token, name in AGENT_CMDS:
        # Match as a path segment or bare argv token.
        if re.search(rf"(^|[\s/]){re.escape(token)}([\s/]|$)", low):
            return name
    return ""


def class_app_name(cls: str) -> str:
    c = (cls or "").strip()
    if not c:
        return ""
    if c in ALIASES:
        return ALIASES[c]
    low = c.lower()
    for key, name in ALIASES.items():
        if key.lower() == low:
            return name
    # Chrome PWA / webapp classes: chrome-host__-Default
    if low.startswith("chrome-"):
        return "Chrome"
    parts = re.split(r"[.\-_]+", c)
    for part in parts:
        name = CLASS_TOKENS.get(part.lower())
        if name:
            return name
    # Avoid useless trailing tokens like "desktop"
    skip = {"org", "com", "io", "desktop", "app", "client", "linux", "default"}
    useful = [p for p in parts if p and p.lower() not in skip]
    if useful:
        last = useful[-1]
        return last[:1].upper() + last[1:]
    return ""


def clean_title(title: str) -> str:
    t = BIDI_RE.sub("", title or "").strip()
    t = re.sub(r"\s+", " ", t)
    return t


def detail_from_title(title: str, app: str) -> str:
    t = clean_title(title)
    if not t:
        return ""
    # Strip browser suffix noise
    for suffix in (" - Google Chrome", " - Chromium", " — Mozilla Firefox", " - Firefox"):
        if t.endswith(suffix):
            t = t[: -len(suffix)].strip()
    if app:
        low_app = app.lower()
        low_t = t.lower()
        if low_t == low_app or low_t.startswith(low_app + " "):
            return ""
        for sep in (" — ", " - ", " – ", " | "):
            if low_t.endswith(sep + low_app):
                t = t[: -(len(sep) + len(app))].strip()
                break
            if low_t.startswith(low_app + sep):
                t = t[len(app) + len(sep) :].strip()
                break
    # Drop unread counters like "– (193)" and agent spinner prefixes.
    t = re.sub(r"\s*[—\-–]\s*\(\d+\)\s*$", "", t).strip()
    t = re.sub(r"^[\u25d0\u25d1\u25d2\u25d3\u2800-\u28ff◉◎●○]\s*", "", t).strip()
    if app and t.lower() == app.lower():
        return ""
    if len(t) > 28:
        t = t[:27] + "…"
    return t


def resolve(client: dict) -> str:
    cls = client.get("class") or client.get("initialClass") or ""
    title = client.get("title") or ""
    pid = int(client.get("pid") or 0)
    cmd = read_cmdline(pid) if pid else ""

    app = ""
    if (cls == "org.omarchy.agent" or "org.omarchy.agent" in cmd) and cmd:
        app = agent_from_cmdline(cmd)
    if not app:
        app = class_app_name(cls)
    if not app and cmd:
        app = agent_from_cmdline(cmd)
    if not app:
        app = class_app_name(cls) or "App"

    detail = detail_from_title(title, app)
    return f"{app} — {detail}" if detail else app


def main() -> int:
    active_only = "--active" in sys.argv
    try:
        if active_only:
            client = json.loads(
                subprocess.check_output(["hyprctl", "-j", "activewindow"], text=True)
            )
            if not isinstance(client, dict) or not client.get("address"):
                print("", end="")
                return 0
            print(resolve(client), end="")
            return 0

        clients = json.loads(subprocess.check_output(["hyprctl", "-j", "clients"], text=True))
    except Exception as exc:
        if active_only:
            print("", end="")
            return 1
        print(json.dumps({"error": str(exc)}))
        return 1

    out = {}
    for c in clients:
        addr = str(c.get("address") or "")
        if not addr:
            continue
        out[addr] = {
            "app": resolve(c),
            "class": c.get("class") or "",
            "title": clean_title(c.get("title") or ""),
            "pid": c.get("pid") or 0,
        }
    json.dump(out, sys.stdout, ensure_ascii=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
