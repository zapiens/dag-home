(defun ftx ()
  "Format TeXt chunk in YANG."
  ;; Place cursor anywhere inside the text chunk. The Text following
  ;; tailf-info up to "; will be filled as region. Handles thins like:
  ;;
  ;; tailf:info
  ;;   "Force resolver to re-query for resource records at
  ;;    cache-maximum-ttl seconds if its original ttl is greater than
  ;;    cache-maximum-ttl.";
  (interactive)
  (search-backward "\"" nil nil 1)
  (indent-for-tab-command)
  (beginning-of-line)
  (setq s (point-marker))
  (back-to-indentation)
  (setq e (point-marker))
  (copy-region-as-kill s e)
  ;; Fix the second line. The indentation of the second line is used as the
  ;; prefix for all indentaions in the fill-region
  (next-logical-line)
  (beginning-of-line)
  (setq s (point-marker))
  (back-to-indentation)
  (setq e (point-marker))
  (kill-region s e)
  (current-kill 1)
  (yank)
  (insert " ")
  ;; Now the second line is correctly indented, mark the text chunk and
  ;; fill-region
  (previous-logical-line)
  (beginning-of-line)
  (setq s (point-marker))
  (search-forward "\";" nil nil 1)
  (setq e (point-marker))
  (fill-region s e)
  (indent-for-tab-command)
  )
(defun fatt ()
  "Format attribute."
  ;; This will take the current line as presented in the tmsh manual like:
  ;;
  ;; delayed-acks [disabled | enabled]
  ;;
  ;; And rewrite it as:
  ;;
  ;; leaf delayed-acks {
  ;;   tailf:info
  ;;     "";
  ;;   type [disabled | enabled];
  ;; }
  ;;
  (interactive)
  (beginning-of-line)
  (indent-for-tab-command)
  (insert "leaf ")
  (search-forward " " nil nil 1)
  (insert "{")
  (newline-and-indent)
  (insert "tailf:info")
  (newline-and-indent)
  (insert "\"\";")
  (newline-and-indent)
  (insert "type ") (end-of-line) (insert ";")
  (newline-and-indent)
  (insert "}") (indent-for-tab-command)
  (next-logical-line))

(defun list_head ()
  "Generate a list head."
  (interactive)
  (beginning-of-line)
  (indent-for-tab-command)
  (insert "list ") (end-of-line)(insert " {")
  (indent-for-tab-command) (newline)
  (insert "tailf:info") (indent-for-tab-command) (newline)
  (insert "\"\";") (indent-for-tab-command) (newline)
  (insert "key name;") (indent-for-tab-command) (newline)
  (insert "leaf name {") (indent-for-tab-command) (newline)
  (insert "type string;") (indent-for-tab-command) (newline)
  (insert "}") (indent-for-tab-command) (newline)
  (insert "uses app-service-g;") (indent-for-tab-command) (newline)
  (insert "uses description-g;") (indent-for-tab-command) (newline)
  (insert "uses partition-g;") (indent-for-tab-command) (newline)
  (insert "}") (indent-for-tab-command) (indent-for-tab-command)
  (next-logical-line) (beginning-of-line) (indent-for-tab-command)
  )

