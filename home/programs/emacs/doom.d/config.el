;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Brian Romanko"
      user-mail-address "hello@bromanko.com")

;; **************************************************
;; UI Settings
;; **************************************************
(setq doom-font (font-spec :family "FantasqueSansMono Nerd Font" :size 17)
      doom-variable-pitch-font (font-spec :family "Avenir Next" :size 17))

(setq-default line-spacing 0.15)

(load-theme 'monokai-pro t)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; Configure cursor for insert mode
(unless (display-graphic-p)
  (require 'evil-terminal-cursor-changer)
  (evil-terminal-cursor-changer-activate))
(setq evil-insert-state-cursor 'bar)



;; **************************************************
;; General
;; **************************************************

;; PATH configuration
(defun set-exec-path-from-shell-PATH ()
  "Set up Emacs' `exec-path' and PATH environment variable to match
that used by the user's shell.

This is particularly useful under Mac OS X and macOS, where GUI
apps are not started from a shell."
  (interactive)
  (let ((path-from-shell (replace-regexp-in-string
			  "[ \t\n]*$" "" (shell-command-to-string
					  "$SHELL --login -c 'echo $PATH'"
					  ))))
    (setenv "PATH" path-from-shell)
    (setq exec-path (split-string path-from-shell path-separator))))

(set-exec-path-from-shell-PATH)

;; evil-easymotion
(evilem-default-keybindings "SPC")

;; save on focus change
(add-hook 'focus-out-hook (lambda () (save-some-buffers t)))

;; Save by default
(setq auto-save-default t)

;; Configure the alarm bell to flash the mode-line
(setq visible-bell nil
      ring-bell-function 'flash-mode-line)
(defun flash-mode-line ()
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil #'invert-face 'mode-line))

;; Disable quit confirmation
(setq confirm-kill-emacs nil)

;; **************************************************
;; org mode
;; **************************************************

;; agenda
(setq org-agenda-files (list
                        "~/org/todo.org"
                        "~/org/facebook/todo.org"))

;; org-export settings
(after! org
  (setq org-directory "~/org/")
  ;; don't add section numbers to headings on export
  (setq org-export-with-section-numbers nil)
  ;; don't automatically use smart quotes
  (setq org-export-with-smart-quotes nil)
  ;; require brackets to use sub/superscripts so that a straight underline
  ;; or caret doesn't get interpreted as such
  (setq org-export-with-sub-superscripts '{})
  ;; don't automatically add TOC to exports
  (setq org-export-with-toc nil))

;; org-roam
(after! org-roam-
  (setq org-roam-directory org-directory)
  (map! :leader
        :prefix "n"
        :desc "org-roam" "l" #'org-roam
        :desc "org-roam-insert" "i" #'org-roam-insert
        :desc "org-roam-find-file" "f" #'org-roam-find-file
        :desc "org-roam-show-graph" "g" #'org-roam-show-graph
        :desc "org-roam-capture" "c" #'org-roam-capture))

;; deft notes
(setq
 deft-directory org-directory
 deft-extensions '("org", "md")
 deft-recursive t)

;; org-reveal
(setq org-reveal-root "https://cdn.jsdelivr.net/npm/reveal.js")

;; **************************************************
;; markdown
;; **************************************************
(setq markdown-header-scaling t)
(setq markdown-marginalize-headers t)
(setq markdown-indent-on-enter "indent-and-new-item")

;; Set a variable-pitch font for default face in markdown
(add-hook 'markdown-mode-hook
          (lambda () (display-fill-column-indicator-mode 0)))
(add-hook 'markdown-mode-hook #'mixed-pitch-mode)

;; **************************************************
;; treemacs
;; **************************************************

;; sync tree with open file
(setq treemacs-follow-mode t)

;; **************************************************
;; server
;; **************************************************
(if (and (fboundp 'server-running-p)
         (not (server-running-p)))
    (server-start))

;; **************************************************
;; projectile
;; **************************************************
(setq projectile-globally-ignored-files '("flake.lock")
      projectile-project-search-path '("~/Code"))

;; **************************************************
;; company
;; **************************************************
(after! company
  (setq company-minimum-prefix-length 1)
  ;; show completion results asap
  (setq company-idle-delay 0.0))


;; **************************************************
;; lsp
;; **************************************************
(after! lsp-mode
  (setq lsp-ui-doc-include-signature t)
  (setq lsp-ui-doc-delay 0.75)
  (setq lsp-ui-sideline-delay 0.75)
  (setq lsp-headerline-breadcrumb-enable t)
)


;; **************************************************
;; magit
;; **************************************************
(add-hook 'magit-mode-hook (lambda () (magit-delta-mode +1)))
