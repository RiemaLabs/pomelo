#lang rosette
(require rosette/lib/destruct)
(require
  "../utils.rkt"
  "../config.rkt"
  (prefix-in bs:: "./ast.rkt")
  )
(provide (all-defined-out))

; symbolic virtual machine

; stack is a stack, script is a FILO list
(struct runtime (stack script) #:mutable #:transparent #:reflection-name 'runtime)

; tells whether a runtime script is terminated
(define (terminated? rt) (null? (runtime-script rt)))

; pop one element from runtime stack; if empty, assert false
; inplace operation
; returns: head of stack
(define (pop! rt)
  (let ([s (runtime-stack rt)])
    (assert (! (null? s)) "empty stack")
    (let ([h (car s)] [r (cdr s)])
      (set-runtime-stack! rt r) ; update stack
      h ; return head
      )
    )
  )

; push one element into runtime stack
; inplace operation
(define (push! rt v)
  (let ([s (runtime-stack rt)])
    (set-runtime-stack! rt (cons v s))
    )
  )

; remove the next operation from runtime script and return; if empty, return #f
; inplace operation
(define (next! rt)
  (let ([s (runtime-script rt)])
    (if (null? s) #f
        (let ([h (car s)] [r (cdr s)])
          (set-runtime-script! rt r) ; update script
          h ; return head
          )
        )
    )
  )

(define (interpret rt #:step [step #f])
  (let ([o (next! rt)])
    (when o
      (destruct
       o

       ; =========================== ;
       ; ======== push data ======== ;
       ; =========================== ;
       [(bs::op::0 ) (push! rt (bv 0 ::bitvector))]
       [(bs::op::false ) (push! rt (bv 0 ::bitvector))]

       [(bs::op::1 ) (push! rt (bv 1 ::bitvector))]
       [(bs::op::true ) (push! rt (bv 1 ::bitvector))]
       [(bs::op::x x) (push! rt (bv x ::bitvector))]

       ; ============================== ;
       ; ======== control flow ======== ;
       ; ============================== ;
       [(bs::op::branch thn els)
        (define v (pop! rt))
        (define script (runtime-script rt))
        (if (bvzero? v)
            (set-runtime-script! rt (append els script))
            (set-runtime-script! rt (append thn script))
            )
        ]


       ; ================================= ;
       ; ======== stack operators ======== ;
       ; ================================= ;
       [(bs::op::dup )
        (define v0 (pop! rt))
        (push! rt v0)
        (push! rt v0)
        ]

       ; ================================ ;
       ; ======== strings/splice ======== ;
       ; ================================ ;

       ; =============================== ;
       ; ======== bitwise logic ======== ;
       ; =============================== ;

       ; ==================================== ;
       ; ======== numeric/arithmetic ======== ;
       ; ==================================== ;
       [(bs::op::add )
        (define v1 (pop! rt))
        (define v0 (pop! rt))
        (define r (bvadd v0 v1))
        (push! rt r)
        ]

       [(bs::op::numequal )
        (define v1 (pop! rt))
        (define v0 (pop! rt))
        (define r (bveq v0 v1))
        (push! rt r)
        ]

       ; ============================== ;
       ; ======== cryptography ======== ;
       ; ============================== ;

       ; ================================ ;
       ; ======== locktime/other ======== ;
       ; ================================ ;

       ; ============================== ;
       ; ======== vacant words ======== ;
       ; ============================== ;
       ; no op code here

       ; ======================================= ;
       ; ======== pomela symbolic words ======== ;
       ; ======================================= ;
       [(bs::op::symint x)
        (define id (string->symbol (format "int$~a" x)))
        (define r (fresh-symbolic id 'int))
        (push! rt r)
        ]

       ; OP_SOLVE doesn't push anything back to stack
       [(bs::op::solve )
        (define v (pop! rt))
        (define r (solve (assert v)))
        (printf "# OP_SOLVE result:\n~a\n" r)
        ]

       [_ (error 'step (format "unsupported operator: ~a" o))]
       )
      )
    (when (! step)
      (when (! (terminated? rt))
        (interpret rt)
        )
      )
    )
  )
