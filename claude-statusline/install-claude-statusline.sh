#!/usr/bin/env bash
# Устанавливает кастомный status line в Claude Code глобально (для всех проектов).
# Создаёт ~/.claude/statusline-command.py и прописывает statusLine в ~/.claude/settings.json,
# не затирая остальные настройки. Можно запускать повторно — идемпотентно.
set -euo pipefail

CLAUDE_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
SCRIPT_PATH="$CLAUDE_DIR/statusline-command.py"
SETTINGS="$CLAUDE_DIR/settings.json"

command -v python3 >/dev/null 2>&1 || { echo "Ошибка: нужен python3" >&2; exit 1; }

mkdir -p "$CLAUDE_DIR"

# ── 1. Скрипт status line ─────────────────────────────────────────────────────
cat > "$SCRIPT_PATH" <<'PYEOF'
#!/usr/bin/env python3
import json
import sys
import os
import time

# ANSI
RESET  = "\033[0m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
CYAN   = "\033[36m"
GREEN  = "\033[32m"
YELLOW = "\033[33m"
RED    = "\033[31m"
WHITE  = "\033[37m"

MAX_DIR = 24  # max visible length of the folder name before truncation


def fmt_tokens(n):
    if n >= 1_000_000:
        return f"{n / 1_000_000:.2f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}K"
    return str(n)


def pct_color(p):
    if p < 50:
        return GREEN
    if p < 80:
        return YELLOW
    return RED


def bar(pct, width=8):
    pct = max(0, min(100, pct))
    filled = int(round(pct / 100 * width))
    return "█" * filled + "░" * (width - filled)


def fmt_reset(ts):
    if not isinstance(ts, (int, float)):
        return None
    left = int(ts - time.time())
    if left <= 0:
        return "now"
    d, rem = divmod(left, 86400)
    h, rem = divmod(rem, 3600)
    m = rem // 60
    if d:
        return f"{d}d{h}h"
    if h:
        return f"{h}h{m:02d}m"
    return f"{m}m"


def term_width():
    c = os.environ.get("COLUMNS")
    if c and c.isdigit():
        return int(c)
    for fd in (1, 2, 0):
        try:
            w = os.get_terminal_size(fd).columns
            if w > 0:
                return w
        except Exception:
            pass
    try:
        with open("/dev/tty") as tty:
            return os.get_terminal_size(tty.fileno()).columns
    except Exception:
        pass
    return 9999  # detection failed -> show everything


def label(text):
    return f"{DIM}{text}{RESET}"


try:
    data = json.loads(sys.stdin.read())
except Exception:
    sys.exit(0)

# ── extract values ────────────────────────────────────────────────────────────
model_name = (data.get("model") or {}).get("display_name") or "?"

cwd = data.get("cwd") or (data.get("workspace") or {}).get("current_dir") or ""
folder = os.path.basename(cwd.rstrip("/")) if cwd else "?"
if len(folder) > MAX_DIR:
    folder = folder[:MAX_DIR - 1] + "…"

cw = data.get("context_window") or {}
cu = cw.get("current_usage") or {}
total_tokens = (
    cu.get("input_tokens", 0)
    + cu.get("cache_creation_input_tokens", 0)
    + cu.get("cache_read_input_tokens", 0)
    + cu.get("output_tokens", 0)
)
ctx_pct = cw.get("used_percentage")

rl = data.get("rate_limits") or {}

# ── build blocks ──────────────────────────────────────────────────────────────
# priority (lower kept longer): usage 5h(1) > dir(2) > usage 7d(3) > model(4) > ctx(5)
# Each block has a "full" and a "min" variant; for usage, "min" drops the bar.
blocks = []


def add_block(prio, order, usage, plain, render, plain_min=None, render_min=None):
    blocks.append({
        "prio": prio, "order": order, "usage": usage,
        "plain": plain, "render": render,
        "plain_min": plain_min if plain_min is not None else plain,
        "render_min": render_min if render_min is not None else render,
    })


