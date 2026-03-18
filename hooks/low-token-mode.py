#!/usr/bin/env python3
"""UserPromptSubmit hook: inject a one-time budget warning when spend rate
exceeds what's needed to finish the month within cap.

Fires at most once per session. Reads existing cache files — no API calls.
Message is intentionally short; behavioral rules live in CLAUDE.md.
"""
import json, sys, calendar
from datetime import date
from pathlib import Path

home = Path.home()
SENTINEL_F   = home / ".claude/hooks/sentinels/low-token-warned"
API_CACHE_F  = home / ".claude/usage-api-cache.json"
LOCAL_CACHE_F = home / ".claude/usage-cache.json"
CONFIG_F     = home / ".claude/usage-config.json"

def main():
    SENTINEL_F.parent.mkdir(parents=True, exist_ok=True)

    # Read session_id from hook payload on stdin
    session_id = ""
    try:
        session_id = json.load(sys.stdin).get("session_id", "")
    except Exception:
        pass

    # Fire at most once per session
    if session_id and SENTINEL_F.exists() and session_id in SENTINEL_F.read_text():
        return

    # --- Get monthly spend and cap ---
    monthly_used = monthly_cap = None

    # Authoritative: API cache (populated by usage widget, no new calls)
    try:
        d = json.loads(API_CACHE_F.read_text())
        eu = (d.get("data") or {}).get("extra_usage") or {}
        v, lim = eu.get("used_credits"), eu.get("monthly_limit")
        if v is not None and lim is not None:
            monthly_used, monthly_cap = v / 100, lim / 100
    except Exception:
        pass

    # Fallback: local JSONL cache for monthly_used
    if monthly_used is None and LOCAL_CACHE_F.exists():
        try:
            cache = json.loads(LOCAL_CACHE_F.read_text())
            month_start = date.today().replace(day=1).isoformat()
            monthly_used = round(sum(
                e["cost"]
                for v in cache.values()
                for e in v.get("entries", [])
                if e.get("date", "") >= month_start
            ), 2)
        except Exception:
            pass

    # Cap from config
    if monthly_cap is None and CONFIG_F.exists():
        try:
            monthly_cap = json.loads(CONFIG_F.read_text()).get("monthly_cap")
        except Exception:
            pass

    if monthly_used is None or monthly_cap is None:
        return

    # --- Pace calculation ---
    today = date.today()
    days_in_month = calendar.monthrange(today.year, today.month)[1]
    days_elapsed  = today.day
    days_left     = days_in_month - today.day

    # Skip first 2 days (burn estimate too noisy) and last day
    if days_elapsed < 3 or days_left <= 0:
        return

    burn      = monthly_used / days_elapsed
    remaining = max(0.0, monthly_cap - monthly_used)
    pace      = remaining / days_left

    if burn <= pace:
        return

    # --- Warn ---
    if session_id:
        with open(SENTINEL_F, "a") as f:
            f.write(session_id + "\n")

    pct = int(monthly_used / monthly_cap * 100)
    msg = (
        f"\u26a0\ufe0f LOW BUDGET: ${monthly_used:.0f}/${monthly_cap:.0f} ({pct}%) "
        f"\u00b7 ${burn:.1f}/day burn vs ${pace:.1f}/day pace. "
        f"Low Token Mode active \u2014 see CLAUDE.md."
    )
    print(json.dumps({"systemMessage": msg}))

main()
