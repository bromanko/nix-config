;; -*- no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Display customization
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Better diff views in magit
(package! magit-delta)

;; Unpin some packages to get the latest goodies
(unpin! lsp-mode)
(unpin! web-mode)

;; monky for Mercurial repos
(package! monky)

;; zen mode packages
(package! hl-sentence)
(package! mixed-pitch)

;; Better org agenda
(package! org-super-agenda)

;; Just mode
(package! just-mode)
