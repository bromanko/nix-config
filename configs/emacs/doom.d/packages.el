;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Display customization
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Allow for mixing font pitch in the same major mode. This is how I can use
;; both monospace and proportional fonts in org and markdowm modes.
(package! mixed-pitch)

;; My prefered color theme
(package! monokai-pro-theme)

;; Better diff views in magit
(package! magit-delta)
