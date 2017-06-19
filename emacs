(set-background-color "black")
(set-foreground-color "white")
(show-paren-mode)
(tool-bar-mode -1)
(menu-bar-mode -1)
(setq inhibit-startup-message t)        ; Disable startup message
(setq-default indent-tabs-mode nil)

(defun set-window-undedicated-p (window flag)
 "Never set window dedicated."
 flag)

(advice-add 'set-window-dedicated-p :override #'set-window-undedicated-p)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
