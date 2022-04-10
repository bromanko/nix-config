;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Display customization
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; My prefered color themes
(package! monokai-pro-theme)
(package! spacemacs-theme)

;; Better diff views in magit
(package! magit-delta)

;; Unpin some packages to get the latest goodies
(unpin! lsp-mode)
(unpin! web-mode)

;; monky for Mercurial repos
(package! monky)

;; Highlight by sentence
(package! hl-sentence)
