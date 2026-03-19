#!/usr/bin/env python3
"""Claude Code usage tracker — tmux status bar and SwiftBar menu bar widget.

Two data sources (automatically merged):
  1. Official Anthropic API  — reads OAuth token from macOS Keychain, calls
     GET https://api.anthropic.com/api/oauth/usage  (returns dollar amounts
     directly for Max/Enterprise plans via extra_usage, and utilization
     percentages for the rolling 5-hour and 7-day rate-limit buckets).
  2. Local JSONL parse — scans ~/.claude/projects/**/*.jsonl and computes
     cost from token counts using published API pricing.  Used as fallback
     when the official API is unavailable, and for per-model breakdowns.

Usage:
    claude_usage.py tmux        # budget-aware status for tmux
    claude_usage.py swiftbar    # SwiftBar plugin output with dropdown
    claude_usage.py json        # machine-readable JSON
    claude_usage.py official    # print raw official API response and exit
    claude_usage.py             # defaults to tmux
    claude_usage.py set-cap 150 # set monthly budget cap
    claude_usage.py calibrate 142.20  # sync month spend to official number

Add --refresh to force a full local-JSONL cache rebuild.
Add --no-api   to skip the official API call (local JSONL only).
"""

import calendar
import json
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from collections import defaultdict
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

CLAUDE_DIR = Path.home() / ".claude"
PROJECTS_DIR = CLAUDE_DIR / "projects"
CACHE_FILE = CLAUDE_DIR / "usage-cache.json"
CONFIG_FILE = CLAUDE_DIR / "usage-config.json"
API_CACHE_FILE = CLAUDE_DIR / "usage-api-cache.json"
API_CACHE_TTL_SECONDS = 600  # re-fetch at most once per 10 minutes

# Keychain entry written by Claude Code CLI
KEYCHAIN_SERVICE = "Claude Code-credentials"

# Official Anthropic OAuth API
USAGE_URL = "https://api.anthropic.com/api/oauth/usage"
PROFILE_URL = "https://api.anthropic.com/api/oauth/profile"
TOKEN_REFRESH_URL = "https://console.anthropic.com/v1/oauth/token"
OAUTH_CLIENT_ID = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
OAUTH_BETA_HEADER = "oauth-2025-04-20"
USER_AGENT = "claude-code/2.1.62"

# Pricing per million tokens (USD) — update when Anthropic changes pricing
# (input, output, cache_write, cache_read)
PRICING = {
    "opus":   (15.0, 75.0, 18.75, 1.50),
    "sonnet": (3.0,  15.0, 3.75,  0.30),
    "haiku":  (0.80, 4.0,  1.0,   0.08),
}

# Alert thresholds (fraction of monthly cap)
THRESHOLDS = [
    (0.90, "red",    "CRITICAL"),
    (0.75, "orange", "WARNING"),
    (0.50, "yellow", ""),
]


# ---------------------------------------------------------------------------
# Official API: keychain read + HTTP calls
# ---------------------------------------------------------------------------

