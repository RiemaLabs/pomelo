#lang rosette
(require 
    "./config.rkt"
    (prefix-in ext:: "./extensions.rkt")
)
(provide (all-defined-out))

; ================================ ;
; ======== symbolic utils ======== ;
; ================================ ;

; id: symbol, type: symbol
(define (fresh-symbolic id type)
    (cond
        [(equal? 'int type)
            (constant (list id) ::bitvector)
        ]
        [(equal? 'bool type)
            (constant (list id) boolean?)
        ]
        [else (error "unknown symbolic type, got: ~a" type)]
    )
)

(define (fresh-symbolic* id type)
    (cond
        [(equal? 'int type)
                (constant (list id (ext::index!)) ::bitvector)
        ]
        [(equal? 'bool type)
                (constant (list id (ext::index!)) boolean?)
        ]
        [else (error "unknown symbolic type, got: ~a" type)]
    )
)

; ======================================================== ;
; ======== associate list (with symbolic support) ======== ;
; ======================================================== ;

; create a mutable struct so that we can update it like hash
; instead of creating a new copy every time (though down here it's still creating a new copy)
; it's like a box now which is mutable
(struct asl (vs) #:mutable #:transparent #:reflection-name 'asl)
(define (make-asl [vs null]) (asl vs))

(define (asl-ref lst key)
    (if (asl-has-key? lst key)
        (let ([p (car (asl-vs lst))])
            (if (equal? key (car p))
                (cdr p) ; found
                (asl-ref (asl (cdr (asl-vs lst))) key) ; not found, move next
            )
        )
        (error 'asl-ref (format "cannot find key: ~a" key))
    )
)

(define (asl-has-key? lst key)
    (if (null? (asl-vs lst))
        #f ; exhausted
        (let ([p (car (asl-vs lst))])
            (if (equal? key (car p))
                #t ; found
                (asl-has-key? (asl (cdr (asl-vs lst))) key) ; not found, move next
            )
        )
    )
)

; NOTE: this directly modifies the value
(define (asl-set! lst key val)
    (if (asl-has-key? lst key)
        (set-asl-vs! lst (for/list ([p (asl-vs lst)])
            (if (equal? key (car p))
                (cons key val) ; hit, update
                p ; not hit, keep
            )
        ))
        (set-asl-vs! lst (cons (cons key val) (asl-vs lst))) ; add pair directly
    )
    #t ; return true when done
)