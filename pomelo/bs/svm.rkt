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
  (assert (bvslt n (length-bv s ::bitvector))
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
       (define r (fresh-symbolic* (format "v~a" n) 'int))
       (set-runtime-symvars! rt (cons (cons (format "v~a" n) r) (runtime-symvars rt)))
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
    (if (|| (bvzero? x1) (bvzero? x2))
        (push! rt (bv 0 ::bitvector))
        (push! rt (bv 1 ::bitvector))
        )
    ]

   [(bs::op::boolor)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (if (&& (bvzero? x1) (bvzero? x2))
        (push! rt (bv 0 ::bitvector))
        (push! rt (bv 1 ::bitvector))
        )
    ]

   [(bs::op::equal)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (define x1-extended (sign-extend x1 ::bitvector))
    (define x2-extended (sign-extend x2 ::bitvector))
    (define r (bool->bitvector (bveq x1-extended x2-extended) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::equalverify)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (define x1-extended (sign-extend x1 ::bitvector))
    (define x2-extended (sign-extend x2 ::bitvector))
    (assume (bveq x1-extended x2-extended) "equalverify failed")
    ]

   [(bs::op::verify)
    (define x1 (pop! rt))
    (assume (! (bvzero? x1)) "equalverify failed")
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
    (if (bvzero? v) (push! rt (bv 1 ::bitvector)) (push! rt (bv 0 ::bitvector)))
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
    (define a-extended (sign-extend a ::bitvector))
    (define b-extended (sign-extend b ::bitvector))
    (define r (bvadd a-extended b-extended))
    (push! rt r)
    ]

   [(bs::op::sub)
    (define b (pop! rt))
    (define a (pop! rt))
    (define a-extended (sign-extend a ::bitvector))
    (define b-extended (sign-extend b ::bitvector))
    (define r (bvsub a-extended b-extended))
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
    (assume (bveq a b) "numequalverify failed")
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
    (define b-extended (sign-extend b ::bitvector))
    (define a-extended (sign-extend a ::bitvector))
    (define r (bool->bitvector (bvslt a-extended b-extended) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::greaterthan)
    (define b (pop! rt))
    (define a (pop! rt))
    (define b-extended (sign-extend b ::bitvector))
    (define a-extended (sign-extend a ::bitvector))
    (define r (bool->bitvector (bvsgt a-extended b-extended) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::lessthanorequal)
    (define b (pop! rt))
    (define a (pop! rt))
    (define b-extended (sign-extend b ::bitvector))
    (define a-extended (sign-extend a ::bitvector))
    (define r (bool->bitvector (bvsle a-extended b-extended) ::bitvector))
    (push! rt r)
    ]

   [(bs::op::greaterthanorequal)
    (define b (pop! rt))
    (define a (pop! rt))
    (define b-extended (sign-extend b ::bitvector))
    (define a-extended (sign-extend a ::bitvector))
    (define r (bool->bitvector (bvsge a-extended b-extended) ::bitvector))
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
    (define r (fresh-symbolic* (format "v~a" x) 'int))
    (set-runtime-symvars! rt (cons (cons (format "v~a" x) r) (runtime-symvars rt)))
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
    (define type-check-result (type-check-expr rt expr))
    (printf "  Type Check: ~a\n" type-check-result)
    (define verify-result (verify (assert (evaluate-expr rt expr))))
    (if (unsat? verify-result)
        (printf "  Result: \033[1;32mVerified\033[0m\n\n")
        (begin
          (printf "  Result: \033[1;31mFailed\033[0m\n")
          (let ([model (model verify-result)])
            (printf "Model:\n")
            (hash-for-each model
                           (lambda (key value)
                             (printf "  ~a: ~a\n" key value))))))]

   [(bs::op::assume name expr)
    (printf "# ASSUME")
    (when name
      (printf " (~a)" name))
    (printf ":\n")
    (define assume-result (evaluate-expr rt expr))
    (assume assume-result)
    (printf "  Assumption added: ~a \n\n" (convert assume-result))]

   ; Modify the handling of PUSH_BIGINT
   [(bs::op::push_bigint nbits limb_size limbs_name var_name)
    (define n_limbs (ceiling (/ nbits limb_size)))
    (define highest_limb_size (- nbits (* (sub1 n_limbs) limb_size)))

    ;; Define the limbs list, ordered from least significant to most significant
    (define limbs
      (append
       ;; Lower limbs, there are n_limbs - 1, each with a width of limb_size + 1 for the sign bit
       (for/list ([i (in-range (sub1 n_limbs))])
         (define limb-name (format "~a[~a]" limbs_name i))
         (fresh-symbolic (list limb-name limb_size) 'bitvector))
       ;; Most significant limb, with a width of highest_limb_size + 1 for the sign bit
       (list
        (let ([highest-limb-name (format "~a[~a]" limbs_name (sub1 n_limbs))])
          (fresh-symbolic (list highest-limb-name highest_limb_size) 'bitvector)))))

    ;; Assume all limbs are positive >=0
    ;; Assume that in all bigints (a bigint = an array of n numbers), each number is positive (the highest bit of each number is 0), assuming all are positive by default
    (for ([limb limbs]
          [i (in-naturals)])
      (if (= i (sub1 n_limbs))
          (assume (bvzero? (extract (sub1 highest_limb_size) (sub1 highest_limb_size) limb)))
          (assume (bvzero? (extract (sub1 limb_size) (sub1 limb_size) limb)))))

    ;; Reconstruct the large integer x_reconstructed
    (define x_reconstructed
      (zero-extend
       (apply bvadd
              (for/list ([i (in-range n_limbs)]
                         [limb limbs])
                ;; Extend limb to nbits width
                (define extended_limb (zero-extend limb (bitvector nbits)))
                ;; Convert shift amount to a bitvector of nbits width
                (define shift_amount (bv (* i limb_size) nbits))
                ;; Perform left shift operation
                (bvshl extended_limb shift_amount))) ::bitvector))
    ;;; (printf "  nbits: ~a\n" nbits)
    ;;; (printf "  limb_size: ~a\n" limb_size)
    ;;; (printf "  limbs_name: ~a\n" limbs_name)
    ;;; (printf "  var_name: ~a\n" var_name)
    ;;; (for ([i (in-range n_limbs)]
    ;;;       [limb limbs])
    ;;;   (printf "    ~a_~a: ~a\n" limbs_name i limb))
    ;;; (printf "  x_reconstructed: ~a\n\n" x_reconstructed)

    ;; Define the symbolic variable x_symbol with a width of nbits
    ;;; (define x_symbol (bitvector nbits))
    ;; Use fresh-symbolic to define the symbolic variable x_symbol with a width of nbits
    (define id (string->symbol (format "v~a" var_name)))
    (define x_symbol (fresh-symbolic (list id ::bvsize) 'bitvector))
    ; Print x_symbol
    ;; Apply constraint: x_symbol == x_reconstructed
    (assume (bveq x_reconstructed x_symbol))

    ;; Push all elements of limbs onto the stack in reverse order
    ;; Since the stack is LIFO, push in reverse order
    (for ([limb (reverse limbs)])
      (push! rt limb))

    ;; Update the symbolic variable mapping
    (set-runtime-symvars! rt
                          (append (runtime-symvars rt)
                                  (list (cons (format "v~a" var_name) x_symbol))
                                  ;; Create name mapping for limbs
                                  (for/list ([i (in-range n_limbs)]
                                             [limb limbs])
                                    (cons (format "~a[~a]" limbs_name i) limb))))]


   [(bs::op::cat)
    (define x2 (pop! rt))
    (define x1 (pop! rt))
    (define result (concat x1 x2))
    ;;; (when (bvugt (length result) (bv MAX_SCRIPT_ELEMENT_SIZE ::bitvector))
    ;;;   (error 'step "OP_CAT result exceeds MAX_SCRIPT_ELEMENT_SIZE"))
    (push! rt result)]

   [_ (error 'step (format "unsupported operator: ~a" o))]
   )
  )

(define (evaluate-expr rt expr)
  (destruct
   expr
   [(bs::expr::eq left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bveq (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::lt left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvslt (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::lte left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvsle (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::ite condition then-expr else-expr)
    (if (evaluate-expr rt condition)
        (evaluate-expr rt then-expr)
        (evaluate-expr rt else-expr))]
   [(bs::expr::bv value)
    (bv value ::bitvector)]
   [(bs::expr::var name)
    (get-variable rt name)]
   [(bs::expr::stack-nth n)
    (list-ref (runtime-stack rt) n)]
   [(bs::expr::altstack-nth n)
    (list-ref (runtime-alt rt) n)]
   [(bs::expr::gt left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvsgt (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::gte left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvsge (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::neq left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (!(bveq (sign-extend l ::bitvector) (sign-extend r ::bitvector)))]
   [(bs::expr::not expr)
    (!(evaluate-expr rt expr))]
   [(bs::expr::and left right)
    (define x1 (evaluate-expr rt left))
    (define x2 (evaluate-expr rt right))
    (&& x1 x2)]
   [(bs::expr::or left right)
    (define x1 (evaluate-expr rt left))
    (define x2 (evaluate-expr rt right))
    (|| x1 x2)]
   [(bs::expr::add left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvadd (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::sub left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvsub (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::mul left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvmul (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::div left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvsdiv (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::mod left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvsmod (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::shl left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvshl (sign-extend l ::bitvector) (sign-extend r ::bitvector))]
   [(bs::expr::shr left right)
    (define l (evaluate-expr rt left))
    (define r (evaluate-expr rt right))
    (bvashr (sign-extend l ::bitvector) (sign-extend r ::bitvector))] ;; arithmetic right shift of x by y bits

   [_ (error 'evaluate-expr (format "unsupported expr: ~a" expr))]))

(define (get-variable rt name)
  (let ([var (assoc name (runtime-symvars rt))])
    ;;; (printf "var ~a: ~a\n" name var)
    (if var
        (cdr var)
        (error 'get-variable (format "Variable not found: ~a" name)))))


;;; Type Checker

; Define type enums
(define TYPE-BOOL 'bool)
(define TYPE-INT 'int)

; Main type checking function
(define (type-check-expr rt expr)
  (match expr
    [(bs::expr::eq left right)
     (check-equality rt 'eq left right)]

    [(bs::expr::lt left right)
     (check-numeric-comparison rt 'lt left right)]

    [(bs::expr::lte left right)
     (check-numeric-comparison rt 'lte left right)]

    [(bs::expr::gt left right)
     (check-numeric-comparison rt 'gt left right)]

    [(bs::expr::gte left right)
     (check-numeric-comparison rt 'gte left right)]

    [(bs::expr::ite condition then-expr else-expr)
     (check-if-then-else rt condition then-expr else-expr)]

    [(bs::expr::bv value)
     TYPE-INT]

    [(bs::expr::var name)
     (get-variable-type rt name)]

    [(bs::expr::stack-nth n)
     TYPE-INT] ; Assume all stack elements are integers

    [(bs::expr::altstack-nth n)
     TYPE-INT] ; Assume all stack elements are integers

    [(bs::expr::neq left right)
     (check-equality rt 'neq left right)]

    [(bs::expr::not expr)
     (check-not rt expr)]

    [(bs::expr::and left right)
     (check-boolean-operation rt 'and left right)]

    [(bs::expr::or left right)
     (check-boolean-operation rt 'or left right)]

    [(bs::expr::add left right)
     (check-numeric-operation rt 'add left right)]

    [(bs::expr::sub left right)
     (check-numeric-operation rt 'sub left right)]

    [(bs::expr::mul left right)
     (check-numeric-operation rt 'mul left right)]

    [(bs::expr::div left right)
     (check-numeric-operation rt 'mul left right)]

    [(bs::expr::mod left right)
     (check-numeric-operation rt 'mul left right)]

    [(bs::expr::shl left right)
     (check-numeric-operation rt 'mul left right)]

    [(bs::expr::shr left right)
     (check-numeric-operation rt 'mul left right)]

    [_ (error 'type-check-expr (format "Unsupported expression: ~a" expr))]))

; Helper function: Check equality operations
(define (check-equality rt op left right)
  (define left-type (type-check-expr rt left))
  (define right-type (type-check-expr rt right))
  (unless (equal? left-type right-type)
    (error 'type-check "Type mismatch in ~a: ~a and ~a" op left-type right-type))
  TYPE-BOOL)

; Helper function: Check numeric comparison operations
(define (check-numeric-comparison rt op left right)
  (define left-type (type-check-expr rt left))
  (define right-type (type-check-expr rt right))
  (unless (and (equal? left-type TYPE-INT) (equal? right-type TYPE-INT))
    (error 'type-check "Both operands of ~a must be integers" op))
  TYPE-BOOL)

; Helper function: Check if-then-else expression
(define (check-if-then-else rt condition then-expr else-expr)
  (unless (equal? (type-check-expr rt condition) TYPE-BOOL)
    (error 'type-check "Condition must be boolean in if-then-else"))
  (define then-type (type-check-expr rt then-expr))
  (define else-type (type-check-expr rt else-expr))
  (unless (equal? then-type else-type)
    (error 'type-check "Branches of if-then-else must have same type"))
  then-type)

; Helper function: Check not operation
(define (check-not rt expr)
  (unless (equal? (type-check-expr rt expr) TYPE-BOOL)
    (error 'type-check "Argument of 'not' must be boolean"))
  TYPE-BOOL)

; Helper function: Check boolean operations
(define (check-boolean-operation rt op left right)
  (define left-type (type-check-expr rt left))
  (define right-type (type-check-expr rt right))
  (unless (and (equal? left-type TYPE-BOOL) (equal? right-type TYPE-BOOL))
    (error 'type-check "Both operands of ~a must be boolean" op))
  TYPE-BOOL)

; Get variable type
(define (get-variable-type rt name)
  (let ([var (assoc name (runtime-symvars rt))])
    (if var
        TYPE-INT
        (error 'get-variable-type (format "Variable not found: ~a" name)))))

; Added helper function: Check numeric operations
(define (check-numeric-operation rt op left right)
  (define left-type (type-check-expr rt left))
  (define right-type (type-check-expr rt right))
  (unless (and (equal? left-type TYPE-INT) (equal? right-type TYPE-INT))
    (error 'type-check "Both operands of ~a must be int" op))
  TYPE-INT)