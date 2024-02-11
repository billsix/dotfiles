
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
(load-theme 'modus-vivendi t)
;; (load-theme 'modus-operandi t)
;; (load-theme 'material t)
;;(load-theme 'the-matrix t)
(global-auto-revert-mode)
(setq auto-reve9rt-avoid-polling t)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(ack ellama evil-escape theme-buffet ess dired-duplicates drepl devicetree-ts-mode dape yafolding which-key the-matrix-theme projectile org-modern material-theme markdown-preview-mode magit helm-xref helm-lsp fold-this flycheck elpy discover dap-mode blacken better-defaults)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
