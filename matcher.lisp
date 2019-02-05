(load "real_util.lisp")
(load "protoschemas.lisp")
(load "inference.lisp")

; CURRENT ASSUMPTIONS:
; 	1. The schema's intended episodes are all simultaneous
; 	2. The story's episodes are consecutive (though effects may endure)

; We're trying to match the intended episodes of the schema with episodes in
; the story.

; Although the story's episodes are consecutive, effects stated in earlier
; episodes may persist (via axioms about those things) until and unless
; negated in a later episode. Thus, they may be implicitly considered part
; of later episodes.

; When matching a schema episode with a candidate episode in the story,
; we apply a variety of inference rules. For example, if the story says (MOTHER5.SK GIVE-TO.V SHE.PRO KITTEN6.SK), but the schema says (?x do2.v (kind1-of.n activity1.n)), we have an inference rule that any (<individual> <verb>.v <args...>) story episode can be matched to the schema as the semantically equivalent (<individual> do2.v (ka <verb>.v <args...>)).
(defun match-story-with-schema (story schema)
	(loop for ep in (get-int-ep schema) do
		(format t "episode: ~s~%" ep)
		(setf ep_name (car ep))
		(setf episode (second ep))
	)
)

(defun extract-vars-wff (wff)
	(loop for e in wff
		if (varp e) append (list e)
		else if (listp e) append (extract-vars-wff e)
	)
)

(defun extract-vars (wffs)
	(remove-duplicates (loop for wff in wffs
		append (extract-vars-wff wff)
	) :test #'equal)
)

; mk-unbound-var-constraints returns a hash table of
; variable constraints for each variable in a list
; of WFFs. Each constraint specifies that any value
; bound to the variable must be equal to any pre-bound
; value for that same variable in this given bindings
; table.
(defun mk-unbound-var-constraints (wffs bindings)
(block outer
	(setf constrs (make-hash-table :test #'equal))

	(loop for var in (extract-vars wffs)
		do (setf (gethash var constrs)
			; When we match, only allow bindings that don't contradict
			; the bindings we know right now, before the match.
			(lambda (x)
				(or
					(null (gethash var bindings))
					(equal x (gethash var bindings))
				)
			)
		)
	)

	(return-from outer constrs)
)
)

; unifying two WFFs can be done using our match-formula function
; from the inference code, with a constraint predicate on every
; variable to ensure it wasn't bound already in the same schema.
(defun unify-wffs (wff1 wff2 bindings)
(block outer
	(match-formula-with-bindings wff1 wff2 nil bindings)
)
)


(defun match-wff-with-episodes (wff eps bindings)
(block outer
	; A single WFF could mean essentially the same thing
	; as several WFFs; we encode these transformations in
	; a set of "standard" inference rules, and we try each
	; form of the WFF when matching. We're happy with the
	; first match.
	; TODO: consider whether this should be baked into a more
	; general inference procedure for match-candidate WFFs.
	(loop for alt-wff in (apply-standard-rules wff)
		do (loop for ep in eps
			do (setf unify-res (unify-wffs wff ep bindings))
			if (not (null unify-res))
			do (return-from outer unify-res)
		)
	)
)
)

(defun match-wff-with-schema (wff schema bindings)
	(match-wff-with-episodes
		wff
		(mapcar #'second (get-int-ep schema))
	)
)

(defun match-story-with-schema (story schema)
(block outer
	(loop for schema-ep in (mapcar #'second (get-int-ep schema))
		do (setf match-binds (match-wff-with-episodes story))
		if (null match-binds)
		do (format t "couldn't bind WFF ~s~% to schema")
		else do (block inner
			(format t "current bindings:~%")
			(print-ht match-binds)
		)
	)

	(format t "final schema:~%~%~s~%~%" (apply-bindings schema match-binds))
)
)

; (match-story-with-schema nil do_for-pleasure.v)
