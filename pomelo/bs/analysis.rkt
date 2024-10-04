#lang rosette
(require rosette/lib/destruct)
(require
  "../utils.rkt"
  (prefix-in bs:: "./ast.rkt")
  )
(provide (all-defined-out))

(define (auto-init/stack script-list)
  (auto-init/n script-list (in-stack-size script-list)))

(define (auto-init/alt script-list)
  (auto-init/n script-list (in-alt-size script-list)))

; analyze the minimum input stack/alt size, and push the same # of symbolic values
(define (auto-init/n script-list n)
  (for/list ([i (in-range n)])
    (define id (string->symbol (format "int$~a" i)))
    (define r (fresh-symbolic id 'int))
    r))

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

(define (in-alt-size script)
  ; a list of op, prev op
  (for/fold ([n 0])
            ([o (reverse script)])
    (match-define (cons in out) (alt-delta/op o))
    (values (+ (max n out) (- in out)))
    )
  )

(define (alt-delta/op o)
  (-> bs::op? bs::op? (cons/c integer? integer?))
  (destruct
   o
   [(bs::op::toaltstack) (cons 0 1)]
   [(bs::op::fromaltstack) (cons 1 0)]
   [_ (cons 0 0)]
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
   [(bs::op::pushbytes::x _) (cons 0 1)]
   [_ (error 'stack-delta/op (format "unknown op: ~a" o))]
   )
  )

