#lang rosette
(require
  (prefix-in parser:: "./pomelo/bs/parser.rkt")
  (prefix-in svm:: "./pomelo/bs/svm.rkt")
  )

(define arg-str null)

(define arg-auto-init #f)

(command-line
 #:once-any
 [("--str") p-str "bitcoin script (string)" (set! arg-str p-str)]
 [("--file") p-file "bitcoin script (file)" (set! arg-str (file->string p-file))]
 #:once-each
 [("--auto-init") "auto init stack" (set! arg-auto-init #t)]
 )

(when (! (null? arg-str))
  (define script (parser::parse-str arg-str))
  (define init-stack (if arg-auto-init #f '()))
  (define rt (svm::interpret-script script #:init-stack init-stack))
  (printf "# result (stack):\n~a\n" (svm::runtime-stack rt))
  (printf "# result (alt):\n~a\n" (svm::runtime-alt rt))
  )