add_block(4, 0, False,
          f"model: {model_name}",
          f"{label('model:')} {CYAN}{BOLD}{model_name}{RESET}")
add_block(2, 1, False,
          f"dir: {folder}",
          f"{label('dir:')} {YELLOW}{folder}{RESET}")
if total_tokens:
    cp = f" ({ctx_pct:.0f}%)" if isinstance(ctx_pct, (int, float)) else ""
    add_block(5, 2, False,
              f"ctx: {fmt_tokens(total_tokens)}{cp}",
              f"{label('ctx:')} {WHITE}{fmt_tokens(total_tokens)}{RESET}{DIM}{cp}{RESET}")

for nm, key, prio, order, first in (("5h", "five_hour", 1, 3, True),
                                    ("7d", "seven_day", 3, 4, False)):
    info = rl.get(key)
    if not isinstance(info, dict):
        continue
    p = info.get("used_percentage")
    if not isinstance(p, (int, float)):
        continue
    col = pct_color(p)
    r = fmt_reset(info.get("resets_at"))
    pp = "usage: " if first else ""
    pr = f"{label('usage:')} " if first else ""
    rs_plain = f" (reset {r})" if r else ""
    rs_render = f" {DIM}(reset {r}){RESET}" if r else ""
    # full = with bar, min = without bar
    plain_full = f"{pp}{nm} {bar(p)} {p:.0f}%{rs_plain}"
    render_full = f"{pr}{DIM}{nm}{RESET} {col}{bar(p)} {p:.0f}%{RESET}{rs_render}"
    plain_min = f"{pp}{nm} {p:.0f}%{rs_plain}"
    render_min = f"{pr}{DIM}{nm}{RESET} {col}{p:.0f}%{RESET}{rs_render}"
    add_block(prio, order, True, plain_full, render_full, plain_min, render_min)

# ── responsive selection ──────────────────────────────────────────────────────
SEP_W = 5  # visible width of "  |  "
max_w = term_width() - 1


def select(full):
    sel, used = [], 0
    for b in sorted(blocks, key=lambda x: x["prio"]):
        plain = b["plain"] if full else b["plain_min"]
        add = len(plain) + (SEP_W if sel else 0)
        if not sel or used + add <= max_w:
            sel.append(b)
            used += add
        else:
            break  # strict priority
    return sel


# Try with bars first; if not everything fits, drop bars (then drop blocks).
selected = select(True)
use_full = True
if len(selected) < len(blocks):
    selected = select(False)
    use_full = False

selected.sort(key=lambda x: x["order"])

# ── render ────────────────────────────────────────────────────────────────────
SEP  = f"  {DIM}|{RESET}  "
USEP = f" {DIM}·{RESET} "
out, prev = "", None
for b in selected:
    piece = b["render"] if use_full else b["render_min"]
    if prev is None:
        out = piece
    else:
        out += (USEP if (prev["usage"] and b["usage"]) else SEP) + piece
    prev = b

print(out)
PYEOF

chmod +x "$SCRIPT_PATH"
echo "✓ Скрипт: $SCRIPT_PATH"

# ── 2. Прописать statusLine в settings.json (не затирая остальное) ────────────
SCRIPT_PATH="$SCRIPT_PATH" SETTINGS="$SETTINGS" python3 - <<'PYEOF2'
import json, os

settings_path = os.environ["SETTINGS"]
script_path = os.environ["SCRIPT_PATH"]

data = {}
if os.path.isfile(settings_path):
    try:
        with open(settings_path, encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        # битый/пустой файл — делаем бэкап и начинаем с чистого
        if os.path.getsize(settings_path) > 0:
            os.replace(settings_path, settings_path + ".bak")
        data = {}

data["statusLine"] = {
    "type": "command",
    "command": f"python3 {script_path}",
}

with open(settings_path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
    f.write("\n")

print(f"✓ settings.json обновлён: {settings_path}")
PYEOF2

echo
echo "Готово. Перезапусти Claude Code (или начни новую сессию), чтобы увидеть status line."
