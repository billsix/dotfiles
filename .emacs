(set-background-color "black")
(set-foreground-color "white")
(show-paren-mode)
(tool-bar-mode -1)
(menu-bar-mode -1)
(setq inhibit-startup-message t)        ; Disable startup message
(setq-default indent-tabs-mode nil)

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

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)


;; https://emacs-lsp.github.io/lsp-mode/tutorials/CPP-guide/

(setq package-selected-packages
      '(lsp-mode
        yasnippet
        lsp-treemacs
        helm-lsp
        projectile
        hydra
        flycheck
        company
        avy
        which-key
        helm-xref
        dap-mode
        blacken

        elpy

        material-theme
        the-matrix-theme

        fold-this
        yafolding

        org-modern

        discover
        yafolding
        fold-this
        better-defaults
        magit
        markdown-mode
        markdown-preview-mode
        ))

(defun install-or-upgrade-my-packages ()
  (when (cl-find-if-not #'package-installed-p package-selected-packages)
    (package-refresh-contents)
    (mapc #'package-install package-selected-packages)))

;; to run the function, C-x C-e with cursor after this commented-out function
;; (install-or-upgrade-my-packages)

;; sample `helm' configuration use https://github.com/emacs-helm/helm/ for details
(helm-mode)
(require 'helm-xref)
(define-key global-map [remap find-file] #'helm-find-files)
(define-key global-map [remap execute-extended-command] #'helm-M-x)
(define-key global-map [remap switch-to-buffer] #'helm-mini)


(defun billsix-c++-mode ()

  (which-key-mode)
  (add-hook 'c-mode-hook 'lsp)
  (add-hook 'c++-mode-hook 'lsp)

  (setq gc-cons-threshold (* 100 1024 1024)
        read-process-output-max (* 1024 1024)
        treemacs-space-between-root-nodes nil
        company-idle-delay 0.0
        company-minimum-prefix-length 1
        lsp-idle-delay 0.1)  ;; clangd is fast

  (with-eval-after-load 'lsp-mode
    (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration)
    (require 'dap-cpptools)
    (yas-global-mode))
  )

;; python
(defun billsix-python-mode ()
  (elpy-enable)
  (blacken-mode)
  )


;; theme
(load-theme 'material t)
;;(load-theme 'the-matrix t)
(visual-line-mode t)
(global-visual-line-mode t)
