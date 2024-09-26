#lang rosette
(require racket/sequence)
(require racket/generator)
(require
  "../utils.rkt"
  (prefix-in bs:: "./ast.rkt")
  )
(provide (all-defined-out))


; parse bitcoin script from string
; returns: a list of bs language constructs
(define (parse-str s)
  ; token generator
  (define tok-seq (in-list (string-split s)))
  (for/list ([t (parse-tokens tok-seq)]) t)
  )

(define (parse-tokens g)
  (define-values (more? get) (sequence-generate g))
  (in-generator
   (let loop ()
     (when (more?)
       (yield (parse-token (get) get))
       (loop)))
   )
  )

(define (parse-token/if g)
  (println "parse-token/if")
  (define thn '())
  (define els '())
  (let loop ([in-then? #t])
    (define t (parse-token (g) g))
    (match t
      [(bs::op::endif) (void)]
      [(bs::op::else) (set! in-then? #f) (loop #f)]
      [_ (if in-then? (set! thn (cons t thn)) (set! els (cons t els))) (loop in-then?)]))
  (bs::op::branch (reverse thn) (reverse els)))


; parse a single string token t and generator g holding the rest of the tokens
(define (parse-token t g)
  (cond

    ; =========================== ;
    ; ======== push data ======== ;
    ; =========================== ;
    [(equal? "OP_0" t) (bs::op::0 )]
    [(equal? "OP_FALSE" t) (bs::op::false )]
    [(equal? "OP_PUSHDATA1" t) (bs::op::pushdata::x 1)]
    [(equal? "OP_PUSHDATA2" t) (bs::op::pushdata::x 2)]
    [(equal? "OP_PUSHDATA4" t) (bs::op::pushdata::x 4)]
    [(equal? "OP_1NEGATE" t) (bs::op::1negate )]
    [(equal? "OP_RESERVED" t) (bs::op::reserved )]
    [(equal? "OP_1" t) (bs::op::1 )]
    [(equal? "OP_TRUE" t) (bs::op::true )]

    ; ============================== ;
    ; ======== control flow ======== ;
    ; ============================== ;
    [(equal? "OP_NOP" t) (bs::op::nop )]
    [(equal? "OP_DUP" t) (bs::op::dup )]
    [(equal? "OP_IF"  t) (parse-token/if g)]
    [(equal? "OP_ELSE" t) (bs::op::else)]
    [(equal? "OP_ENDIF" t) (bs::op::endif)]

    ; ================================= ;
    ; ======== stack operators ======== ;
    ; ================================= ;
    [(equal? "OP_TOALTSTACK" t) (bs::op::toaltstack )]

    ; ================================ ;
    ; ======== strings/splice ======== ;
    ; ================================ ;
    [(equal? "OP_CAT" t) (bs::op::cat )]

    ; =============================== ;
    ; ======== bitwise logic ======== ;
    ; =============================== ;
    [(equal? "OP_INVERT" t) (bs::op::invert )]

    ; ==================================== ;
    ; ======== numeric/arithmetic ======== ;
    ; ==================================== ;
    [(equal? "OP_1ADD" t) (bs::op::1add )]
    [(equal? "OP_ADD" t) (bs::op::add )]
    [(equal? "OP_NUMEQUAL" t) (bs::op::numequal )]

    ; ============================== ;
    ; ======== cryptography ======== ;
    ; ============================== ;
    [(equal? "OP_RIPEMD160" t) (bs::op::ripemd160 )]

    ; ================================ ;
    ; ======== locktime/other ======== ;
    ; ================================ ;
    [(equal? "OP_NOP1" t) (bs::op::nop1 )]

    ; ============================== ;
    ; ======== vacant words ======== ;
    ; ============================== ;
    ; no op code here

    ; ======================================= ;
    ; ======== pomela symbolic words ======== ;
    ; ======================================= ;
    [(string-prefix? t "OP_SYMINT_") (parse-token/symint t)]
    [(equal? "OP_SOLVE" t) (bs::op::solve )]

    ; order sensitive
    [(string-prefix? t "OP_PUSHBYTES_") (parse-token/pushbytes t)]
    [(string-prefix? t "OP_") (parse-token/x t)]

    [else (error 'parse-token (format "unsupported token: ~a" t))]
    )
  )


; parse string token starting with OP_PUSHBYTES_
(define (parse-token/pushbytes t)
  (let ([ns (substring t 13)])
    ; convert to number, it's decimal (weird but true, not hex)
    (define n (string->number ns))
    (assert (integer? n) (format "OP_PUSHBYTES_ argument should be integer, got: ~a" ns))
    (assert (&& (<= 1 n) (<= n 75)) (format "OP_PUSHBYTES_ argument range is invalid, got: ~a" n))
    (bs::op::pushbytes::x n)
    )
  )

; parse string token starting with OP_
(define (parse-token/x t)
  (let ([ns (substring t 3)])
    ; convert to number, it's decimal (weird but true, not hex)
    (define n (string->number ns))
    (assert (integer? n) (format "OP_ argument should be integer, got: ~a" ns))
    (assert (&& (<= 2 n) (<= n 16)) (format "OP_ argument range is invalid, got: ~a" n))
    (bs::op::x n)
    )
  )

; parse string token starting with OP_SYMINT_
(define (parse-token/symint t)
  (let ([ns (substring t 10)])
    ; convert to number, it's decimal
    (define n (string->number ns))
    (assert (integer? n) (format "OP_SYMINT_ argument should be integer, got: ~a" ns))
    (assert (>= n 0) (format "OP_SYMINT_ argument should be non-negative, got: ~a" n))
    (bs::op::symint n)
    )
  )