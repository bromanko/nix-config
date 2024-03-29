(require-macros :lib.macros)
(require-macros :lib.advice.macros)
(local windows (require :windows))
(local emacs (require :emacs))
(local vim (require :vim))

(local {: concat
        : logf} (require :lib.functional))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(set hs.window.animationDuration 0.0)
(tset hs.alert.defaultStyle :fadeInDuration 0.0)
(tset hs.alert.defaultStyle :fadeOutDuration 0.0)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Actions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn activator
  [app-name]
  "
  A higher order function to activate a target app. It's useful for quickly
  binding a modal menu action or hotkey action to launch or focus on an app.
  Takes a string application name
  Returns a function to activate that app.

  Example:
  (local launch-emacs (activator \"Emacs\"))
  (launch-emacs)
  "
  (fn activate []
    (windows.activate-app app-name)))

(fn m-key [key]
  "
  Simulates pressing a multimedia key on a keyboard
  Takes the key string and simulates pressing it for 5 ms then relesing it.
  Side effectful.
  Returns nil
  "
  (: (hs.eventtap.event.newSystemKeyEvent (string.upper key) true) :post)
  (hs.timer.usleep 5)
  (: (hs.eventtap.event.newSystemKeyEvent (string.upper key) false) :post))

(fn mute
  []
  "
  Simulates pressing the mute keyboard key
  "
  (fn mute []
    (m-key :mute)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; General
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local music-app "Spotify")

(local return
       {:key :space
        :title "Back"
        :action :previous})

(fn is-clamshell
  []
  "
  Returns a value indicating whether the computer is currently in clamshell
  mode (lid is closed).
  "
  (=
    (hs.execute "ioreg -r -k AppleClamshellState -d 4 | grep AppleClamshellState | head -1 | grep No")
    ""))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(fn close-active-window
  []
  "
  Closes the active window
  "
  (fn close []
    (: (hs.window.focusedWindow) :close)))

(local window-jumps
       [{:mods [:cmd]
         :key "⏴⏷⏶⏵"
         :title "Jump"}
        {:mods [:cmd]
         :key :left
         :action "windows:jump-window-left"
         :repeatable true}
        {:mods [:cmd]
         :key :up
         :action "windows:jump-window-above"
         :repeatable true}
        {:mods [:cmd]
         :key :down
         :action "windows:jump-window-below"
         :repeatable true}
        {:mods [:cmd]
         :key :right
         :action "windows:jump-window-right"
         :repeatable true}])

(local window-halves
       [{:key "⏴⏷⏶⏵"
         :title "Halves"}
        {:key :left
         :action "windows:resize-half-left"
         :repeatable true}
        {:key :down
         :action "windows:resize-half-bottom"
         :repeatable true}
        {:key :up
         :action "windows:resize-half-top"
         :repeatable true}
        {:key :right
         :action "windows:resize-half-right"
         :repeatable true}])

(local window-increments
       [{:mods [:alt]
         :key "⏴⏷⏶⏵"
         :title "Increments"}
        {:mods [:alt]
         :key :left
         :action "windows:resize-inc-left"
         :repeatable true}
        {:mods [:alt]
         :key :down
         :action "windows:resize-inc-bottom"
         :repeatable true}
        {:mods [:alt]
         :key :up
         :action "windows:resize-inc-top"
         :repeatable true}
        {:mods [:alt]
         :key :right
         :action "windows:resize-inc-right"
         :repeatable true}])

(local window-resize
       [{:mods [:shift]
         :key "⏴⏷⏶⏵"
         :title "Resize"}
        {:mods [:shift]
         :key :left
         :action "windows:resize-left"
         :repeatable true}
        {:mods [:shift]
         :key :down
         :action "windows:resize-down"
         :repeatable true}
        {:mods [:shift]
         :key :up
         :action "windows:resize-up"
         :repeatable true}
        {:mods [:shift]
         :key :right
         :action "windows:resize-right"
         :repeatable true}])

(local window-bindings
       (concat
        [return
         {:key :w
          :title "Last Window"
          :action "windows:jump-to-last-window"}]
        window-jumps
        window-halves
        window-increments
        window-resize
        [{:key :m
          :title "Maximize"
          :action "windows:maximize-window-frame"}
         {:key :c
          :title "Center"
          :action "windows:center-window-frame"}
         {:key :d
          :title "Close"
          :action (close-active-window)}
         {:key :g
          :title "Grid"
          :action "windows:show-grid"}
         {:key :u
          :title "Undo"
          :action "windows:undo"}]))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Apps Menu
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local app-bindings
       [return
        {:key :c
         :title "Chrome"
         :action (activator "Google Chrome")}
        {:key :e
         :title "Emacs"
         :action (activator "Emacs")}
        {:key :h
         :title "Hammerspoon"
         :action (activator "Hammerspoon")}
        {:key :f
         :title "Workplace Chat"
         :action (activator "Workplace Chat")}
        {:key :l
         :title "Calendar"
         :action (activator "Calendar")}
        {:key :m
         :title "Messages"
         :action (activator "Messages")}
        {:key :m
         :title "Mail"
         :action (activator "Mail")}
        {:key :o
         :title "Obsidian"
         :action (activator "Obsidian")}
        {:key :p
         :title "1Password"
         :action (activator "1Password")}
        {:key :s
         :title "Safari"
         :action (activator "Safari")}
        {:key :w
         :title "Workplace"
         :action (activator "Workplace")}
        {:key :z
         :title music-app
         :action (activator music-app)}])

;; Make this match the Miryoku mappings
(local media-bindings
       [return
        {:key :s
         :title "Play or Pause"
         :action "multimedia:play-or-pause"}
        {:key :h
         :title "Prev Track"
         :action "multimedia:prev-track"}
        {:key :l
         :title "Next Track"
         :action "multimedia:next-track"}
        {:key :j
         :title "Volume Down"
         :action "multimedia:volume-down"
         :repeatable true}
        {:key :k
         :title "Volume Up"
         :action "multimedia:volume-up"
         :repeatable true}
        {:key :m
         :title "Toggle Mute"
         :action (mute)}
        {:key :a
         :title (.. "Launch " music-app)
         :action (activator music-app)}])

(fn screen-capture
  [style]
  "
  Issues a screen capture command
  "
  (fn c []
    (local task (hs.task.new "/usr/sbin/screencapture" nil ["-i" (.. "-J" style) "-c"]))
    (task:start)))

(local capture-bindings
       [return
        {:key :s
        :title "Selection"
        :action (screen-capture "selection")}
        {:key :w
        :title "Window"
        :action (screen-capture "window")}])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main Menu & Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local menu-items
       [{:key    :space
         :title  "Raycast"
         :action (activator "Raycast")}
        {:key   :w
         :title "Window"
         :enter "windows:enter-window-menu"
         :exit "windows:exit-window-menu"
         :items window-bindings}
        {:key   :a
         :title "Apps"
         :items app-bindings}
        {:key    :j
         :title  "Jump"
         :action "windows:jump"}
        {:key   :m
         :title "Media"
         :items media-bindings}
        {:key   :x
         :title "Capture Screen"
         :items capture-bindings}])

