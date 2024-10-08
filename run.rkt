#lang rosette
(require
  (prefix-in parser:: "./pomelo/bs/parser.rkt")
  (prefix-in svm:: "./pomelo/bs/svm.rkt")
  (prefix-in utils:: "./pomelo/utils.rkt")
  racket/string
  )

(define arg-str null)
(define arg-auto-init #f)
(define arg-debug #f)

(command-line
 #:once-any
 [("--str") p-str "bitcoin script (string)" (set! arg-str p-str)]
 [("--file") p-file "bitcoin script (file)" (set! arg-str (file->string p-file))]
 #:once-each
 [("--auto-init") "auto init stack" (set! arg-auto-init #t)]
 [("--debug") "enable debug output" (set! arg-debug #t)]
 )

(when (! (null? arg-str))
  (define script (parser::parse-str arg-str))
  (define rt (svm::interpret-script script #:auto-init arg-auto-init #:debug arg-debug))
  (when arg-debug
    (utils::print-stack (svm::runtime-stack rt) "result (stack)")
    (printf "\n")
    (utils::print-stack (svm::runtime-alt rt) "result (alt stack)")
    (printf "\n"))
  )