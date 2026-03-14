#!/usr/bin/env python3
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>
import subprocess, sys
result = subprocess.run(
    [sys.executable, str(__import__("pathlib").Path.home() / "claude-projects/claude-usage/claude_usage.py"), "swiftbar"],
    capture_output=True, text=True
)
print(result.stdout, end="")
