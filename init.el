;; This emacs configuration supports loading from an arbitrary
;; directory via emacs -q --load "/path/to/this/init.el"
;; see https://emacs.stackexchange.com/a/4258/22184

;; basic emacs settings:
(setq inhibit-startup-screen t)
(setq-default indent-tabs-mode nil)
(setq column-number-mode t)
(global-display-line-numbers-mode)
(global-auto-revert-mode 1) ;; auto-refresh files that change
(setq visible-bell t)

;; disable secondary selections (annoying)
(global-unset-key [M-mouse-1])
(global-unset-key [M-drag-mouse-1])
(global-unset-key [M-down-mouse-1])
(global-unset-key [M-mouse-3])
(global-unset-key [M-mouse-2])

;; other aesthetic settings:
(scroll-bar-mode -1) ;; disable mode
(tool-bar-mode -1) ;; disable mode
(menu-bar-mode -1) ;; disable the mode

;; Set `user-emacs-directory` to directory where this file is.
(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))

;; Emacs can write customizations to this file, ignored by git
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

;; Configure backups.  Everything goes under ".cache/" in same
;; directory as this file.
;; See https://www.emacswiki.org/emacs/BackupDirectory
(setq user-cache-directory (expand-file-name ".cache" user-emacs-directory))
(setq
   backup-by-copying t ;; don't clobber symlinks
   backup-directory-alist `(("." . ,(expand-file-name "backups" user-cache-directory)))
   auto-save-list-file-prefix (expand-file-name "auto-save-list/.saves-" user-cache-directory)
   url-history-file (expand-file-name "url/history" user-cache-directory)
   delete-old-versions t ;; delete excess backup versions silently
   kept-new-versions 6 ;; number of newest versions to keep when making new numbered backup
   kept-old-versions 2 ;; number of oldest versions to keep when making new numbered backup
   version-control t   ;; use versioned backups
   auto-save-file-name-transforms `((".*" ,(expand-file-name "autosave" user-cache-directory) t)))

;; packages:

(require 'package)

;; Add some package repositories:
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("tromey" . "http://tromey.com/elpa/"))
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)

;; Load Emacs Lisp packages and activate them.
(package-initialize)

