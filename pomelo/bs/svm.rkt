#lang rosette
(require rosette/lib/destruct)
(require
  "../utils.rkt"
  "../config.rkt"
  (prefix-in bs:: "./ast.rkt")
  (prefix-in analysis:: "./analysis.rkt")
  )
(provide (all-defined-out))

; symbolic virtual machine

(define debug-output #f)

; stack is a stack, alt is a stack, script is a FILO list
(struct runtime (stack alt script symvars) #:mutable #:transparent #:reflection-name 'runtime)

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
        (loop)))))

(define (interpret* rt script-list)
  (if (null? script-list) (void)
      (begin
        (define o (car script-list))
        (step rt o)
        (interpret* rt (cdr script-list)))))

(define (interpret-script script #:auto-init [auto-init #f] #:debug [debug #f])
  (set! debug-output debug)
  (define rt
    (if auto-init
        (begin
          (define script-list (sequence->list script))
          (define stack (analysis::auto-init/stack script-list))
          (define alt (analysis::auto-init/alt script-list))
          (runtime stack alt (in-list script-list) '()))
        (runtime '() '() script '())))
  (when debug-output
    (print-stack (runtime-stack rt) "init (stack)")
    (printf "\n")
    (print-stack (runtime-alt rt) "init (alt stack)")
    (printf "\n"))
  (interpret rt)
  rt)

; 修改 step 函数
(define (step rt o)
  (when debug-output
    (printf "# stack:\n~a\n" (runtime-stack rt))
    (printf "# alt:\n~a\n" (runtime-alt rt))
    (printf "# next: ~a\n" o))
  (define unsupported (lambda (o) (error 'interpret (format "unsupported operator: ~a" o))))
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
   [(bs::op::pushbytes::x x)
    (match x
      [(bs::op::symint n)
       (define r (fresh-symbolic* n 'int))
       (set-runtime-symvars! rt (cons (cons n r) (runtime-symvars rt)))
       (push! rt r)]
      [_
       (if (bitvector? x)
           (push! rt x)
           (error 'step (format "Invalid type for OP_PUSHBYTES_X: ~a" x)))])]

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
    (if (&& (bvzero? x1) (bvzero? x2))
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
    (define r (fresh-symbolic* x 'int))
    (set-runtime-symvars! rt (cons (cons x r) (runtime-symvars rt)))
    (push! rt r)]

   ; OP_SOLVE doesn't push anything back to stack
   [(bs::op::solve)
    (define v (pop! rt))
    (define r (solve (assert v)))
    (printf "# OP_SOLVE result:\n~a\n" (evaluate r v))]

   [(bs::op::assert name expr)
    (printf "# ASSERT")
    (when name
      (printf " (~a)" name))
    (printf ":\n")
    (define verify-result (verify (assert (evaluate-expr rt expr))))
    (printf "  Verify result: ~a\n" verify-result)
    (if (unsat? verify-result)
        (printf "  Result: \033[1;32mVerified\033[0m\n\n")
        (begin
          (printf "  Result: \033[1;31mFailed\033[0m\n")
          (printf "  Counter-example: ~a\n\n" (evaluate expr (model verify-result)))))]

   [_ (error 'step (format "unsupported operator: ~a" o))]
   )
  )

(define (evaluate-expr rt expr)
  (destruct
   expr
   [(bs::expr::eq left right)
    (bveq (evaluate-expr rt left) (evaluate-expr rt right))]
   [(bs::expr::lt left right)
    (bvslt (evaluate-expr rt left) (evaluate-expr rt right))]
   [(bs::expr::lte left right)
    (bvsle (evaluate-expr rt left) (evaluate-expr rt right))]
   [(bs::expr::ite condition then-expr else-expr)
    (if (evaluate-expr rt condition)
        (evaluate-expr rt then-expr)
        (evaluate-expr rt else-expr))]
   [(bs::expr::bv value size)
    (bv value size)]
   [(bs::expr::var name)
    (get-variable rt name)]
   [(bs::expr::stack-nth n)
    (list-ref (runtime-stack rt) n)]
   [_ (error 'evaluate-expr (format "Unsupported expression: ~a" expr))]))

(define (get-variable rt name)
  (let ([var (assoc name (runtime-symvars rt))])
    (if var
        (cdr var)
        (error 'get-variable (format "Variable not found: ~a" name)))))
