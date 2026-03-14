# TMUX CHEATSHEET
Prefix: Ctrl+Space

## Windows (tabs)
^Space c     - new window
^Space n/p   - next/previous window
^Space w     - list windows
^Space ,     - rename window
^Space &     - kill window

## Panes (splits)
^Space %     - vertical split
^Space "     - horizontal split
Alt+h/j/k/l  - navigate panes (no prefix needed)
^Space o     - cycle through panes (avoid: buggy w/ Claude input)
^Space x     - kill pane
^Space z     - zoom/unzoom pane
^Space {/}   - swap pane left/right

## Copy Mode
^Space [     - enter copy mode
  v          - start selection (vi mode)
  y          - yank/copy
  q/Esc      - exit
^Space ]     - paste

## Sessions
^Space d     - detach session
^Space s     - list sessions

## This Cheatsheet
^Space h     - toggle this popup

# READLINE CHEATSHEET
(works in bash, fish, Claude Code input, most terminal prompts)

## Cursor Movement
Ctrl+b       - back one char
Ctrl+f       - forward one char
Ctrl+a       - beginning of line
Ctrl+e       - end of line
Alt+b        - back one word
Alt+f        - forward one word

## Editing
Ctrl+k       - kill to end of line
Ctrl+u       - kill to start of line
Ctrl+w       - kill word backward
Alt+d        - kill word forward
Ctrl+y       - yank (paste killed text)
Ctrl+t       - transpose chars

## History
Ctrl+r       - reverse search history
Ctrl+p/n     - previous/next history entry

## Other
Ctrl+l       - clear screen
Ctrl+_       - undo

# AMETHYST CHEATSHEET
AMETHYST (⌥⇧ = Mod, ⌃⌥⇧ = Mod2)

LAYOUTS
Mod+Space/Mod2+Space  cycle layout fwd/back
Mod+,/.               inc/dec main pane count
Mod+H/L               shrink/expand main
Mod+A/S/D/F           Tall/Wide/Fullscreen/Column

FOCUS
Mod+J/K              focus counter/clockwise
Mod+M                focus main window
Mod+P/N              focus counter/clockwise screen
Mod+W/E/R/Q/G        focus screen 1/2/3/4/5

MOVE
Mod2+J/K             swap counter/clockwise
Mod+↩                swap with main
Mod2+H/L             swap to counter/clockwise screen
Mod2+←/→             throw to space left/right
Mod2+1-7             throw to space 1-7
Mod2+W/E/R/Q/G       throw to screen 1-5

OTHER
Mod+T                toggle float
Mod+I                display layout
Mod+Z                reflow windows
Mod2+X               toggle focus follows mouse
Mod2+T               toggle global tiling
Mod2+Z               relaunch Amethyst
