;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Display customization
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; My prefered color theme
(package! monokai-pro-theme)

;; Better diff views in magit
(package! magit-delta)

;; Unpin some packages to get the latest goodies
(unpin! lsp-mode)
(unpin! web-mode)
