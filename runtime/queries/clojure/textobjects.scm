; Textobjects for Clojure (Helix ships highlights/injections only).
; Function-like top-level forms: `]f` / `[f` jump, `maf` selects the whole form.
((list_lit
   .
   (sym_lit) @_head) @function.around
 (#match? @_head "^(defn|defn-|defmacro|defmethod|defmulti|fn|fn\\*|deftest|defprotocol|defrecord|deftype|definterface|defonce|def)$"))

; Everything after the head symbol and the name (params, docstring, body).
; `(_)+` with one capture name is grouped by Helix into a single range.
((list_lit
   .
   (sym_lit) @_head
   .
   (_)
   (_)+ @function.inside)
 (#match? @_head "^(defn|defn-|defmacro|defmethod|defmulti|deftest|defonce|def)$"))

(comment) @comment.inside
(comment)+ @comment.around
