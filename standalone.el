(setq column-number-mode t)
(global-display-line-numbers-mode)
(setq inhibit-startup-screen t)
(setq-default indent-tabs-mode nil)
(global-auto-revert-mode 1)

;; This is to support loading from a non-standard .emacs.d
;; via emacs -q --load "/path/to/standalone.el"
;; see https://emacs.stackexchange.com/a/4258/22184

(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(require 'package)
(add-to-list 'package-archives '("tromey" . "http://tromey.com/elpa/"))
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/") t)
(setq package-user-dir (expand-file-name "elpa/" user-emacs-directory))
(package-initialize)

;; Work around an Emacs v26 bug.
;; https://www.reddit.com/r/emacs/comments/cdei4p/failed_to_download_gnu_archive_bad_request/
(when (version< emacs-version "27")
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

;; Install use-package that we require for managing all other dependencies
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

;; I find these light-weight and helpful

(use-package which-key
  :ensure
  :init
  (which-key-mode))

(use-package selectrum
  :ensure
  :init
  (selectrum-mode)
  :custom
  (completion-styles '(flex substring partial-completion)))

;; Some common sense settings

(load-theme 'leuven t)
(fset 'yes-or-no-p 'y-or-n-p)
(recentf-mode 1)
(setq recentf-max-saved-items 100
      inhibit-startup-message t
      ring-bell-function 'ignore)

(tool-bar-mode 0)
(menu-bar-mode 0)
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode 0))

(cond
 ((member "Monaco" (font-family-list))
  (set-face-attribute 'default nil :font "Monaco-12"))
 ((member "Inconsolata" (font-family-list))
  (set-face-attribute 'default nil :font "Inconsolata-12"))
 ((member "Consolas" (font-family-list))
  (set-face-attribute 'default nil :font "Consolas-11"))
 ((member "DejaVu Sans Mono" (font-family-list))
  (set-face-attribute 'default nil :font "DejaVu Sans Mono-10")))

(load-file (expand-file-name "init.el" user-emacs-directory))

;; These are hacks until scala-mode support Scala-3 braceless syntax
;; https://sideshowcoder.com/2021/12/30/new-scala-3-syntax-in-emacs/

(use-package projectile
  :ensure t
  :init
  (projectile-mode +1)
  :bind (:map projectile-mode-map
              ("s-p" . projectile-command-map)
              ("C-c p" . projectile-command-map)))

(defun is-scala3-project ()
  "Check if the current project is using scala3.

Loads the build.sbt file for the project and search for the scalaVersion."
  (projectile-with-default-dir (projectile-project-root)
    (when (file-exists-p "build.sbt")
      (with-temp-buffer
        (insert-file-contents "build.sbt")
        (search-forward "scalaVersion := \"3" nil t)))))

(defun with-disable-for-scala3 (orig-scala-mode-map:add-self-insert-hooks &rest arguments)
    "When using scala3 skip adding indention hooks."
    (unless (is-scala3-project)
      (apply orig-scala-mode-map:add-self-insert-hooks arguments)))

(advice-add #'scala-mode-map:add-self-insert-hooks :around #'with-disable-for-scala3)

(defun disable-scala-indent ()
  "In scala 3 indent line does not work as expected due to whitespace grammar."
  (when (is-scala3-project)
    (setq indent-line-function 'indent-relative-maybe)))

(add-hook 'scala-mode-hook #'disable-scala-indent)

;; end of scala-3 indentation hacks

