#lang rosette
(require
    (prefix-in parser:: "./pomelo/parser.rkt")
    (prefix-in svm:: "./pomelo/svm.rkt")
)

(define arg-str null)

(command-line
    #:once-any
    [("--str") p-str "bitcoin script (string)" (set! arg-str p-str)]
)

(when (! (null? arg-str))
    (define script (parser::parse-str arg-str))
    (define rt (svm::runtime (list ) script))
    (svm::interpret rt #:step #f)
    (printf "# result (stack):\n~a\n" (svm::runtime-stack rt))
)