;; unless the package named "use-package" is installed
(unless (package-installed-p 'use-package)
  ;; unless cached, download all descriptions of all configured ELPA packages
  (unless package-archive-contents (package-refresh-contents))
  ;; and install the package "use-package"
  (package-install 'use-package))
;; If use-package is not already loaded then load from the file `use-package.el`
(require 'use-package)

;; Enable defer and :ensure by default for use-package
(setq use-package-always-defer t
      use-package-always-ensure t)

;; Initialize environment from the user’s shell, rather than by
;;   (setenv "JAVA_HOME" javadir)
(use-package exec-path-from-shell)
(exec-path-from-shell-initialize)

;; Enable scala-mode for highlighting, indentation and motion commands
(use-package scala-mode
  :interpreter ("scala" . scala-mode)
  :hook (scala-mode . (lambda ()
                       (add-hook 'before-save-hook 'lsp-format-buffer nil 'local))))

;; Enable sbt mode for executing sbt commands
(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition 'minibuffer-complete-word 'self-insert-command minibuffer-local-completion-map)
   ;; sbt-supershell kills sbt-mode:  https://github.com/hvesalai/emacs-sbt-mode/issues/152
   (setq sbt:program-options '("-Dsbt.supershell=false")))

;; Enable nice rendering of diagnostics like compile errors.
(use-package flycheck
  :init (global-flycheck-mode))

(use-package lsp-mode
  ;; Enable lsp-mode automatically in scala files
  :hook  (scala-mode . lsp-deferred)
         (lsp-mode   . lsp-lens-mode)
         (lsp-mode   . lsp-enable-which-key-integration)
         (java-mode  . lsp-deferred)
  :init
  (setq 
    ;; this is for which-key integration documentation, need to use lsp-mode-map
    lsp-keymap-prefix "C-c l"
    lsp-enable-file-watchers nil
    read-process-output-max (* 1024 1024)  ; 1 mb
    lsp-idle-delay 0.500
    lsp-enable-on-type-formatting t
    lsp-format-on-save t
  )
  :config
  (define-key lsp-mode-map (kbd "C-c l") lsp-command-map)
  (define-key lsp-mode-map [C-down-mouse-1] 'lsp-find-definition)
  ;; Uncomment following section if you would like to tune lsp-mode performance according to
  ;; https://emacs-lsp.github.io/lsp-mode/page/performance/
  ;; (setq gc-cons-threshold 100000000) ;; 100mb
  ;; (setq read-process-output-max (* 1024 1024)) ;; 1mb
  ;; (setq lsp-idle-delay 0.500)
  ;; (setq lsp-log-io nil)

  ;; can I delete the next line?
  ;; (setq lsp-prefer-flymake nil)

  ;; Makes LSP shutdown the metals server when all buffers in the project are closed.
  ;; https://emacs-lsp.github.io/lsp-mode/page/settings/mode/#lsp-keep-workspace-alive
  (setq lsp-keep-workspace-alive nil)
  (setq lsp-semantic-tokens-enable t)
  (setq lsp-semantic-tokens-apply-modifiers nil))

;; Add metals backend for lsp-mode
(use-package lsp-metals
  :custom
  (lsp-metals-server-args '(;; Allow emacs to use indentation provided by scala-mode.
                            "-J-Dmetals.allow-multiline-string-formatting=off"
                            ;; Enable unicode icons.
                            "-J-Dmetals.icons=unicode"))
  (lsp-metals-enable-semantic-highlighting t)
  :hook (scala-mode . lsp-deferred))

;; Enable nice rendering of documentation on hover
;;   Warning: on some systems this package can reduce your emacs responsiveness significally.
;;   (See: https://emacs-lsp.github.io/lsp-mode/page/performance/)
;;   In that case you have to not only disable this but also remove from the packages since
;;   lsp-mode can activate it automatically.
(use-package lsp-ui
  :after (lsp-mode)
  :bind (:map lsp-ui-mode-map
              ([remap xref-find-definitions] . lsp-ui-peek-find-definitions)
              ([remap xref-find-references] . lsp-ui-peek-find-references))
  :init (setq lsp-ui-doc-delay 1.5
              lsp-ui-doc-position 'bottom
	      lsp-ui-doc-max-width 100
              )
  :commands lsp-ui-mode
  :custom
  (lsp-ui-peek-always-show t)
  (lsp-ui-sideline-show-hover t)
  (lsp-ui-doc-enable t))

;; lsp-mode supports snippets, but in order for them to work you need to use yasnippet
;; If you don't want to use snippets set lsp-enable-snippet to nil in your lsp-mode settings
;; to avoid odd behavior with snippets and indentation
(use-package yasnippet :config (yas-global-mode))
(use-package yasnippet-snippets :ensure t)

;; Use company-capf as a completion provider.
(use-package company
  :hook (scala-mode . company-mode)
  :config
  (setq lsp-completion-provider :capf))

;; Posframe is a pop-up tool that must be manually installed for dap-mode
(use-package posframe)

;; Use the Debug Adapter Protocol for running tests and debugging
(use-package dap-mode
  :after (lsp-mode)
  :functions dap-hydra/nil
  :bind (:map lsp-mode-map
              ("<f5>" . dap-debug)
              ("M-<f5>" . dap-hydra))
  :hook
  (lsp-mode . dap-mode)
  (dap-mode . dap-ui-mode)
  (dap-session-created . (lambda (&_rest) (dap-hydra)))
  (dap-terminated . (lambda (&_rest) (dap-hydra/nil)))
)

(use-package projectile
  :init
  (setq projectile-known-projects-file (expand-file-name "projectile-bookmarks.eld" user-cache-directory))
  (projectile-mode +1)
  :config
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
)

(use-package flycheck-projectile
  :bind (("M-9" . flycheck-projectile-list-errors))
  )

(use-package use-package-chords
  :config (key-chord-mode 1)
  (setq key-chord-two-keys-delay 0.4)
  (setq key-chord-one-key-delay 0.5) ; default 0.2
  )

(use-package helm
  :init 
  (helm-mode 1)
  (progn (setq helm-buffers-fuzzy-matching t))
  :bind
  (("C-c h" . helm-command-prefix))
  (("M-x" . helm-M-x))
  (("C-x C-f" . helm-find-files))
  (("C-x b" . helm-buffers-list))
  (("C-c b" . helm-bookmarks))
  (("C-c f" . helm-recentf))   ;; Add new key to recentf
  (("C-c g" . helm-grep-do-git-grep)))  ;; Search using grep in a git project

(use-package helm-descbinds
  :ensure t
  :bind ("C-h b" . helm-descbinds))

(use-package helm-swoop
  :ensure t
  ;; :chords
  ;; ("js" . helm-swoop)
  ;; ("jp" . helm-swoop-back-to-last-point)
  :init
  (bind-key "M-m" 'helm-swoop-from-isearch isearch-mode-map)
  ;; If you prefer fuzzy matching
  (setq helm-swoop-use-fuzzy-match t)
  ;; Save buffer when helm-multi-swoop-edit complete
  (setq helm-multi-swoop-edit-save t)
  ;; If this value is t, split window inside the current window
  (setq helm-swoop-split-with-multiple-windows nil)
  ;; Split direction. 'split-window-vertically or 'split-window-horizontally
  (setq helm-swoop-split-direction 'split-window-vertically)
  ;; If nil, you can slightly boost invoke speed in exchange for text color
  (setq helm-swoop-speed-or-color nil)
  ;; Go to the opposite side of line from the end or beginning of line
  (setq helm-swoop-move-to-line-cycle t)
)

(use-package helm-lsp
  :after (lsp-mode)
  :commands (helm-lsp-workspace-symbol)
  :init (define-key lsp-mode-map [remap xref-find-apropos] #'helm-lsp-workspace-symbol)
)

(use-package avy 
  ;; :chords
  ;; ("jc" . avy-goto-char)
  ;; ("jw" . avy-goto-word-1)
  ;; ("jl" . avy-goto-line)
)

(use-package which-key 
  :init
  (which-key-mode)
  )

(use-package quickrun 
  :ensure t
  :bind ("C-c r" . quickrun))

(use-package treemacs
  :commands (treemacs)
  :after (lsp-mode)
  :config (setq treemacs-expand-after-init t)
)

(use-package lsp-treemacs
  :after (lsp-mode treemacs)
  :commands lsp-treemacs-errors-list
  :config (add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1)))
  ;; :bind (:map lsp-mode-map
  ;;             ("M-9" . lsp-treemacs-errors-list))
)


;; partial (hopefully temporary) fix for scala-3 braceless indentation
(load-file (expand-file-name "indentation-hack.el" user-emacs-directory))
