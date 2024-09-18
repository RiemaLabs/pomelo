#lang rosette
(require rosette/lib/destruct)
(require
    "../utils.rkt"
    "../config.rkt"
    (prefix-in bs:: "./ast.rkt")
)
(provide (all-defined-out))

; (concrete) virtual machine