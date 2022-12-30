
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
(package-initialize)

(load-file "~/.emacs.d/bills-preferences.el")
(load-file "~/.emacs.d/helm.el")
;; type C-x-e after the sexepression to execute
;; (load-file "~/.emacs.d/install-melpa-packages.el")
;; (load-file "~/.emacs.d/c++-mode.el")
;; (load-file "~/.emacs.d/python-mode.el")

;; theme
(load-theme 'material t)
;;(load-theme 'the-matrix t)
(global-auto-revert-mode)
(setq auto-reve9rt-avoid-polling t)