(local common-keys
       [{:mods [:cmd]
         :key :space
         :action "lib.modal:activate-modal"}
        {:mods [:cmd :ctrl]
         :key "`"
         :action hs.toggleConsole}])

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; App Specific Config
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(local browser-keys
       [{:mods [:cmd :shift]
         :key :l
         :action "chrome:open-location"}
        {:mods [:alt]
         :key :k
         :action "chrome:next-tab"
         :repeat true}
        {:mods [:alt]
         :key :j
         :action "chrome:prev-tab"
         :repeat true}])

(local browser-items
       (concat
        menu-items
        [{:key "'"
          :title "Edit with Emacs"
          :action "emacs:edit-with-emacs"}]))

(local chrome-config
       {:key "Google Chrome"
        :keys browser-keys
        :items browser-items})

(local hammerspoon-config
       {:key "Hammerspoon"
        :items (concat
                menu-items
                [{:key :r
                  :title "Reload Config"
                  :action hs.reload}
                 {:key :c
                  :title "Clear Console"
                  :action hs.console.clearConsole}])
        :keys []})

(local apps
       [chrome-config
        hammerspoon-config])

(local config
       {:title "Main Menu"
        :items menu-items
        :keys  common-keys
        :enter (fn [] (windows.hide-display-numbers))
        :exit  (fn [] (windows.hide-display-numbers))
        :apps  apps
        :hyper {:key :F18}
        :grid {:size "3x1" :margins [10 10]}
        :modules {:windows {:center-ratio "80:50" }}})


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Exports
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

config
