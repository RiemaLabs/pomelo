#lang rosette
(require racket/sequence)
(require racket/generator)
(require file/sha1)
(require
  "../utils.rkt"
  "../config.rkt"
  (prefix-in bs:: "./ast.rkt")
  )
(provide (all-defined-out))


(define (line-generator filename)
  (let ((in-port (open-input-file filename)))
    (in-generator
     (let loop ()
       (define line (read-line in-port 'any))
       (if (eof-object? line)
           (begin
             (close-input-port in-port)
             #f) ; Return #f to signal the end of the file
           (begin
             (yield line)
             (loop)))))))


; parse bitcoin script from string
; returns: a sequence of bs language constructs
(define (parse-str s)
  (define tseq (in-list (string-split s)))
  (parse-tokens tseq)
  )

; parse bitcoin script from file
; returns: a sequence of bs language constructs
(define (parse-file filename)
  (define tseq (line-generator filename))
  (parse-tokens tseq)
  )

; produce a sequence tokens from a sequence of strings
(define/contract (parse-tokens tseq)
  (-> (sequence/c string?) (sequence/c bs::op?))
  (define-values (more? get) (sequence-generate tseq))
  (define token-gen (make-token-generator get))
  (in-generator
   (let loop ()
     (when (more?)
       (yield (parse-token (token-gen) token-gen))
       (loop)))))

; parse tokens into a branching op
(define/contract (parse-token/branch get [not? #f])
  (-> procedure? bs::op::branch?)
  ; accumulators for then and else branches
  (define thn '())
  (define els '())
  ; start by assuming we are in the then branch
  (let loop ([in-then? #t])
    (define t (parse-token (get) get))
    (match t
      [(bs::op::endif)
       (void)]
      [(bs::op::else)
       ; switch to else branch
       (loop #f)]
      [_
       ; add to either then or else branch
       (if in-then?
           (set! thn (cons t thn))
           (set! els (cons t els)))
       ; continue
       (loop in-then?)]))
  (if not?
      (bs::op::branch (reverse els) (reverse thn))
      (bs::op::branch (reverse thn) (reverse els))))



; parse a string token t into an op, where generator g holds the rest of the tokens
(define/contract (parse-token t g)
  (-> string? procedure? bs::op?)
  (case t
    [("OP_ASSERT") 
     (define expr (parse-assert-expr g))
     (bs::op::assert expr)]
    [("OP_SOLVE") (bs::op::solve)]
    [else
     (cond

       ; =========================== ;
       ; ======== push data ======== ;
       ; =========================== ;
       ; Push Data (97), opcodes 0x0-0x60
       [(equal? "OP_0" t) (bs::op::0 )]
       [(equal? "OP_FALSE" t) (bs::op::false )]
       [(equal? "OP_PUSHDATA1" t) (bs::op::pushdata::x 1)]
       [(equal? "OP_PUSHDATA2" t) (bs::op::pushdata::x 2)]
       [(equal? "OP_PUSHDATA4" t) (bs::op::pushdata::x 4)]
       [(equal? "OP_1NEGATE" t) (bs::op::1negate )]
       [(equal? "OP_RESERVED" t) (bs::op::reserved )]
       [(equal? "OP_1" t) (bs::op::1 )]
       [(equal? "OP_TRUE" t) (bs::op::true )]

       ; ============================== ;
       ; ======== control flow ======== ;
       ; ============================== ;
       ; Control Flow (10), opcodes 0x61-0x6a
       [(equal? "OP_NOP" t) (bs::op::nop )]
       [(equal? "OP_VER" t) (bs::op::ver )]
       [(equal? "OP_IF" t) (parse-token/branch g )]
       [(equal? "OP_NOTIF" t) (parse-token/branch g )]
       [(equal? "OP_VERIF" t) (bs::op::verif )]
       [(equal? "OP_VERNOTIF" t) (bs::op::vernotif )]
       [(equal? "OP_ELSE" t) (bs::op::else )]
       [(equal? "OP_ENDIF" t) (bs::op::endif )]
       [(equal? "OP_VERIFY" t) (bs::op::verify )]
       [(equal? "OP_RETURN" t) (bs::op::return )]

       ; ================================= ;
       ; ======== stack operators ======== ;
       ; ================================= ;
       ; Stack Operation (19), opcodes 0x6a-0x7d
       [(equal? "OP_TOALTSTACK" t) (bs::op::toaltstack )]
       [(equal? "OP_FROMALTSTACK" t) (bs::op::fromaltstack )]
       [(equal? "OP_2DROP" t) (bs::op::2drop )]
       [(equal? "OP_2DUP" t) (bs::op::2dup )]
       [(equal? "OP_3DUP" t) (bs::op::3dup )]
       [(equal? "OP_2OVER" t) (bs::op::2over )]
       [(equal? "OP_2ROT" t) (bs::op::2rot )]
       [(equal? "OP_2SWAP" t) (bs::op::2swap )]
       [(equal? "OP_IFDUP" t) (bs::op::ifdup )]
       [(equal? "OP_DEPTH" t) (bs::op::depth )]
       [(equal? "OP_DROP" t) (bs::op::drop )]
       [(equal? "OP_DUP" t) (bs::op::dup )]
       [(equal? "OP_NIP" t) (bs::op::nip )]
       [(equal? "OP_OVER" t) (bs::op::over )]
       [(equal? "OP_PICK" t) (bs::op::pick )]
       [(equal? "OP_ROLL" t) (bs::op::roll )]
       [(equal? "OP_ROT" t) (bs::op::rot )]
       [(equal? "OP_SWAP" t) (bs::op::swap )]
       [(equal? "OP_TUCK" t) (bs::op::tuck )]

       ; ================================ ;
       ; ======== strings/splice ======== ;
       ; ================================ ;
       ; Strings (5), opcodes 0x7e-0x82
       [(equal? "OP_SIZE" t) (bs::op::size )]

       ; =============================== ;
       ; ======== bitwise logic ======== ;
       ; =============================== ;
       ; Bitwise Logic (8), opcodes 0x83-0x8a
       [(equal? "OP_EQUAL" t) (bs::op::equal )]
       [(equal? "OP_EQUALVERIFY" t) (bs::op::equalverify )]
       [(equal? "OP_RESERVED1" t) (bs::op::reserved1 )]
       [(equal? "OP_RESERVED2" t) (bs::op::reserved2 )]

       ; ==================================== ;
       ; ======== numeric/arithmetic ======== ;
       ; ==================================== ;
       ; Numeric (27), opcodes 0x8b-0xa5
       [(equal? "OP_1ADD" t) (bs::op::1add )]
       [(equal? "OP_1SUB" t) (bs::op::1sub )]
       [(equal? "OP_NEGATE" t) (bs::op::negate )]
       [(equal? "OP_ABS" t) (bs::op::abs )]
       [(equal? "OP_NOT" t) (bs::op::not )]
       [(equal? "OP_0NOTEQUAL" t) (bs::op::0notequal )]
       [(equal? "OP_ADD" t) (bs::op::add )]
       [(equal? "OP_SUB" t) (bs::op::sub )]
       [(equal? "OP_BOOLAND" t) (bs::op::booland )]
       [(equal? "OP_BOOLOR" t) (bs::op::boolor )]
       [(equal? "OP_NUMEQUAL" t) (bs::op::numequal )]
       [(equal? "OP_NUMEQUALVERIFY" t) (bs::op::numequalverify )]
       [(equal? "OP_NUMNOTEQUAL" t) (bs::op::numnotequal )]
       [(equal? "OP_LESSTHAN" t) (bs::op::lessthan )]
       [(equal? "OP_GREATERTHAN" t) (bs::op::greaterthan )]
       [(equal? "OP_LESSTHANOREQUAL" t) (bs::op::lessthanorequal )]
       [(equal? "OP_GREATERTHANOREQUAL" t) (bs::op::greaterthanorequal )]
       [(equal? "OP_MIN" t) (bs::op::min )]
       [(equal? "OP_MAX" t) (bs::op::max )]
       [(equal? "OP_WITHIN" t) (bs::op::within )]

       ; ============================== ;
       ; ======== cryptography ======== ;
       ; ============================== ;
       ; Cryptography (10), opcodes 0xa6-0xaf
       [(equal? "OP_RIPEMD160" t) (bs::op::ripemd160 )]
       [(equal? "OP_SHA1" t) (bs::op::sha1 )]
       [(equal? "OP_SHA256" t) (bs::op::sha256 )]
       [(equal? "OP_HASH160" t) (bs::op::hash160 )]
       [(equal? "OP_HASH256" t) (bs::op::hash256 )]
       [(equal? "OP_CODESEPARATOR" t) (bs::op::codeseparator )]
       [(equal? "OP_CHECKSIG" t) (bs::op::checksig )]
       [(equal? "OP_CHECKSIGVERIFY" t) (bs::op::checksigverify )]
       [(equal? "OP_CHECKMULTISIG" t) (bs::op::checkmultisig )]
       [(equal? "OP_CHECKMULTISIGVERIFY" t) (bs::op::checkmultisigverify )]

       ; ================================ ;
       ; ======== locktime/other ======== ;
       ; ================================ ;
       [(equal? "OP_NOP1" t) (bs::op::nop1 )]
       [(equal? "OP_CHECKLOCKTIMEVERIFY" t) (bs::op::checklocktimeverify )]
       [(equal? "OP_CHECKSEQUENCEVERIFY" t) (bs::op::checksequenceverify )]
       [(equal? "OP_CHECKSEQUENCEVERIFY" t) (bs::op::checksequenceverify )]
       [(equal? "OP_NOP4" t) (bs::op::nop4 )]
       [(equal? "OP_NOP5" t) (bs::op::nop5 )]
       [(equal? "OP_NOP6" t) (bs::op::nop6 )]
       [(equal? "OP_NOP7" t) (bs::op::nop7 )]
       [(equal? "OP_NOP8" t) (bs::op::nop8 )]
       [(equal? "OP_NOP9" t) (bs::op::nop9 )]
       [(equal? "OP_NOP10" t) (bs::op::nop10 )]
       [(equal? "OP_CHECKSIGADD" t) (bs::op::checksigadd )]

       ; ============================== ;
       ; ======== vacant words ======== ;
       ; ============================== ;
       ; no op code here

       ; ======================================= ;
       ; ======== pomelo symbolic words ======== ;
       ; ======================================= ;
       [(string-prefix? t "OP_SYMINT_") (parse-token/symint t)]
       [(string-prefix? t "OP_SYMBV_") (parse-token/symbv t)]

       ; Handle OP_PUSHNUM_ and OP_PUSHBYTES_
       [(string-prefix? t "OP_PUSHNUM_") (parse-token/pushnum (substring t (string-length "OP_PUSHNUM_")))]
       [(string-prefix? t "OP_PUSHBYTES_") 
        (let ([next (g)])
          (if (string-prefix? next "OP_SYMBV_")
              (bs::op::pushbytes::x (parse-token/symbv next))
              (parse-token/pushbytes (substring t (string-length "OP_PUSHBYTES_")) g)))]
       [(string-prefix? t "OP_") (parse-token/x (substring t (string-length "OP_")))]

       [else (error 'parse-token (format "unsupported token: ~a" t))]
       )
     ]
  ))


; parse string token starting with OP_PUSHBYTES_
(define (parse-token/pushbytes n-str g)
  (define n-bytes (string->number n-str))
  (define n-bits (* 8 n-bytes))
  (define t (g))
  (if (string-prefix? t "OP_SYMBV_")
      (bs::op::pushbytes::x (parse-token/symbv t))
      (begin
        (assert (= (string-length t) (* 2 n-bytes))
                (format "OP_PUSHBYTES_~a: data length mismatch, got: ~a" n-bytes t))
        (assert (<= n-bits ::bvsize)
                (format "OP_PUSHBYTES_~a: does not fit in bv ~a" n-bytes ::bvsize))
        (define bytes (hex-string->bytes t))
        (define bits (apply bv (append (bytes->list bytes) (make-list (- ::bvsize n-bits) 0))))
        (bs::op::pushbytes::x bits))))

; parse string token starting with OP_PUSHNUM_
(define (parse-token/pushnum n-str)
  (define n (string->number n-str))
  (bs::op::pushbits (integer->bitvector n ::bitvector))
  )


; parse string token starting with OP_
(define (parse-token/x ns)
  ; convert to number, it's decimal (weird but true, not hex)
  (define n (string->number ns))
  (assert (integer? n) (format "OP_ argument should be integer, got: ~a" ns))
  (assert (&& (<= 2 n) (<= n 16)) (format "OP_ argument range is invalid, got: ~a" n))
  (bs::op::x n)
  )

; parse string token starting with OP_SYMINT_
(define (parse-token/symint t)
  (let ([ns (substring t 10)])
    ; convert to number, it's decimal
    (define n (string->number ns))
    (assert (integer? n) (format "OP_SYMINT_ argument should be integer, got: ~a" ns))
    (assert (>= n 0) (format "OP_SYMINT_ argument should be non-negative, got: ~a" n))
    (bs::op::symint n)
    )
  )

; parse string token starting with OP_SYMBV_
(define (parse-token/symbv t)
  (define parts (string-split (substring t (string-length "OP_SYMBV_")) "_"))
  (when (not (= (length parts) 2))
    (error 'parse-token/symbv "Invalid OP_SYMBV format. Expected OP_SYMBV_name_size"))
  (define name (string->symbol (first parts)))
  (define size (string->number (second parts)))
  (when (or (not size) (not (integer? size)) (<= size 0))
    (error 'parse-token/symbv "Invalid size for OP_SYMBV. Must be a positive integer"))
  (bs::op::symbv name size))


(define unget-token-stack '())
(define (unget-token! g token)
  (set! unget-token-stack (cons token unget-token-stack)))

(define (make-token-generator old-g)
  (lambda ()
    (if (null? unget-token-stack)
        (old-g)
        (let ([token (car unget-token-stack)])
          (set! unget-token-stack (cdr unget-token-stack))
          token))))

(define (parse-assert-expr g)
  (expect-token! g "(")
  (define result (parse-postfix-expr g))
  (define next-token (g))
  (if (equal? next-token ")")
      (begin
        ;;; (printf "Parsed assert expression: ~a\n" result)
        result)
      (begin
        (unget-token! g next-token)
        ;;; (printf "Parsed assert expression (without closing paren): ~a\n" result)
        result)))

(define (parse-postfix-expr g)
  (define (parse-expr-token token)
    (case token
      [("(") (parse-postfix-expr g)]
      [("eq") 'eq]
      [("ite") 'ite]
      [else (parse-value token)]))

  (define (parse-value token)
    (cond
      [(equal? token "x") (bs::expr::var 'x)]
      [(equal? token "stack-top") (bs::expr::stack-top)]
      [(string->number token) => (bs::expr::bv (string->number token) 32)]
      [else (error 'parse-value "Unknown value: ~a" token)]))

  (define (apply-op op args)
    (case op
      [(eq) (bs::expr::eq (cadr args) (car args))]
      [(ite) (bs::expr::ite (caddr args) (cadr args) (car args))]
      [else (error 'apply-op "Unknown operator: ~a" op)]))

  (let loop ([stack '()] [ops '()])
    (define token (g))
    (cond
      [(equal? token ")") 
       (if (null? ops)
           (if (= (length stack) 1)
               (car stack)
               (error 'parse-postfix-expr "Invalid final state, stack: ~a" stack))
           (error 'parse-postfix-expr "Unused operators remaining: ~a" ops))]
      [(not token)
       (error 'parse-postfix-expr "Unexpected end of input")]
      [else
       (let ([parsed (parse-expr-token token)])
         (cond
           [(or (eq? parsed 'eq) (eq? parsed 'ite))
            (loop stack (cons parsed ops))]
           [else
            (define new-stack (cons parsed stack))
            (define (try-apply-ops s o)
              (if (or (null? o) 
                      (and (eq? (car o) 'eq) (< (length s) 2))
                      (and (eq? (car o) 'ite) (< (length s) 3)))
                  (values s o)
                  (let* ([op (car o)]
                         [arity (if (eq? op 'eq) 2 3)]
                         [args (take s arity)]
                         [rest (drop s arity)]
                         [result (apply-op op args)])
                    (try-apply-ops (cons result rest) (cdr o)))))
            (define-values (new-stack2 new-ops) (try-apply-ops new-stack ops))
            (loop new-stack2 new-ops)]))])))

(define (expect-token! g expected)
  (define token (g))
  (unless (equal? token expected)
    (error 'expect-token! "Expected ~a, got ~a" expected token)))