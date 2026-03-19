# Claude Usage Widget

Real-time Claude spending tracker displayed in the tmux status bar and macOS menu bar.

## What It Shows

- **Remaining budget** for the current billing month vs. monthly cap
- **Burn rate vs. pace** — actual $/day spend alongside the $/day needed to finish on budget; burn turns red when exceeding pace
- **Depletion projection** — estimated date the budget runs out at current pace
- **Per-model breakdown** (Opus / Sonnet / Haiku) from local session data
- **macOS notifications** at 50%, 75%, and 90% of monthly cap (once per threshold per month)
- **⚡ LTM indicator** — shown in tmux bar and SwiftBar title when low token mode is active this session

## Files

| Path | Purpose |
|---|---|
| `~/claude-projects/claude-usage/claude_usage.py` | Main script |
| `~/.config/swiftbar/claude-usage.60s.py` | SwiftBar plugin (calls main script) |
| `~/.claude/usage-config.json` | Stored cap, reset day, calibration scale |
| `~/.claude/usage-cache.json` | Local JSONL parse cache (fast repeated calls) |
| `~/.claude/usage-api-cache.json` | Official API response cache (10-min TTL) |
| `~/.claude/usage-last-alert.json` | Alert debounce state |

## Data Sources

Two sources are merged automatically on every run:

**1. Official Anthropic API** (`GET https://api.anthropic.com/api/oauth/usage`)
- OAuth access token read from macOS Keychain entry `"Claude Code-credentials"` (written by `claude` CLI)
- Returns authoritative dollar amounts: `extra_usage.used_credits` and `extra_usage.monthly_limit` (in cents — divide by 100)
- Also returns 5-hour and 7-day rate-limit bucket utilisation percentages
- Result is cached locally for 10 minutes to avoid 429 rate limits

**2. Local JSONL parse** (`~/.claude/projects/**/*.jsonl`)
- Every Claude Code session writes one JSONL file per conversation
- `assistant`-type entries contain `.message.usage` with full token counts
- Cost is computed from token counts using published Anthropic API pricing
- Used as fallback when the API is unavailable, and always used for per-model breakdown
- Results are file-size-cached for fast repeated calls (~50ms)

When the official API succeeds, it overrides the monthly total and cap. Per-model numbers always come from JSONL.

## OAuth Token Lifecycle

The access token from the Keychain typically expires after ~1 hour. The script handles this automatically:

1. Reads `expiresAt` from the Keychain entry
2. If the token is within 5 minutes of expiry, calls `POST https://console.anthropic.com/v1/oauth/token` with the refresh token (long-lived, written by `claude` CLI at login)
3. If refresh fails, falls back to local JSONL data silently

The refresh token itself is long-lived and tied to your Claude login session. It only becomes invalid if you explicitly log out of Claude Code (`claude logout`) or revoke the OAuth app in Anthropic settings. In that case, running `claude` and logging in again re-writes the Keychain entry.

## Display Format

**tmux status bar** (example):
```
☁ █████░░░ $140 left | $18.9/$10.7/d | 13d ⚡LTM
         ^bar   ^remaining  ^burn ^pace       ^LTM flag (if active)
```
- Budget bar and remaining always colored by % used (green/yellow/red)
- Burn rate is red when burn > pace, green otherwise
- `⚡LTM` shown (red) when low token mode is active for the session; absent when disabled or not triggered

**SwiftBar menu bar** (title line):
```
⚡ ⚠️ ☁ $140 left          ← ⚡ prefix when LTM active; ⚠️ prefix when ≥50% used
```
Dropdown shows:
- `Burn: $X/day` — red when exceeding pace
- `Pace: $X/day to finish on track`

## Startup Behaviour

| Component | Auto-start |
|---|---|
| tmux status bar | Yes — configured in `~/.config/tmux/tmux.conf`, active whenever tmux is running |
| SwiftBar | Yes — added to macOS Login Items; launches SwiftBar.app on login |

SwiftBar reads the plugin from `~/.config/swiftbar/` (configured in SwiftBar preferences).

## Commands

```bash
# Show status (same as tmux bar, but in terminal)
python3 ~/claude-projects/claude-usage/claude_usage.py

# Force a fresh official API fetch (bypass 10-min cache)
python3 ~/claude-projects/claude-usage/claude_usage.py tmux --refresh-api

# Force a full local JSONL reparse
python3 ~/claude-projects/claude-usage/claude_usage.py tmux --refresh

# Print raw official API JSON (always bypasses cache)
python3 ~/claude-projects/claude-usage/claude_usage.py official

# Machine-readable JSON (all fields)
python3 ~/claude-projects/claude-usage/claude_usage.py json

# Update monthly cap (e.g. if Anthropic changes your limit)
python3 ~/claude-projects/claude-usage/claude_usage.py set-cap 480

# Calibrate local estimate to official number
# (only needed if API is unavailable long-term; API normally overrides this)
python3 ~/claude-projects/claude-usage/claude_usage.py calibrate 142.20
```

## Pricing Constants

The local JSONL cost computation uses these rates (per million tokens):

| Model | Input | Output | Cache write | Cache read |
|---|---|---|---|---|
| Opus | $15.00 | $75.00 | $18.75 | $1.50 |
| Sonnet | $3.00 | $15.00 | $3.75 | $0.30 |
| Haiku | $0.80 | $4.00 | $1.00 | $0.08 |

Subscription plans bill at approximately 50% of these API rates. The official API overrides the local estimate anyway, so pricing drift only matters when the API is unavailable.

Update `PRICING` in `claude_usage.py` if Anthropic changes rates.

## Troubleshooting

**SwiftBar shows stale data** — Click the menu bar item → Refresh, or run `python3 claude_usage.py tmux --refresh-api`.

**API returns 429 (rate limited)** — You've been calling the endpoint too frequently. The 10-minute cache prevents this under normal use. Wait a few minutes; it will self-heal.

**API returns 401 (unauthorized)** — OAuth token invalid. Run `claude` in a terminal; if it asks you to log in again, do so. This re-writes the Keychain entry.

**SwiftBar not showing** — Check that SwiftBar.app is running (`open -a SwiftBar`), and that the plugin is in `~/.config/swiftbar/`. Check SwiftBar preferences → Plugin folder.

**tmux bar not updating** — Run `tmux source-file ~/.config/tmux/tmux.conf` to reload config.
