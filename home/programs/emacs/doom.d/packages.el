;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Terminal mode plugins
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Allow for changing the cursor shape when running in a terminal
(package! evil-terminal-cursor-changer)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Display customization
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Allow for mixing font pitch in the same major mode. This is how I can use
;; both monospace and proportional fonts in org and markdowm modes.
(package! mixed-pitch)

;; My prefered color theme
(package! monokai-pro-theme
  :recipe (:host github :repo "belak/emacs-monokai-pro-theme"))


;; Quickly jump to words with letter combinations
(package! evil-easymotion
  :recipe (:host github :repo "PythonNut/evil-easymotion"))

;; Allow the browser "Edit in Emacs plugins"
(package! edit-server)
