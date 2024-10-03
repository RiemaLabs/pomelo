#lang rosette
(require rosette/lib/destruct)
(require racket/generator)
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
  (define msg (format "nth!: index ~a >= depth ~a" n (length-bv s ::bitvector)))
  (assert (bvult n (length-bv s ::bitvector))
          msg
          ; "index out of range")
          )

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

(define (interpret rt)
  (define-values (more? next) (sequence-generate (runtime-script rt)))
  (let loop ()
    (when (more?)
      (let ([o (next)])
        (step rt o)
        (loop)
        )
      )
    )
  )

(define (interpret-script script #:init-stack [init-stack #f])
  (define rt
    (if init-stack
        (runtime init-stack '() script)
        (begin
          (define script-list (sequence->list script))
          (printf "# script:\n~a\n" script-list)
          (define n (in-stack-size script-list))
          (define stack
            (for/list ([i (in-range n)])
              (define id (string->symbol (format "int$~a" i)))
              (define r (fresh-symbolic id 'int))
              r))
          (runtime stack '() (in-list script-list)))))
  (printf "# init stack:\n~a\n" (runtime-stack rt))
  (interpret rt)
  rt
  )

; return the number of input items that must be on stack for the script
(define (in-stack-size script)
  ; a list of op, prev op
  (define rshift (cons #f (take script (sub1 (length script)))))
  (define os (map cons script rshift))
  (for/fold ([n 0])
            ([o-p (reverse os)])
    (match-define (cons o p) o-p)
    (match-define (cons in out) (stack-delta/op o p))
    (values (+ (max n out) (- in out)))
    )
  )

; return the maximum number of input items that must be on stack for the given op
; and the minimum number of output items that will be on stack after the op
(define (stack-delta/op o prev)
  (-> bs::op? bs::op? (cons/c integer? integer?))
  ; (printf "# stack-delta/op: ~a prev: ~a\n" o prev)
  (destruct
   o
   ;  [(bs::op::branch thn els)
   ; (match-define (cons thn-in thn-out) (stack-delta/script thn))
   ; (match-define (cons els-in els-out) (stack-delta/script els))
   ; (assert (= thn-in els-in) "branch: inconsistent input stack size")
   ; (assert (= thn-out els-out) "branch: inconsistent output stack size")
   ; (cons (add1 thn-in) thn-out)
   ; ]
   [(bs::op::toaltstack)
    ; moves one item to alt stack
    (cons 1 0)]
   [(bs::op::fromaltstack)
    ; moves one item from alt stack
    (cons 0 1)]
   [(bs::op::ifdup)
    ; if condition is true, consumes 2 (cond + item), produces 2
    ; if condition is false, consumes 1 (cond), produces 0
    (cons 2 0)]
   [(bs::op::depth) (cons 0 1)]
   [(bs::op::drop) (cons 1 0)]
   [(bs::op::dup) (cons 1 2)]
   [(bs::op::nip) (cons 2 1)]
   [(bs::op::over) (cons 2 3)]
   [(bs::op::pick)
    (destruct prev
              [(bs::op::pushbits bs)
               (define n (bitvector->integer bs))
               (cons (+ n 2) (+ n 1))]
              [_ (error 'stack-delta/op (format "pick: unknown previous op: ~a" prev))]
              )
    ]
   [(bs::op::roll)
    (destruct prev
              [(bs::op::pushbits bs)
               (define n (bitvector->integer bs))
               (cons (+ n 1) n)]
              [_ (error 'stack-delta/op (format "roll: unknown previous op: ~a" prev))]
              )
    ]
   [(bs::op::rot)  (cons 3 3)]
   [(bs::op::swap) (cons 2 2)]
   [(bs::op::tuck) (cons 2 3)]
   [(bs::op::2drop) (cons 2 0)]
   [(bs::op::2dup)  (cons 2 4)]
   [(bs::op::3dup)  (cons 3 6)]
   [(bs::op::2over) (cons 4 4)]
   [(bs::op::2rot)  (cons 6 6)]
   [(bs::op::2swap) (cons 4 4)]
   [(bs::op::booland) (cons 2 1)]
   [(bs::op::boolor) (cons 2 1)]
   [(bs::op::equal) (cons 2 1)]
   [(bs::op::equalverify) (cons 2 0)]
   [(bs::op::0notequal) (cons 2 1)]
   [(bs::op::add) (cons 2 1)]
   [(bs::op::sub) (cons 2 1)]
   [(bs::op::numequal) (cons 2 1)]
   [(bs::op::numequalverify) (cons 2 0)]
   [(bs::op::numnotequal) (cons 2 1)]
   [(bs::op::lessthan) (cons 2 1)]
   [(bs::op::greaterthan) (cons 2 1)]
   [(bs::op::lessthanorequal) (cons 2 1)]
   [(bs::op::greaterthanorequal) (cons 2 1)]
   [(bs::op::min) (cons 2 1)]
   [(bs::op::max) (cons 2 1)]
   [(bs::op::within) (cons 3 1)]
   [(bs::op::symint _) (cons 0 1)]
   [(bs::op::solve) (cons 1 0)]
   [(bs::op::pushbits _) (cons 0 1)]
   [_ (error 'stack-delta/op (format "unknown op: ~a" o))]
   )
  )


(define (step rt o)
  (define unsupported (lambda (o) (error 'interpret (format "unsupported operator: ~a" o))))
  (printf "# stack:\n~a\n" (runtime-stack rt))
  (printf "# alt:\n~a\n" (runtime-alt rt))
  (printf "# next: ~a\n" o)
  (destruct
   o

   ; =========================== ;
   ; ======== push data ======== ;
   ; =========================== ;
   [(bs::op::0) (push! rt (bv 0 ::bitvector))]
   [(bs::op::1) (push! rt (bv 1 ::bitvector))]
   [(bs::op::false) (push! rt (bv 0 ::bitvector))]
   [(bs::op::true) (push! rt (bv 1 ::bitvector))]
   [(bs::op::x x) (push! rt (bv x ::bitvector))]
   [(bs::op::pushbits bs) (push! rt bs)]

   ; ============================== ;
   ; ======== control flow ======== ;
   ; ============================== ;
   [(bs::op::branch thn els)
    (define v (pop! rt))

    (if (bvzero? v)
        (begin
          (set-runtime-script! rt els)
          (interpret rt)
          )
        (begin
          (set-runtime-script! rt thn)
          (interpret rt)
          )
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

   [(bs::op::dup)
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

   [(bs::op::booland)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (if (|| (bvzero? x1) (bvzero? x2))
        (push! rt (bv 0 ::bitvector))
        (push! rt (bv 1 ::bitvector))
        )
    ]

   [(bs::op::boolor)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (if (|| (bvzero? x1) (bvzero? x2))
        (push! rt (bv 0 ::bitvector))
        (push! rt (bv 1 ::bitvector))
        )
    ]

   [(bs::op::equal)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (define r (bool->bitvector (bveq x1 x2) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::equalverify)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (assert (bveq x1 x2) "equalverify failed")
    ]

   ; ==================================== ;
   ; ======== numeric/arithmetic ======== ;
   ; ==================================== ;
   [(bs::op::1add)
    (define v (pop! rt))
    (push! rt (bvadd1 v))
    ]

   [(bs::op::1sub)
    (define v (pop! rt))
    (push! rt (bvsub1 v))
    ]

   [(bs::op::negate)
    (define v (pop! rt))
    (push! rt (bvneg v))
    ]

   [(bs::op::abs)
    (define v (pop! rt))
    (if (bvslt v (bv 0 ::bitvector))
        (push! rt (bvneg v))
        (push! rt v)
        )
    ]

   [(bs::op::not)
    (define v (pop! rt))
    (cond
      [(bvzero? v) (push! rt (bv 1 ::bitvector))]
      [(bveq v (bv 1 ::bitvector)) (push! rt (bv 0 ::bitvector))]
      [else (push! rt (bv 0 ::bitvector))]
      )
    ]

   [(bs::op::0notequal)
    (define v (pop! rt))
    (if (bvzero? v)
        (push! rt (bv 0 ::bitvector))
        (push! rt (bv 1 ::bitvector))
        )
    ]

   [(bs::op::add)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bvadd a b))
    (push! rt r)
    ]

   [(bs::op::sub)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bvsub a b))
    (push! rt r)
    ]

   [(bs::op::numequal)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bool->bitvector (bveq a b) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::numequalverify)
    (define b (pop! rt))
    (define a (pop! rt))
    (assert (bveq a b) "numequalverify failed")
    ]


   [(bs::op::numnotequal)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bool->bitvector (! (bveq a b)) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::lessthan)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bool->bitvector (bvslt a b) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::greaterthan)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bool->bitvector (bvsgt a b) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::lessthanorequal)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bool->bitvector (bvsle a b) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::greaterthanorequal)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bool->bitvector (bvsge a b) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::min)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bvsmin a b))
    (push! rt r)
    ]

   [(bs::op::max)
    (define b (pop! rt))
    (define a (pop! rt))
    (define r (bvsmax a b))
    (push! rt r)
    ]

   [(bs::op::within)
    (define max (pop! rt))
    (define min (pop! rt))
    (define x (pop! rt))
    (define r (bool->bitvector (&& (bvsle min x) (bvslt x max)) ::bitvector))
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
   [(bs::op::solve)
    (define v (pop! rt))
    (define r (solve (assert v)))
    (printf "# OP_SOLVE result:\n~a\n" (evaluate r v))
    ]

   [_ (error 'step (format "unsupported operator: ~a" o))]
   )
  )


