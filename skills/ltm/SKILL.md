---
name: ltm
description: Toggle low token mode on/off for this command or the rest of the session.
argument-hint: "[once|session|status|on]"
---

Manage low token mode (LTM). LTM is active when the budget pace hook has injected a warning this session.

**Sentinel files:**
- `~/.claude/hooks/sentinels/low-token-warned` — sessions already warned (written by hook)
- `~/.claude/hooks/sentinels/low-token-disabled` — manual full-session disable (you create/delete this)
- `~/.claude/hooks/sentinels/low-token-override-once` — skip hook on the very next prompt (consumed on use)

**Steps:**

1. Check current state:
   ```bash
   ls -la ~/.claude/hooks/sentinels/low-token-warned ~/.claude/hooks/sentinels/low-token-disabled ~/.claude/hooks/sentinels/low-token-override-once 2>/dev/null
   ```

2. Based on `$ARGUMENTS`:

   - **`status`** (or empty with no intent to toggle): Report current state and exit. State:
     - LTM active = `low-token-warned` is non-empty
     - Session-disabled = `low-token-disabled` exists
     - Override-once queued = `low-token-override-once` exists

   - **`once`** or **`1`**: Suspend for next command only.
     ```bash
     touch ~/.claude/hooks/sentinels/low-token-override-once
     ```
     Tell the user: "LTM suspended for the next command. Normal model selection and verbosity apply for that one prompt; the hook will resume afterwards."
     Then apply normal (non-LTM) behaviour for your **current** response.

   - **`session`** or **`full`** or **`2`**: Disable for the rest of this session.
     ```bash
     touch ~/.claude/hooks/sentinels/low-token-disabled
     ```
     Tell the user: "LTM disabled for this session. The hook will not reinject the warning again. Normal behaviour resumes now."
     Then apply normal (non-LTM) behaviour for the rest of this session.

   - **`on`** or **`re-enable`**: Re-enable LTM (remove disable sentinels).
     ```bash
     rm -f ~/.claude/hooks/sentinels/low-token-disabled ~/.claude/hooks/sentinels/low-token-override-once
     ```
     Tell the user: "LTM re-enabled. The hook will evaluate budget pace on the next prompt."

   - **No arguments**: Ask the user:
     > "Disable low token mode for:  [1] This command only  [2] Rest of session  [3] Cancel"
     Then act on their response as above.

**After toggling**, briefly summarise: what changed, what sentinel file was created/removed, and what behaviour applies going forward.
