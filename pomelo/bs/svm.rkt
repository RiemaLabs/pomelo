#lang rosette
(require rosette/lib/destruct)
(require
  "../utils.rkt"
  "../config.rkt"
  (prefix-in bs:: "./ast.rkt")
  )
(provide (all-defined-out))

; symbolic virtual machine

; stack is a stack, alt is a stack, script is a FILO list
(struct runtime (stack alt script) #:mutable #:transparent #:reflection-name 'runtime)

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

; pop one element from alt stack; if empty, assert false
; inplace operation
; returns: head of alt stack
(define (alt/pop! rt)
  (let ([s (runtime-alt rt)])
    (assert (! (null? s)) "empty stack")
    (let ([h (car s)] [r (cdr s)])
      (set-runtime-alt! rt r) ; update stack
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

; push one element into runtime stack
; inplace operation
(define (alt/push! rt v)
  (let ([s (runtime-alt rt)])
    (set-runtime-alt! rt (cons v s))
    )
  )

; return the nth element from runtime stack
; if the index is out of range, assert false
(define (nth rt n)
  (define s (runtime-stack rt))
  (assert (bvult n (length-bv s ::bitvector)) "nth!: index out of range")
  (list-ref-bv s n)
  )

; remove the nth element from runtime stack, and return the removed element
; calls nth, so if the index is out of range, assert false
; inplace operation
(define (remove-nth! rt n)
  (define s (runtime-stack rt))
  (define x (nth rt n))
  (set-runtime-stack! rt (append (take-bv s n) (drop-bv s (bvadd1 n))))
  x
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
  (define unsupported (lambda (o) (error 'interpret (format "unsupported operator: ~a" o))))
  (let ([o (next! rt)])
    (when o
      (destruct
       o

       ; =========================== ;
       ; ======== push data ======== ;
       ; =========================== ;
       [(bs::op::0 ) (push! rt (bv 0 ::bitvector))]
       [(bs::op::1 ) (push! rt (bv 1 ::bitvector))]
       [(bs::op::false ) (push! rt (bv 0 ::bitvector))]
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
       [(bs::op::toaltstack)
        (define x1 (pop! rt))
        (alt/push! rt x1)
        ]

       [(bs::op::fromaltstack)
        (define x1 (alt/pop! rt))
        (push! rt x1)
        ]

       [(bs::op::ifdup)
        (define x (pop! rt))
        (if (bvzero? x)
            (push! rt x)
            (begin (push! rt x) (push! rt x))
            )
        ]

       [(bs::op::depth)
        (push! rt (length-bv (runtime-stack rt) ::bitvector))
        ]

       [(bs::op::drop)
        (pop! rt)
        ]

       [(bs::op::dup )
        (define x (pop! rt))
        (push! rt x)
        (push! rt x)
        ]

       [(bs::op::nip)
        (define x2 (pop! rt))
        (define _x1 (pop! rt))
        (push! rt x2)
        ]

       [(bs::op::over)
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x1)
        (push! rt x2)
        (push! rt x1)
        ]

       [(bs::op::pick)
        (define n (pop! rt))
        (define xn (nth rt n))
        (push! rt xn)
        ]

       [(bs::op::roll)
        (define n (pop! rt))
        (define x (remove-nth! rt n))
        (push! rt x)
        ]

       [(bs::op::rot)
        (define x3 (pop! rt))
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x2)
        (push! rt x3)
        (push! rt x1)
        ]

       [(bs::op::swap)
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x2)
        (push! rt x1)
        ]

       [(bs::op::tuck)
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x2)
        (push! rt x1)
        (push! rt x2)
        ]

       [(bs::op::2drop)
        (pop! rt)
        (pop! rt)
        ]

       [(bs::op::2dup)
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x1)
        (push! rt x2)
        (push! rt x1)
        (push! rt x2)
        ]

       [(bs::op::3dup)
        (define x3 (pop! rt))
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x1)
        (push! rt x2)
        (push! rt x3)
        (push! rt x1)
        (push! rt x2)
        (push! rt x3)
        ]

       [(bs::op::2over)
        (define x4 (pop! rt))
        (define x3 (pop! rt))
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x1)
        (push! rt x2)
        (push! rt x3)
        (push! rt x4)
        (push! rt x1)
        (push! rt x2)
        ]

       [(bs::op::2rot)
        (define x6 (pop! rt))
        (define x5 (pop! rt))
        (define x4 (pop! rt))
        (define x3 (pop! rt))
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x3)
        (push! rt x4)
        (push! rt x5)
        (push! rt x6)
        (push! rt x1)
        (push! rt x2)
        ]

       [(bs::op::2swap)
        (define x4 (pop! rt))
        (define x3 (pop! rt))
        (define x2 (pop! rt))
        (define x1 (pop! rt))
        (push! rt x3)
        (push! rt x4)
        (push! rt x1)
        (push! rt x2)
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
