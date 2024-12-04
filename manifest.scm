(use-modules (gnu packages racket)
	     (gnu packages version-control)
	     (gnu packages node))

(packages->manifest (list racket git node))
