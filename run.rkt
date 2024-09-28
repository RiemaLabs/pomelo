#lang rosette
(require
  (prefix-in parser:: "./pomelo/bs/parser.rkt")
  (prefix-in svm:: "./pomelo/bs/svm.rkt")
  )

(define arg-str null)

(command-line
 #:once-any
 [("--str") p-str "bitcoin script (string)" (set! arg-str p-str)]
 [("--file") p-file "bitcoin script (file)" (set! arg-str (file->string p-file))]
 )

(when (! (null? arg-str))
  (define script (parser::parse-str arg-str))
  (define rt (svm::runtime (list) (list) script))
  (svm::interpret rt)
  (printf "# result (stack):\n~a\n" (svm::runtime-stack rt))
  (printf "# result (alt):\n~a\n" (svm::runtime-alt rt))
  )