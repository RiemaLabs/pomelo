#lang rosette

(require rosette/lib/synthax)
(require
  "../utils.rkt"
  "../config.rkt"
  "./ast.rkt"
  (prefix-in analysis:: "./analysis.rkt")
  (prefix-in svm:: "./svm.rkt")
  )
(provide (all-defined-out))

(define (bv*/range lo hi)
  (define-symbolic x ::bitvector)
  (assert (bvsle lo x))
  (assert (bvslt x hi))
  x)


(define-grammar (grammar/script consts)
  [script
   (choose '() (cons (op) (script)))]
  [op/stack
   (choose
    (op::toaltstack) (op::fromaltstack)
    (op::ifdup) (op::depth) (op::drop) (op::dup)
    (op::nip) (op::over) (op::pick) (op::roll)
    (op::rot) (op::swap) (op::tuck)
    (op::2drop) (op::2dup) (op::3dup)
    (op::2over) (op::2rot) (op::2swap)
    )]
  [op/arith
   (choose
    (op::1add) (op::1sub) (op::negate) (op::abs)
    (op::not) (op::0notequal)
    (op::add) (op::sub)
    (op::booland) (op::boolor)
    (op::numequal) (op::numequalverify) (op::numnotequal)
    (op::lessthan) (op::greaterthan) (op::lessthanorequal) (op::greaterthanorequal)
    (op::min) (op::max)
    (op::within)
    )]
  [op/flow
   (choose (op::nop))]
  ; [op
  ;  (choose (op/stack) (op/arith) (op/flow))]
  [op
   (choose (op/stack) (op/flow))]
  [const
   (choose consts)])

(define (check rt# rt*)
  (assert (equal? (svm::runtime-stack rt#) (svm::runtime-stack rt*)) "inequivalent stacks")
  ; (assert (equal? (svm::runtime-alt rt#) (svm::runtime-alt rt*)) "inequivalent alts")
  )

(define (syn script# #:depth [depth 3])
  (define script#-list (sequence->list script#))
  (define stack (analysis::auto-init/stack script#-list))
  (define alt (analysis::auto-init/alt script#-list))
  (define consts (for/list ([i (in-range 0 5)]) (integer->bitvector i ::bitvector)))
  (define script*-list (grammar/script consts #:depth depth))

  (printf "spec:   ~a\n" script#-list)
  (printf "initial stack: ~a\n" stack)
  (printf "initial alt: ~a\n" alt)

  (define rt# (svm::runtime stack alt '() '()))
  (define rt* (svm::runtime stack alt '() '()))

  (printf "Symbolic execution...\n")

  (svm::interpret* rt# script#-list)
  (svm::interpret* rt* script*-list)

  (printf "Synthesizing...\n")

  (define sol (synthesize
               #:forall (append stack alt)
               #:guarantee (check rt# rt*)))

  (if (sat? sol)
      (begin
        (printf "\033[1;32mSat\n")
        (printf "Optimized program:\n\033[0m~a\n" (evaluate script*-list sol)))
      (begin
        (printf "\033[1;31mUnsat\033[0m\n"))))