(defun create_list ()
  "Create a typical BIGIP list, each line is list name and info"
  (interactive)
  (beginning-of-line)
  (indent-for-tab-command)
  (insert "list ")
  (setq s (point-marker))
  (search-forward " " nil nil 1) (backward-char)
  (setq e (point-marker))
  (copy-region-as-kill s e)
  (insert " {")
  (newline)
  (insert "tailf:info") (indent-for-tab-command) (newline)
  (indent-for-tab-command)
  (insert "\"") (end-of-line) (insert "\";") (indent-for-tab-command) (newline)
  (insert "key name;") (indent-for-tab-command) (newline)
  (insert "leaf name {") (indent-for-tab-command) (newline)
  (insert "type string;") (indent-for-tab-command) (newline)
  (insert "}") (indent-for-tab-command) (newline)
  (insert "uses app-service-t;") (indent-for-tab-command) (newline)

  ;; defaults-from
  (insert "leaf defaults-from {") (indent-for-tab-command) (newline)
  (insert "tailf:info") (indent-for-tab-command) (newline)
  (insert "\"Specifies the profile that you want to use as ")
  (insert "the parent profile.\";") (indent-for-tab-command) (newline)
  (insert "type string;") (indent-for-tab-command) (newline)
  (insert "tailf:non-strict-leafref {") (indent-for-tab-command) (newline)
  (insert "path \"../../") (yank) (insert "/name\";")
  (indent-for-tab-command) (newline)
  (insert "}") (indent-for-tab-command) (newline)

  ;; description
  (insert "leaf \"description\" {")(indent-for-tab-command) (newline)
  (insert "tailf:info")(indent-for-tab-command) (newline)
  (insert "\"User defined description.\";")(indent-for-tab-command) (newline)
  (insert "type string;")(indent-for-tab-command) (newline)
  (insert "}")(indent-for-tab-command) (newline)

  (insert "}") (indent-for-tab-command) (newline)
  (insert "}") (indent-for-tab-command)
  (next-line)
)
(defun replace_types ()
  "Rewrite some of the fundamental types in tmsh the their YANG counterpart"
  (interactive)
  (setq our_start (point-marker))

  (while (re-search-forward "\\[[ ]*enabled \| disabled[ ]*\\]" nil t)
    (replace-match "enabled-t"))
  (goto-char our_start)

  (while (re-search-forward "\\[[ ]*disabled \| enabled[ ]*\\]" nil t)
    (replace-match "enabled-t"))
  (goto-char our_start)

  (while (re-search-forward "\\[yes \| no\\]" nil t)
    (replace-match "yes-t"))
  (goto-char our_start)

  (while (re-search-forward "\\[no \| yes\\]" nil t)
    (replace-match "yes-t"))
  (goto-char our_start)

  (while (re-search-forward "\\[true \| false\\]" nil t)
    (replace-match "boolean"))
  (goto-char our_start)

  (while (re-search-forward "\\[false \| true\\]" nil t)
    (replace-match "boolean"))
  (goto-char our_start)

  (while (re-search-forward "\\[[ ]*\\[integer\\] \| none[ ]*\\]" nil t)
    (replace-match "uint32"))
  (goto-char our_start)

  (while (re-search-forward "\\[[ ]*\\[none\\] \| integer[ ]*\\]" nil t)
    (replace-match "uint32"))
  (goto-char our_start)

  (while (re-search-forward "\\[integer\\]" nil t)
    (replace-match "uint32"))
  (goto-char our_start)

  (while (re-search-forward "\\[[ ]*none \| string[ ]*\\]" nil t)
    (replace-match "string"))
  (goto-char our_start)

  (while (re-search-forward "\\[[ ]*string \| none[ ]*\\]" nil t)
    (replace-match "string"))
  (goto-char our_start)

  (while (re-search-forward "\\[string\\]" nil t)
    (replace-match "string"))
  (goto-char our_start)

  (while (re-search-forward "\\[name\\]" nil t)
    (replace-match "string"))
  (goto-char our_start)

  (while (re-search-forward "\\[ \\[ip address\\] \| none\\]" nil t)
    (replace-match "inet:ip-address"))
  (goto-char our_start)

  (while (re-search-forward "\\[ \\[hostname\\] \| none\\]" nil t)
    (replace-match "string"))
  (goto-char our_start)
  )

(defun insert_default ()
  (interactive)
  (newline)
  (previous-line)
  (indent-for-tab-command)
  (insert "default \"\";")
  (backward-char)
  (backward-char)
)

(defun load_bigip ()
  "Load bigip.el."
  (interactive)
  (load "~/dag-work/util/bigip.el")
  )

(global-set-key [f5]  'load_bigip )
(global-set-key [f6]  'ftx)
(global-set-key [f7]  'fatt)
(global-set-key [f8]  'list_head)
(global-set-key [f9]  'create_list)
;;(global-set-key [f10]  'insert_default
(global-set-key [f10]  'replace_types
)