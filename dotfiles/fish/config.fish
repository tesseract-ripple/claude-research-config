        # fix autosuggestion color
	function bobthefish_colors -S -d 'Neon Orchid color scheme for bobthefish'
	    # Use brblack (now defined as visible purple in Kitty)
	    set -gx fish_color_autosuggestion brblack
	    # make primary text match kitty terminal's pink
            set -gx fish_color_command brmagenta #external commands 
            set -gx fish_color_param magenta #parameters
            set -gx fish_color_keyword cyan #keywords like 'function'
	end
if status is-interactive
	#### fonts, theme customization
	set -g theme_nerd_fonts yes
	set -g theme_color_scheme terminal-dark

	#### vim keybindings and vim-style autocomplete

	# Accept autosuggestion with Ctrl+L (like in vim, clear and accept)
	bind -M insert \cl forward-char

	# Or use Ctrl+F (forward)
	bind -M insert \cf accept-autosuggestion

	# Or use Ctrl+E (end of line)
	bind -M insert \ce accept-autosuggestion

	# Accept one word at a time with Ctrl+W
	bind -M insert \cw forward-word

	# In normal mode, use 'l' to accept
	bind -M default l forward-char

	# make ESC faster
	set -g fish_escape_delay_ms 10

	#### tmux init
	if not set -q SKIP_TMUX
	    if not tmux info >/dev/null 2>&1
		tmux attach || tmux new
	    end
	end
        
        #### pyenv setup
        pyenv init - | source



end
