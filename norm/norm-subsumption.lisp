(load "parse.lisp")
(load "norm-el.lisp")
(load "real_util.lisp")
(load "norm-wordnet.lisp")

(defparameter *MOVEMENT-PREDS* '(
	go.v
	come.v
	run.v
	walk.v
	crawl.v
	fly.v
))

(defparameter *RECEIVING-PREDS* '(
	take.v
	get.v
	receive.v
))

(defparameter *ENJOY-PREDS* '(
	like.v
	enjoy.v
	love.v
))

(defparameter *SPECIAL-SUBSUMPTIONS* (mk-hashtable '(
	((AGENT.N ANIMAL.N) t) ; animals are agents
	((FOOD.N FRUIT.N) t) ; fruit is food
)))

(defun get-schema-match-num (pred)
(block outer
	(if (symbolp pred)
		(setf spl (split-str (format nil "~s" pred) "."))
	)
	(if (and (symbolp pred)
			(> (length spl) 2)
			(is-num-str? (nth (- (length spl) 2) spl)))
		; then
		(return-from outer (parse-integer (nth (- (length spl) 2) spl)))
		; else
		(return-from outer nil)
	)
)
)

(defun get-schema-match-name (pred)
(block outer
	(if (symbolp pred)
		(setf spl (split-str (format nil "~s" pred) "."))
	)
	(if (and (symbolp pred)
			(> (length spl) 2)
			(is-num-str? (nth (- (length spl) 2) spl)))
		; then
		(return-from outer
			(intern (join-str-list "." (append
				(subseq spl 0 (- (length spl) 2))
				(last spl)
			)))
		)
		; else
		(return-from outer nil)
	)
)
)

(defun subsumes (schema-pred story-pred)
(block outer
	; If they're equal, schema subsumes story
	(if (equal schema-pred story-pred)
		(return-from outer t)
	)

	; If the story pred is a specification of the schema pred,
	; then schema subsumes story
	; TODO: proper hierarchy for inheritance
	(if (and (not (null (get-schema-match-num story-pred)))
			(equal (get-schema-match-name story-pred) schema-pred))
		; then
		(return-from outer t)
	)

	(if (and (equal schema-pred 'movement_verb.v)
			(not (null (member story-pred *MOVEMENT-PREDS* :test #'equal))))
		; then
		(return-from outer t)
	)

	(if (and (equal schema-pred 'receiving_verb?)
			(not (null (member story-pred *RECEIVING-PREDS* :test #'equal))))
		; then
		(return-from outer t)
	)

	(if (and (equal schema-pred 'enjoy_verb.v)
			(not (null (member story-pred *ENJOY-PREDS* :test #'equal))))
		; then
		(return-from outer t)
	)

	; Check explicit special cases
	(if (gethash (list schema-pred story-pred) *SPECIAL-SUBSUMPTIONS*)
		; then
		(return-from outer t)
	)

	; We should also check to see if any of the special case
	; specific predicates subsume our specific predicate, which
	; would transitively imply the special case general predicate.
	(loop for sc being the hash-keys of *SPECIAL-SUBSUMPTIONS*
		do (block check-scs-transitive
			(if (and (equal schema-pred (car sc))
					 (subsumes (second sc) story-pred))
				; then
				(return-from outer t)
			)
		)
	)

	; Check WordNet hypernym hierarchy
	(if (not (null (member schema-pred (wordnet-hypernyms story-pred))))
		(return-from outer t)
	)

	; Default case: no subsumption
	(return-from outer nil)
)
)

(defun word-sym-split (sym)
(let (symstr spl wspl word num pos)
(block outer
	(setf symstr (string sym))
	(setf spl (split-str symstr "."))
	(setf wspl (split-str (car spl) "#")

	(setf word (car wspl))
	(setf num (parse-integer (second wspl)))
	(setf pos (second spl))

	(return-from outer (list word num pos))
)
)
)
)

