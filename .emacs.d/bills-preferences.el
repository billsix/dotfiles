(set-background-color "black")
(set-foreground-color "white")
(show-paren-mode)
(tool-bar-mode -1)
(menu-bar-mode -1)
(setq inhibit-startup-message t)        ; Disable startup message
(setq-default indent-tabs-mode nil)

(add-hook 'before-save-hook 'delete-trailing-whitespace)


(visual-line-mode t)
(global-visual-line-mode t)
(global-linum-mode t)
(set-buffer-file-coding-system 'unix)

(setq make-backup-files nil)
