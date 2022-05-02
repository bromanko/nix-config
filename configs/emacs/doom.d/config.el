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

(defvar br-default-theme 'doom-monokai-pro)
(setq doom-theme br-default-theme)
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


(setq org-directory "~/org/")

(load-library "find-lisp")
(setq org-agenda-files
      (find-lisp-find-files org-directory "\.org$"))

;; agenda
(defun bromanko/org-agenda-process-inbox-item ()
  "Process a single item in the org-agenda."
  (interactive)
  (org-with-wide-buffer
   (org-agenda-set-tags)
   (org-agenda-priority)
   (org-agenda-refile nil nil t)))

(defun bromanko/bulk-process-entries ()
  (if (not (null org-agenda-bulk-marked-entries))
      (let ((entries (reverse org-agenda-bulk-marked-entries))
            (processed 0)
            (skipped 0))
        (dolist (e entries)
          (let ((pos (text-property-any (point-min) (point-max) 'org-hd-marker e)))
            (if (not pos)
                (progn (message "Skipping removed entry at %s" e)
                       (cl-incf skipped))
              (goto-char pos)
              (let (org-loop-over-headlines-in-active-region) (funcall 'bromanko/org-agenda-process-inbox-item))
              ;; `post-command-hook' is not run yet.  We make sure any
              ;; pending log note is processed.
              (when (or (memq 'org-add-log-note (default-value 'post-command-hook))
                        (memq 'org-add-log-note post-command-hook))
                (org-add-log-note))
              (cl-incf processed))))
        (org-agenda-redo)
        (unless org-agenda-persistent-marks (org-agenda-bulk-unmark-all))
        (message "Acted on %d entries%s%s"
                 processed
                 (if (= skipped 0)
                     ""
                   (format ", skipped %d (disappeared before their turn)"
                           skipped))
                 (if (not org-agenda-persistent-marks) "" " (kept marked)")))))

(defun bromanko/org-agenda-bulk-mark-regexp-category (regexp)
  "Mark entries whose category matches REGEXP for future agenda bulk action."
  (interactive "sMark entries with category matching regexp: ")
  (let ((entries-marked 0) txt-at-point)
    (save-excursion
      (goto-char (point-min))
      (goto-char (next-single-property-change (point) 'org-hd-marker))
      (while (and (re-search-forward regexp nil t)
                  (setq category-at-point
                        (get-text-property (match-beginning 0) 'org-category)))
        (if (get-char-property (point) 'invisible)
            (beginning-of-line 2)
          (when (string-match-p regexp category-at-point)
            (setq entries-marked (1+ entries-marked))
            (call-interactively 'org-agenda-bulk-mark)))))
    (unless entries-marked
      (message "No entry matching this regexp."))))

(defun bromanko/org-process-inbox ()
  "Called in org-agenda-mode, processes all inbox items."
  (interactive)
  (org-agenda-bulk-unmark-all)
  (bromanko/org-agenda-bulk-mark-regexp-category "inbox")
  (bromanko/bulk-process-entries))


(defun bromanko/org-archive-done-tasks ()
  "Archive all done tasks."
  (interactive)
  (org-map-entries 'org-archive-subtree "/DONE" 'file))


(map! :map org-mode-map "SPC m s z" #'bromanko/org-archive-done-tasks)

(after! org
  ;;
  ;; agenda
  ;;
  (setq org-agenda-block-separator nil
        org-agenda-compact-blocks t)

  (org-super-agenda-mode)

  (define-key org-agenda-mode-map "r" 'bromanko/org-process-inbox)

  (add-to-list 'org-capture-templates
               `("i" "inbox" entry (file ,(concat org-directory "inbox.org"))
                 "* TODO %?" :prepend t))
  ;; ("n" "note" entry (file ,(concat bromanko/org-agenda-directory "notes.org"))
  ;;  "* %u %?\n%i\n%a" :prepend t)
  ;; ("l" "link" entry (file ,(concat bromanko/org-agenda-directory "inbox.org"))
  ;;  "* TODO %(org-cliplink-capture)" :immediate-finish t)
  ;; ("c" "org-protocol-capture" entry (file ,(concat bromanko/org-agenda-directory "inbox.org"))
  ;;  "* TODO [[%:link][%:description]]\n\n %i" :immediate-finish t)))

  (setq org-refile-allow-creating-parent-nodes 'confirm)

  (setq org-agenda-custom-commands
        '(("a" "Agenda for current day"
           ((agenda "" (
                        (org-agenda-span 'day)
                        (org-agenda-format-date "%A, %-e %B %Y")
                        (org-agenda-show-log t)
                        (org-super-agenda-groups '(
                                                   (:name "📅 Today"
                                                    :time-grid t
                                                    :todo "TODAY"
                                                    :scheduled today
                                                    :order 0)
                                                   (:name "⏰ Due Today"
                                                    :deadline today
                                                    :order 2)
                                                   (:name "🗓 Due Soon"
                                                    :deadline future
                                                    :order 3)
                                                   (:name "Overdue"
                                                    :deadline past
                                                    :order 1)
                                                   ))))
            (todo "" (
                      (org-agenda-overriding-header "")
                      (org-super-agenda-groups '(
                                                 (:name "📂 To Refile"
                                                  :file-path "inbox\\.org"
                                                  :order 1)
                                                 (:auto-category t
                                                  :order 9)
                                                 ))
                      ))))
          ("t" "Todo"
           ((todo "" (
                      (org-agenda-overriding-header "")
                      (org-super-agenda-groups '(
                                                 (:name "📂 To Refile"
                                                  :file-path "inbox\\.org"
                                                  :order 1)
                                                 (:auto-category t
                                                  :order 9)
                                                 ))
                      )))))
        )


  ;;
  ;; org-export settings
  ;;
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
(setq org-roam-directory (file-truename (concat org-directory "roam")))

;; Speed up saving of large files in org-roam by batching operations into a
;; single sqlite txn. From org-roam#1752 on GH.
(advice-add 'org-roam-db-update-file :around
            (defun +org-roam-db-update-file (fn &rest args)
              (emacsql-with-transaction (org-roam-db)
                (apply fn args))))

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
  (add-to-list 'company-global-modes 'org-mode t)
  (add-to-list 'company-global-modes 'git-commit-mode t)
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
