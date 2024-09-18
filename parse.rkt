#lang rosette
(require
    (prefix-in parser:: "./pomelo/bs/parser.rkt")
)

(define arg-str null)

(command-line
    #:once-any
    [("--str") p-str "bitcoin script (string)" (set! arg-str p-str)]
)

(when (! (null? arg-str))
    (define script (parser::parse-str arg-str))
    (printf "~a\n" script)
)