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




;;; because I can't remember to use camelcase in python
(defun toggle-camelcase-underscores ()
  "Toggle between camelcase and underscore notation for the symbol at point."
  (interactive)
  (save-excursion
    (let* ((bounds (bounds-of-thing-at-point 'symbol))
           (start (car bounds))
           (end (cdr bounds))
           (currently-using-underscores-p (progn (goto-char start)
                                                 (re-search-forward "_" end t))))
      (if currently-using-underscores-p
          (progn
            (upcase-initials-region start end)
            (replace-string "_" "" nil start end)
            (downcase-region start (1+ start)))
        (replace-regexp "\\([A-Z]\\)" "_\\1" nil (1+ start) end)
        (downcase-region start (cdr (bounds-of-thing-at-point 'symbol)))))))

;;; (set-face-attribute 'default nil :height 180)