;; These are hacks until scala-mode support Scala-3 braceless syntax
;; https://sideshowcoder.com/2021/12/30/new-scala-3-syntax-in-emacs/

(defun is-scala3-project ()
  "Return true (usually) if the current project is using scala3.

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
