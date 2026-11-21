"""Read and persist the positions of extended Hyprland displays."""
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import time


def ctl(*args):
    return subprocess.check_output(("/usr/bin/hyprctl", *args), text=True, timeout=4).strip()


def snapshot():
    monitors = [m for m in json.loads(ctl("-j", "monitors")) if not m.get("disabled")]
    rows = []
    for m in monitors:
        w, h = m["width"], m["height"]
        if m["transform"] % 2:
            w, h = h, w
        rows.append(dict(name=m["name"], x=m["x"], y=m["y"],
                         w=round(w/m["scale"]), h=round(h/m["scale"])))
    rows.sort(key=lambda r: r["name"])
    return rows, any(m.get("mirrorOf") not in (None, "", "none") for m in monitors)


def validate(rows, baseline):
    if len(rows) < 2 or len(rows) != len(baseline):
        raise ValueError("Display list changed")
    edges = [set() for _ in rows]
    for i, (r, original) in enumerate(zip(rows, baseline)):
        if (not re.fullmatch(r"[A-Za-z0-9._-]{1,64}", r["name"])
                or any(r[k] != original[k] for k in ("name", "w", "h"))
                or any(type(r[k]) is not int or abs(r[k]) > 100000 for k in ("x", "y"))):
            raise ValueError("Invalid display or position")
        for j, s in enumerate(rows[:i]):
            dx = min(r["x"]+r["w"], s["x"]+s["w"]) - max(r["x"], s["x"])
            dy = min(r["y"]+r["h"], s["y"]+s["h"]) - max(r["y"], s["y"])
            if dx > 0 and dy > 0:
                raise ValueError("Overlapping displays")
            if (dx == 0 and dy > 0) or (dy == 0 and dx > 0):
                edges[i].add(j)
                edges[j].add(i)
    seen, pending = {0}, [0]
    while pending:
        for j in edges[pending.pop()] - seen:
            seen.add(j)
            pending.append(j)
    if len(seen) != len(rows):
        raise ValueError("Disconnected displays")


RULE = re.compile(r'(?P<start>\s*hl\.monitor\(\{\s*output\s*=\s*)"(?P<name>[^"]*)"'
                  r'(?P<rest>\s*,[^{}]*\}\)\s*)(?:--.*)?')
POSITION = re.compile(r'(?<=,)\s*position\s*=\s*"[^"]*"')


def render(source, rows):
    lines = source.splitlines(keepends=True)
    rules = {}
    for i, line in enumerate(lines):
        code = line.strip()
        if not code or code.startswith("--") or code.startswith("hl.env(") or re.fullmatch(
                r"local omarchy_(gdk|monitor)_scale = [\d.]+", code):
            continue
        match = RULE.fullmatch(line.rstrip("\n"))
        if not match or match["name"] in rules or match["name"].startswith("desc:"):
            raise ValueError("Custom monitor configuration cannot be edited safely")
        rules[match["name"]] = (i, match)
    additions = []
    for r in rows:
        existing = rules.get(r["name"])
        if not existing and "" not in rules:
            raise ValueError("No default monitor rule")
        index, match = existing or rules[""]
        pos = f' position = "{r["x"]}x{r["y"]}"'
        rest, count = POSITION.subn(pos, match["rest"])
        if count != 1:
            raise ValueError("Expected one simple position field")
        rule = f'{match["start"]}"{r["name"]}"{rest}'
        if existing:
            lines[index] = rule + match.string[match.end("rest"):] + "\n"
        else:
            additions.append(rule + "\n")
    if additions:
        index = rules[""][0] + 1
        if not lines[index-1].endswith("\n"):
            lines[index-1] += "\n"
        lines[index:index] = additions
    return "".join(lines)


def replace(path, data):
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as tmp:
        temporary = Path(tmp.name)
        try:
            os.fchmod(tmp.fileno(), stat.S_IMODE(path.stat().st_mode))
            tmp.write(data)
            tmp.flush()
            os.replace(temporary, path)
        finally:
            temporary.unlink(missing_ok=True)


def save(baseline, desired):
    live, mirrored = snapshot()
    if mirrored or live != baseline or ctl("configerrors"):
        raise ValueError("The live configuration changed or already has errors")
    validate(desired, live)
    path = (Path.home() / ".config/hypr/monitors.lua").resolve(strict=True)
    old = path.read_bytes()
    new = render(old.decode(), desired).encode()
    if path.read_bytes() != old:
        raise ValueError("The monitor config changed")
    with tempfile.NamedTemporaryFile(dir=path.parent, prefix="monitors.lua.layout-backup-",
                                     delete=False) as backup:
        backup.write(old)
    replace(path, new)
    try:
        if ctl("reload") != "ok":
            raise ValueError("Hyprland did not reload")
        for _ in range(10):
            actual, mirrored = snapshot()
            if actual == desired and not mirrored and not ctl("configerrors"):
                return
            time.sleep(0.15)
        raise ValueError("Hyprland did not apply the requested positions")
    except Exception:
        if path.read_bytes() == new:
            replace(path, old)
            ctl("reload")
            ctl("configerrors")
        raise


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["read"]:
            rows, mirrored = snapshot()
            print(json.dumps(dict(rows=rows, mirrored=mirrored)))
        elif len(sys.argv) == 4 and sys.argv[1] == "save":
            save(json.loads(sys.argv[2]), json.loads(sys.argv[3]))
        else:
            raise ValueError("Unknown command")
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        sys.exit(str(error))
