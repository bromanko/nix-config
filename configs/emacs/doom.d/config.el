;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Brian Romanko"
      user-mail-address "hello@bromanko.com")

;; **************************************************
;; UI Settings
;; **************************************************
(setq doom-font (font-spec :family "FantasqueSansMono Nerd Font" :weight 'medium)
      doom-variable-pitch-font (font-spec :family "Avenir Next" :weight 'medium))

;; Increase the font-size relative to what Emacs defaults
;; I prefer this to hard-coding the font size because it works better across
;; macOS and Linux with HiDPI
(if (display-graphic-p)
    (add-hook 'emacs-startup-hook
              (lambda () (doom/increase-font-size 1))))

(setq-default line-spacing 0.15)

(defvar br-default-theme 'monokai-pro)
(load-theme br-default-theme t)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type 'relative)

;; Configure cursor for insert mode in the terminal
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
;; Performance
;; **************************************************

;; 15 is the original setting, but it seems like it's down to 0.5 via doom or
;; something, so try setting it back up to avoid GC pauses
(setq gcmh-idle-delay 10)

(setq gc-cons-threshold 100000000)
(setq read-process-output-max (* 1024 1024)) ;; 1 mb


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

(add-hook 'markdown-mode-hook
          (lambda ()
            (display-fill-column-indicator-mode 0)))


;; **************************************************
;; company
;; **************************************************

;; disable company for certain modes
(after! company
  ;; ensure the first element is `not' so that the list is negated
  (unless (eq (car company-global-modes) 'not)
    ;; remove existing not, just in case
    (setq company-global-modes (remove 'not company-global-modes))
    ;; set the first element to not
    (setcar company-global-modes 'not))
  ;; add modes in which to disable company-mode to the list, passing `t' for the
  ;; APPEND argument, which will ensure they are added to the end of the list
  ;; to not interfere with negation
  (add-to-list 'company-global-modes 'markdown-mode t)
  (add-to-list 'company-global-modes 'gfm-mode t))

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
;; lsp
;; **************************************************
(after! lsp-mode
  (setq lsp-ui-doc-include-signature t)
  (setq lsp-ui-peek-always-show t)
  (setq lsp-ui-doc-delay 0.75)
  (setq lsp-ui-sideline-delay 0.75)

                                        ; configure web-mode languages
  (add-to-list 'lsp-language-id-configuration
               '(".*\\.[lh]eex$" . "html")))


;; **************************************************
;; magit
;; **************************************************
(add-hook 'magit-mode-hook (lambda () (magit-delta-mode +1)))

;; **************************************************
;; web mode
;; **************************************************
(add-hook 'web-mode-hook
          (lambda () (setq web-mode-markup-indent-offset 2)))

;; **************************************************
;; zen writing mode
;; **************************************************

(defvar br-zen-theme 'doom-zen-writer)

(defun br-zen ()
  "Enable zen mode."
  (interactive)
  (setq doom-theme br-zen-theme)
  (load-theme doom-theme t)
  (display-line-numbers-mode -1)
  (hl-sentence-mode +1))

(defun br-unzen ()
  "Disable zen mode."
  (interactive)
  (hl-sentence-mode -1)
  (display-line-numbers-mode +1)
  (setq doom-theme br-default-theme)
  (load-theme doom-theme t))

(defun br-toggle-zen ()
  "Toggle zen mode."
  (interactive)
  (if (eql doom-theme br-default-theme) (br-zen) (br-unzen)))

(add-hook 'writeroom-mode-enable-hook #'br-zen)
(add-hook 'writeroom-mode-disable-hook #'br-unzen)

(setq +zen-text-scale 0)

;; **************************************************
;; monky
;; **************************************************
(setq monky-process-type 'cmdserver)
