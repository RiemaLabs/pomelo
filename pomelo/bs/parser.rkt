#lang rosette
(require
    "../utils.rkt"
    (prefix-in bs:: "./ast.rkt")
)
(provide (all-defined-out))

; parse bitcoin script from string
; returns: a list of bs language constructs
(define (parse-str s)
    (let ([slist (string-split s)])
        (for/list ([p slist])
            (parse-token p)
        )
    )
)

; parse a single string token
(define (parse-token t)
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