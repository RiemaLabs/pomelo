#lang rosette
(provide (all-defined-out))

; default prefix is ::
(define ::bvsize 256) ; default bvsize
(define ::bitvector (bitvector ::bvsize)) ; default bitvector type