-- Tmux's Ctrl+A prefix and the Ctrl+A, Space which-key hierarchy.
-- Rex shows key-sequence hints as each prefix is pressed. Entries that need
-- tmux-specific features (copy mode, buffers, plugins, and the tmux dashboard)
-- have no equivalent in Rex and are intentionally not bound.

-- Direct tmux bindings.
rex.bind("ctrl+a>c", "client.tab.new")
rex.bind("ctrl+a>n", "client.tab.next")
rex.bind("ctrl+a>p", "client.tab.previous")
rex.bind("ctrl+a>s", "session.switch")
rex.bind("ctrl+a>shift+\\", "pane.split.right") -- |
rex.bind("ctrl+a>-", "pane.split.down")
rex.bind("ctrl+a>z", "pane.zoom")
rex.bind("ctrl+a>x", "pane.close")
rex.bind("ctrl+a>ctrl+a", "pane.send_key", { key = "ctrl+a" })

-- Tmux-which-key root: Ctrl+A, Space.
rex.bind("ctrl+a>space>space", "client.palette.toggle") -- Run
rex.bind("ctrl+a>space>,", "session.rename")
rex.bind("ctrl+a>space>`", "pane.focus_previous")
rex.bind("ctrl+a>space>r", "client.config.reload")
rex.bind("ctrl+a>space>shift+/", "client.palette.toggle") -- ? (actions help)

-- Windows: Rex tabs are the closest equivalent to tmux windows.
rex.bind("ctrl+a>space>w>w", "client.palette.toggle") -- choose a tab
rex.bind("ctrl+a>space>w>p", "client.tab.previous")
rex.bind("ctrl+a>space>w>n", "client.tab.next")
rex.bind("ctrl+a>space>w>c", "client.tab.new")
rex.bind("ctrl+a>space>w>/", "pane.split.right")
rex.bind("ctrl+a>space>w>-", "pane.split.down")
rex.bind("ctrl+a>space>w>r", "client.tab.rename")
rex.bind("ctrl+a>space>w>shift+x", "client.tab.close")

-- Panes.
rex.bind("ctrl+a>space>p>tab", "pane.focus_previous")
rex.bind("ctrl+a>space>p>h", "pane.focus.left")
rex.bind("ctrl+a>space>p>j", "pane.focus.down")
rex.bind("ctrl+a>space>p>k", "pane.focus.up")
rex.bind("ctrl+a>space>p>l", "pane.focus.right")
rex.bind("ctrl+a>space>p>z", "pane.zoom")
rex.bind("ctrl+a>space>p>r>h", "pane.resize", { direction = "left" })
rex.bind("ctrl+a>space>p>r>j", "pane.resize", { direction = "down" })
rex.bind("ctrl+a>space>p>r>k", "pane.resize", { direction = "up" })
rex.bind("ctrl+a>space>p>r>l", "pane.resize", { direction = "right" })
rex.bind("ctrl+a>space>p>r>shift+h", "pane.resize", { direction = "left", amount = 10 })
rex.bind("ctrl+a>space>p>r>shift+j", "pane.resize", { direction = "down", amount = 10 })
rex.bind("ctrl+a>space>p>r>shift+k", "pane.resize", { direction = "up", amount = 10 })
rex.bind("ctrl+a>space>p>r>shift+l", "pane.resize", { direction = "right", amount = 10 })
rex.bind("ctrl+a>space>p>shift+1", "pane.move_to_new_tab") -- ! (break pane)
rex.bind("ctrl+a>space>p>shift+x", "pane.close")

-- Sessions.
rex.bind("ctrl+a>space>s>s", "session.switch")
rex.bind("ctrl+a>space>s>shift+s", "session.switch")
rex.bind("ctrl+a>space>s>c", "session.new")
rex.bind("ctrl+a>space>s>r", "session.rename")
rex.bind("ctrl+a>space>s>shift+x", "session.close")

-- Client actions that have a Rex counterpart. Tmux's client picker,
-- detach/suspend, and TPM plugin controls do not.
rex.bind("ctrl+a>space>shift+c>shift+r", "session.refresh")
rex.bind("ctrl+a>space>shift+c>r", "client.config.reload")
rex.bind("ctrl+a>space>shift+c>,", "client.settings")

-- Tmux's unprefixed Alt+Arrow pane navigation.
rex.bind("alt+left", "pane.focus.left")
rex.bind("alt+right", "pane.focus.right")
rex.bind("alt+up", "pane.focus.up")
rex.bind("alt+down", "pane.focus.down")