def read_keychain_token():
    """Return (access_token, refresh_token, expires_at_ms) from macOS Keychain,
    or (None, None, None) if not found or not on macOS."""
    try:
        result = subprocess.run(
            ["security", "find-generic-password", "-s", KEYCHAIN_SERVICE, "-w"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode != 0:
            return None, None, None
        raw = result.stdout.strip()
        data = json.loads(raw)
        # Claude Code wraps under "claudeAiOauth"
        oauth = data.get("claudeAiOauth", data)
        access = oauth.get("accessToken") or oauth.get("access_token")
        refresh = oauth.get("refreshToken") or oauth.get("refresh_token")
        expires = oauth.get("expiresAt") or oauth.get("expires_at")
        return access, refresh, expires
    except Exception:
        return None, None, None


def refresh_access_token(refresh_token):
    """Exchange a refresh token for a new access token.
    Returns (new_access_token, new_refresh_token, expires_at_ms) or (None, None, None)."""
    try:
        body = urllib.parse.urlencode({
            "grant_type": "refresh_token",
            "refresh_token": refresh_token,
            "client_id": OAUTH_CLIENT_ID,
        }).encode()
        req = urllib.request.Request(
            TOKEN_REFRESH_URL,
            data=body,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read())
        new_access = data.get("access_token")
        new_refresh = data.get("refresh_token", refresh_token)
        expires_in = data.get("expires_in", 3600)
        expires_at_ms = int(time.time() * 1000) + expires_in * 1000
        return new_access, new_refresh, expires_at_ms
    except Exception:
        return None, None, None


def get_valid_token():
    """Return a valid access token, refreshing if necessary.
    Returns (access_token, source_note) where source_note is 'keychain' or 'refreshed'."""
    access, refresh, expires_at = read_keychain_token()
    if not access:
        return None, "no keychain entry"

    now_ms = int(time.time() * 1000)
    # Refresh if expired or expiring within 5 minutes
    if expires_at and now_ms >= (expires_at - 300_000):
        if refresh:
            new_access, new_refresh, _ = refresh_access_token(refresh)
            if new_access:
                return new_access, "refreshed"
        return None, "token expired and refresh failed"

    return access, "keychain"


def fetch_official_usage(access_token):
    """Call the Anthropic usage API. Returns the parsed JSON dict or None."""
    try:
        req = urllib.request.Request(
            USAGE_URL,
            headers={
                "Authorization": f"Bearer {access_token}",
                "anthropic-beta": OAUTH_BETA_HEADER,
                "User-Agent": USER_AGENT,
            }
        )
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        if e.code == 401:
            return {"_error": "unauthorized"}
        return {"_error": f"http_{e.code}"}
    except Exception as e:
        return {"_error": str(e)}


def fetch_official_usage_cached(access_token, force=False):
    """Return official usage JSON, using a local cache to avoid hammering the API.
    Re-fetches at most once per API_CACHE_TTL_SECONDS unless force=True."""
    now = time.time()
    if not force and API_CACHE_FILE.exists():
        try:
            cached = json.loads(API_CACHE_FILE.read_text())
            if now - cached.get("fetched_at", 0) < API_CACHE_TTL_SECONDS:
                return cached.get("data")
        except (json.JSONDecodeError, IOError):
            pass
    data = fetch_official_usage(access_token)
    if "_error" not in data:
        try:
            API_CACHE_FILE.write_text(json.dumps({"fetched_at": now, "data": data}))
        except IOError:
            pass
    return data


def parse_official_response(data):
    """Extract structured fields from the official API response dict.

    The response has these fields (all may be null):
      five_hour          — rolling 5-hour session bucket: {utilization, resets_at}
      seven_day          — rolling 7-day bucket (all models): {utilization, resets_at}
      seven_day_sonnet   — 7-day Sonnet-only bucket
      seven_day_opus     — 7-day Opus-only bucket
      seven_day_oauth_apps — 7-day OAuth apps bucket
      seven_day_cowork   — 7-day cowork bucket
      extra_usage        — additional spend beyond subscription:
                             {is_enabled, monthly_limit, used_credits, utilization}

    For Max/Enterprise plans that show dollar amounts (like "$142.20/$150"):
      extra_usage.used_credits  — dollars spent this month
      extra_usage.monthly_limit — monthly cap in dollars

    For Pro plans with only utilization percentages, extra_usage is absent
    and the five_hour/seven_day buckets show fractional utilization.
    """
    if not data or "_error" in data:
        return None

    eu = data.get("extra_usage") or {}
    # API returns values in cents — convert to dollars
    raw_used = eu.get("used_credits")
    raw_limit = eu.get("monthly_limit")
    result = {
        "has_dollar_data": bool(eu and raw_limit),
        "monthly_used": raw_used / 100 if raw_used is not None else None,
        "monthly_limit": raw_limit / 100 if raw_limit is not None else None,
        "monthly_utilization_pct": eu.get("utilization"),
        "extra_usage_enabled": eu.get("is_enabled", False),
    }

    for bucket in ("five_hour", "seven_day", "seven_day_sonnet", "seven_day_opus",
                   "seven_day_oauth_apps", "seven_day_cowork"):
        b = data.get(bucket)
        result[bucket] = {
            "utilization": b["utilization"] if b else None,
            "resets_at": b.get("resets_at") if b else None,
        }

    return result


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

def load_config():
    defaults = {"monthly_cap": 150.0, "reset_day": 1, "calibration_offset": 0.0, "calibration_month": ""}
    if CONFIG_FILE.exists():
        try:
            stored = json.loads(CONFIG_FILE.read_text())
            defaults.update(stored)
        except (json.JSONDecodeError, IOError):
            pass
    return defaults


def save_config(cfg):
    CONFIG_FILE.write_text(json.dumps(cfg, indent=2) + "\n")


def model_tier(model_id):
    m = model_id.lower()
    if "opus" in m:
        return "opus"
    if "haiku" in m:
        return "haiku"
    return "sonnet"


def compute_msg_cost(usage, model_id):
    p = PRICING[model_tier(model_id)]
    return (
        usage.get("input_tokens", 0) * p[0]
        + usage.get("output_tokens", 0) * p[1]
        + usage.get("cache_creation_input_tokens", 0) * p[2]
        + usage.get("cache_read_input_tokens", 0) * p[3]
    ) / 1_000_000


def parse_jsonl(path):
    entries = []
    with open(path, "r") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue
            if obj.get("type") != "assistant":
                continue
            msg = obj.get("message", {})
            model = msg.get("model", "")
            usage = msg.get("usage", {})
            if not usage or not model:
                continue
            ts = obj.get("timestamp", "")
            if ts:
                try:
                    local_date = datetime.fromisoformat(ts.replace("Z", "+00:00")).astimezone().strftime("%Y-%m-%d")
                except ValueError:
                    local_date = ts[:10]
            else:
                local_date = ""
            entries.append({
                "date": local_date,
                "model": model,
                "cost": compute_msg_cost(usage, model),
            })
    return entries


def load_cache():
    if CACHE_FILE.exists():
        try:
            return json.loads(CACHE_FILE.read_text())
        except (json.JSONDecodeError, IOError):
            pass
    return {}


def save_cache(cache):
    CACHE_FILE.write_text(json.dumps(cache))


def gather_usage(force_refresh=False):
    if not PROJECTS_DIR.exists():
        return []
    cache = {} if force_refresh else load_cache()
    all_entries = []
    new_cache = {}

    for path in PROJECTS_DIR.rglob("*.jsonl"):
        key = str(path)
        size = path.stat().st_size
        if not force_refresh and key in cache and cache[key].get("size") == size:
            all_entries.extend(cache[key]["entries"])
            new_cache[key] = cache[key]
        else:
            entries = parse_jsonl(path)
            new_cache[key] = {"size": size, "entries": entries}
            all_entries.extend(entries)

    save_cache(new_cache)
    return all_entries


def aggregate(entries, config, official=None):
    """Aggregate local JSONL entries into totals.

    If `official` is a parsed official-API response dict (from parse_official_response),
    and it contains dollar data (extra_usage.monthly_limit is set), the official
    used_credits value overrides the local monthly estimate.
    """
    today_str = date.today().isoformat()
    week_start = (date.today() - timedelta(days=date.today().weekday())).isoformat()
    month_start = date.today().replace(day=1).isoformat()
    current_month = date.today().strftime("%Y-%m")

    totals = {
        "today": 0.0,
        "week": 0.0,
        "month": 0.0,
        "all_time": 0.0,
        "by_model": defaultdict(float),
        "month_by_model": defaultdict(float),
        "today_by_model": defaultdict(float),
        "daily_costs": defaultdict(float),
        "messages": len(entries),
        "official": official,
        "official_source": "api" if official else None,
    }

    for e in entries:
        cost = e["cost"]
        d = e["date"]
        tier = model_tier(e["model"])

        totals["all_time"] += cost
        totals["by_model"][tier] += cost

        if d >= month_start:
            totals["month"] += cost
            totals["month_by_model"][tier] += cost
            totals["daily_costs"][d] += cost
        if d >= week_start:
            totals["week"] += cost
        if d == today_str:
            totals["today"] += cost
            totals["today_by_model"][tier] += cost

    # Apply calibration scale factor if it's for the current month
    scale = 1.0
    if config.get("calibration_month") == current_month and config.get("calibration_scale"):
        scale = config["calibration_scale"]
    totals["month"] *= scale
    totals["today"] *= scale
    totals["week"] *= scale
    totals["all_time"] *= scale
    for k in list(totals["by_model"]):
        totals["by_model"][k] *= scale
    for k in list(totals["month_by_model"]):
        totals["month_by_model"][k] *= scale
    for k in list(totals["today_by_model"]):
        totals["today_by_model"][k] *= scale
    for k in list(totals["daily_costs"]):
        totals["daily_costs"][k] *= scale

    # Override monthly total with official API value if available
    if official and official.get("has_dollar_data"):
        totals["month"] = official["monthly_used"]
        totals["official_source"] = "api_dollar"

    # Budget calculations — prefer official monthly_limit if set
    cap = config.get("monthly_cap", 150.0)
    if official and official.get("monthly_limit"):
        cap = official["monthly_limit"]
    totals["cap"] = cap
    totals["remaining"] = max(0, cap - totals["month"])
    totals["pct_used"] = (totals["month"] / cap * 100) if cap > 0 else 0

    # Days remaining in billing period
    today_obj = date.today()
    days_in_month = calendar.monthrange(today_obj.year, today_obj.month)[1]
    totals["days_left"] = days_in_month - today_obj.day
    totals["days_elapsed"] = today_obj.day

    # Burn rate and projection
    if totals["days_elapsed"] > 0:
        totals["daily_avg"] = totals["month"] / totals["days_elapsed"]
        totals["projected_month"] = totals["daily_avg"] * days_in_month
        if totals["daily_avg"] > 0:
            days_until_depleted = totals["remaining"] / totals["daily_avg"]
            depletion_date = today_obj + timedelta(days=days_until_depleted)
            totals["depletion_date"] = depletion_date.isoformat()
            totals["days_until_depleted"] = days_until_depleted
        else:
            totals["depletion_date"] = None
            totals["days_until_depleted"] = float("inf")
    else:
        totals["daily_avg"] = totals["month"]
        totals["projected_month"] = totals["month"]
        totals["depletion_date"] = None
        totals["days_until_depleted"] = float("inf")

    # Daily budget to stay on track
    if totals["days_left"] > 0:
        totals["daily_budget"] = totals["remaining"] / totals["days_left"]
    else:
        totals["daily_budget"] = totals["remaining"]

    # Alert level
    totals["alert"] = ""
    totals["alert_color"] = "green"
    for threshold, color, label in THRESHOLDS:
        if totals["pct_used"] >= threshold * 100:
            totals["alert"] = label
            totals["alert_color"] = color
            break

    return totals


def fmt(v):
    if v >= 100:
        return f"${v:.0f}"
    if v >= 10:
        return f"${v:.1f}"
    return f"${v:.2f}"


def output_tmux(t):
    remaining = fmt(t["remaining"])
    pct = t["pct_used"]
    days = t["days_left"]
    burn = t["daily_avg"]
    pace = t["daily_budget"]
    reset = "#[default]"

    # Budget bar color
    if pct >= 90:
        bar_color = "#[fg=red,bold]"
    elif pct >= 75:
        bar_color = "#[fg=yellow]"
    else:
        bar_color = "#[fg=green]"

    bar_len = 8
    filled = min(bar_len, int(pct / 100 * bar_len))
    bar = "█" * filled + "░" * (bar_len - filled)

    # Burn rate colored red when exceeding pace
    burn_color = "#[fg=red,bold]" if burn > pace else "#[fg=green]"
    rate_str = f"{burn_color}{fmt(burn)}{reset}/{fmt(pace)}/d"

    # LTM indicator
    ltm_str = ""
    sentinel = CLAUDE_DIR / "hooks/sentinels/low-token-warned"
    disabled = CLAUDE_DIR / "hooks/sentinels/low-token-disabled"
    if not disabled.exists() and sentinel.exists() and sentinel.read_text().strip():
        ltm_str = f" {burn_color}⚡LTM{reset}"

    print(f"☁ {bar_color}{bar} {remaining} left{reset} | {rate_str} | {days}d{ltm_str}")


def output_swiftbar(t):
    remaining = fmt(t["remaining"])
    cap = fmt(t["cap"])
    pct = t["pct_used"]
    color = t["alert_color"]
    official = t.get("official") or {}

    # Menu bar title — remaining budget with color
    sfcolor = {"green": "#22c55e", "yellow": "#eab308", "orange": "#f97316", "red": "#ef4444"}.get(color, "#ffffff")
    alert_prefix = "⚠️ " if t["alert"] else ""
    ltm_sentinel = CLAUDE_DIR / "hooks/sentinels/low-token-warned"
    ltm_disabled = CLAUDE_DIR / "hooks/sentinels/low-token-disabled"
    ltm_active = (not ltm_disabled.exists() and ltm_sentinel.exists()
                  and ltm_sentinel.read_text().strip())
    ltm_prefix = "⚡ " if ltm_active else ""
    print(f"{ltm_prefix}{alert_prefix}☁ {remaining} left | color={sfcolor}")
    print("---")

    # Source indicator
    src = t.get("official_source", "local")
    src_label = {"api_dollar": "official API", "api": "official API (utilization only)", "local": "local estimate"}.get(src, src)
    print(f"Source: {src_label}")

    # Budget overview
    print(f"Budget: {fmt(t['month'])} / {cap} ({pct:.0f}%)")
    print(f"Remaining: {remaining}")
    print(f"Days left: {t['days_left']}")
    print("---")

    # Official rate-limit buckets (only show non-null ones)
    if official:
        shown_any = False
        for key, label in [
            ("five_hour", "5-hour session"),
            ("seven_day", "7-day (all models)"),
            ("seven_day_sonnet", "7-day Sonnet"),
            ("seven_day_opus", "7-day Opus"),
        ]:
            b = official.get(key, {})
            util = b.get("utilization") if b else None
            if util is not None:
                shown_any = True
                resets = b.get("resets_at", "")
                reset_str = f" — resets {resets[:10]}" if resets else ""
                bar_len = 8
                filled = min(bar_len, int(util / 100 * bar_len))
                bar = "█" * filled + "░" * (bar_len - filled)
                color_key = "red" if util >= 95 else "orange" if util >= 90 else "green"
                sfbar_color = {"green": "#22c55e", "orange": "#f97316", "red": "#ef4444"}[color_key]
                print(f"{label}: {bar} {util:.0f}%{reset_str} | color={sfbar_color}")
        if shown_any:
            print("---")

    # Burn rate & projection
    burn_over_pace = t["daily_avg"] > t["daily_budget"]
    sfburn = "#ef4444" if burn_over_pace else "#22c55e"
    print(f"Burn: {fmt(t['daily_avg'])}/day | color={sfburn}")
    daily_budget = fmt(t["daily_budget"])
    print(f"Pace: {daily_budget}/day to finish on track")
    if t.get("depletion_date") and t["days_until_depleted"] < t["days_left"]:
        print(f"⚠️ At this rate, depletes {t['depletion_date']} | color=red")
    elif t["projected_month"] <= t["cap"]:
        print(f"On track — projected {fmt(t['projected_month'])} this month | color=green")
    else:
        print(f"Over budget — projected {fmt(t['projected_month'])} | color=orange")
    print("---")

    # This month by model (from local JSONL — gives per-model breakdown)
    print("This month by model (local estimate)")
    for tier in ("opus", "sonnet", "haiku"):
        cost = t["month_by_model"].get(tier, 0)
        if cost > 0:
            print(f"-- {tier.capitalize()}: {fmt(cost)}")

    # Today
    print("---")
    print(f"Today: {fmt(t['today'])}")
    if t["today"] > 0:
        for tier in ("opus", "sonnet", "haiku"):
            cost = t["today_by_model"].get(tier, 0)
            if cost > 0:
                print(f"-- {tier.capitalize()}: {fmt(cost)}")

    print("---")
    print(f"All time: {fmt(t['all_time'])}")
    print(f"Messages: {t['messages']:,}")
    print("---")
    print(f"Cap: {cap} | Set: claude_usage.py set-cap <amount>")
    print(f"Updated: {datetime.now().strftime('%H:%M')}")


def output_json(t):
    out = {
        "today": round(t["today"], 4),
        "week": round(t["week"], 4),
        "month": round(t["month"], 4),
        "all_time": round(t["all_time"], 4),
        "cap": t["cap"],
        "remaining": round(t["remaining"], 4),
        "pct_used": round(t["pct_used"], 2),
        "daily_avg": round(t["daily_avg"], 4),
        "daily_budget": round(t["daily_budget"], 4),
        "projected_month": round(t["projected_month"], 4),
        "depletion_date": t.get("depletion_date"),
        "days_left": t["days_left"],
        "alert": t["alert"],
        "by_model": {k: round(v, 4) for k, v in t["by_model"].items()},
        "month_by_model": {k: round(v, 4) for k, v in t["month_by_model"].items()},
        "messages": t["messages"],
        "official_source": t.get("official_source"),
    }
    if t.get("official"):
        out["official_api"] = t["official"]
    print(json.dumps(out, indent=2))


def send_notification(title, message):
    try:
        subprocess.run([
            "osascript", "-e",
            f'display notification "{message}" with title "{title}"'
        ], check=False, capture_output=True)
    except Exception:
        pass


def check_alerts(t, config):
    alert_file = CLAUDE_DIR / "usage-last-alert.json"
    current_month = date.today().strftime("%Y-%m")
    pct = t["pct_used"]

    last = {}
    if alert_file.exists():
        try:
            last = json.loads(alert_file.read_text())
        except (json.JSONDecodeError, IOError):
            pass

    last_month = last.get("month", "")
    last_pct = last.get("threshold", 0)

    if last_month != current_month:
        last_pct = 0

    for threshold, _, label in THRESHOLDS:
        thr_pct = threshold * 100
        if pct >= thr_pct and last_pct < thr_pct:
            remaining = fmt(t["remaining"])
            send_notification(
                f"Claude Budget {label}" if label else "Claude Budget",
                f"{pct:.0f}% used — {remaining} remaining of {fmt(t['cap'])}"
            )
            alert_file.write_text(json.dumps({"month": current_month, "threshold": thr_pct}))
            break


if __name__ == "__main__":
    args = sys.argv[1:]

    # Handle config commands
    if args and args[0] == "set-cap":
        cfg = load_config()
        cfg["monthly_cap"] = float(args[1])
        save_config(cfg)
        print(f"Monthly cap set to ${cfg['monthly_cap']:.2f}")
        sys.exit(0)

    if args and args[0] == "calibrate":
        cfg = load_config()
        official_val = float(args[1])
        entries = gather_usage()
        raw_totals = aggregate(entries, {**cfg, "calibration_scale": None, "calibration_month": ""})
        raw_month = raw_totals["month"]
        if raw_month > 0:
            scale = official_val / raw_month
        else:
            scale = 1.0
        cfg["calibration_scale"] = round(scale, 6)
        cfg["calibration_month"] = date.today().strftime("%Y-%m")
        save_config(cfg)
        print(f"Calibrated: local={fmt(raw_month)}, official={fmt(official_val)}, scale={scale:.3f}x")
        print(f"(Subscription pricing is ~{scale:.0%} of published API rates)")
        sys.exit(0)

    # Print raw official API response and exit (always bypasses cache)
    if args and args[0] == "official":
        token, source = get_valid_token()
        if not token:
            print(f"No token available: {source}", file=sys.stderr)
            sys.exit(1)
        raw = fetch_official_usage(token)
        print(f"Token source: {source}")
        print(json.dumps(raw, indent=2))
        sys.exit(0)

    mode = next((a for a in args if a in ("tmux", "swiftbar", "json")), "tmux")
    force = "--refresh" in args
    skip_api = "--no-api" in args
    force_api = "--refresh-api" in args

    config = load_config()
    entries = gather_usage(force_refresh=force)

    # Fetch official API data unless suppressed; use cache to avoid 429s
    official_parsed = None
    if not skip_api:
        token, _source = get_valid_token()
        if token:
            raw_api = fetch_official_usage_cached(token, force=force_api)
            official_parsed = parse_official_response(raw_api)

    totals = aggregate(entries, config, official=official_parsed)

    {"tmux": output_tmux, "swiftbar": output_swiftbar, "json": output_json}[mode](totals)

    # Check alerts (runs on every invocation, but notifications are debounced per threshold)
    check_alerts(totals, config)
