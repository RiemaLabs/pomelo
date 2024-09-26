#lang rosette
(provide (all-defined-out))

; global configuration
;   - default prefix is ::
;   - prefix is not recommended when using this as a package

(define ::bvsize 256) ; default bvsize
; (define ::bvsize 4160) ; default bvsize (520 bytes, bs single element limit)
(define ::bitvector (bitvector ::bvsize)) ; default bitvector type