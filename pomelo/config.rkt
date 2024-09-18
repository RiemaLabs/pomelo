#lang rosette
(provide (all-defined-out))

; global configuration
;   - default prefix is ::
;   - prefix is not recommended when using this as a package

(define ::bvsize 256) ; default bvsize
(define ::bitvector (bitvector ::bvsize)) ; default bitvector type