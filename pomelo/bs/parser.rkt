#lang rosette
(require racket/sequence)
(require racket/generator)
(require racket/string)
(require file/sha1)
(require "../utils.rkt"
         "../config.rkt"
         (prefix-in bs:: "./ast.rkt"))
(provide (all-defined-out))
(provide parse-assert-expr)

(define (line-generator filename)
  (let ([in-port (open-input-file filename)])
    (in-generator (let loop ()
                    (define line (read-line in-port 'any))
                    (if (eof-object? line)
                        (begin
                          (close-input-port in-port)
                          #f) ; Return #f to signal the end of the file
                        (begin
                          (yield line)
                          (loop)))))))

(define (preprocess-input input-string)
  (define (add-spaces-around-braces str)
    (define (process-char c)
      (case c
        [(#\{) " { "]
        [(#\}) " } "]
        [else (string c)]))
    (string-join (map process-char (string->list str)) ""))

  (add-spaces-around-braces input-string))

; parse bitcoin script from string
; returns: a sequence of bs language constructs
(define (parse-str s)
  (define s1 (preprocess-input s))
  (define tseq (in-list (string-split s1)))
  (parse-tokens tseq))

; parse bitcoin script from file
; returns: a sequence of bs language constructs
(define (parse-file filename)
  (define tseq (line-generator filename))
  (parse-tokens tseq))

; produce a sequence tokens from a sequence of strings
(define/contract (parse-tokens tseq)
  (-> (sequence/c string?) (sequence/c bs::op?))
  (define-values (more? get) (sequence-generate tseq))
  (define token-gen (make-token-generator get))
  (in-generator (let loop ()
                  (when (more?)
                    (yield (parse-token (token-gen) token-gen))
                    (loop)))))

; parse tokens into a branching op
(define/contract (parse-token/branch get not?)
  (-> procedure? boolean? bs::op::branch?)
  ; accumulators for then and else branches
  (define thn '())
  (define els '())
  ; start by assuming we are in the then branch
  (let loop ([in-then? #t])
    (define t (parse-token (get) get))
    (match t
      [(bs::op::endif) (void)]
      ; switch to else branch
      [(bs::op::else) (loop #f)]
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
    [("OP_SOLVE") (bs::op::solve)]
    [else
     (cond

       ; =========================== ;
       ; ======== push data ======== ;
       ; =========================== ;
       ; Push Data (97), opcodes 0x0-0x60
       [(equal? "OP_0" t) (bs::op::0)]
       [(equal? "OP_FALSE" t) (bs::op::false)]
       [(equal? "OP_PUSHDATA1" t) (bs::op::pushdata::x 1)]
       [(equal? "OP_PUSHDATA2" t) (bs::op::pushdata::x 2)]
       [(equal? "OP_PUSHDATA4" t) (bs::op::pushdata::x 4)]
       [(equal? "OP_1NEGATE" t) (bs::op::1negate)]
       [(equal? "OP_RESERVED" t) (bs::op::reserved)]
       [(equal? "OP_1" t) (bs::op::1)]
       [(equal? "OP_TRUE" t) (bs::op::true)]

       ; ============================== ;
       ; ======== control flow ======== ;
       ; ============================== ;
       ; Control Flow (10), opcodes 0x61-0x6a
       [(equal? "OP_NOP" t) (bs::op::nop)]
       [(equal? "OP_VER" t) (bs::op::ver)]
       [(equal? "OP_IF" t) (parse-token/branch g #f)]
       [(equal? "OP_NOTIF" t) (parse-token/branch g #t)]
       [(equal? "OP_VERIF" t) (bs::op::verif)]
       [(equal? "OP_VERNOTIF" t) (bs::op::vernotif)]
       [(equal? "OP_ELSE" t) (bs::op::else)]
       [(equal? "OP_ENDIF" t) (bs::op::endif)]
       [(equal? "OP_VERIFY" t) (bs::op::verify)]
       [(equal? "OP_RETURN" t) (bs::op::return)]

       ; ================================= ;
       ; ======== stack operators ======== ;
       ; ================================= ;
       ; Stack Operation (19), opcodes 0x6a-0x7d
       [(equal? "OP_TOALTSTACK" t) (bs::op::toaltstack)]
       [(equal? "OP_FROMALTSTACK" t) (bs::op::fromaltstack)]
       [(equal? "OP_2DROP" t) (bs::op::2drop)]
       [(equal? "OP_2DUP" t) (bs::op::2dup)]
       [(equal? "OP_3DUP" t) (bs::op::3dup)]
       [(equal? "OP_2OVER" t) (bs::op::2over)]
       [(equal? "OP_2ROT" t) (bs::op::2rot)]
       [(equal? "OP_2SWAP" t) (bs::op::2swap)]
       [(equal? "OP_IFDUP" t) (bs::op::ifdup)]
       [(equal? "OP_DEPTH" t) (bs::op::depth)]
       [(equal? "OP_DROP" t) (bs::op::drop)]
       [(equal? "OP_DUP" t) (bs::op::dup)]
       [(equal? "OP_NIP" t) (bs::op::nip)]
       [(equal? "OP_OVER" t) (bs::op::over)]
       [(equal? "OP_PICK" t) (bs::op::pick)]
       [(equal? "OP_ROLL" t) (bs::op::roll)]
       [(equal? "OP_ROT" t) (bs::op::rot)]
       [(equal? "OP_SWAP" t) (bs::op::swap)]
       [(equal? "OP_TUCK" t) (bs::op::tuck)]

       ; ================================ ;
       ; ======== strings/splice ======== ;
       ; ================================ ;
       ; Strings (5), opcodes 0x7e-0x82
       [(equal? "OP_SIZE" t) (bs::op::size)]
       [(equal? "OP_CAT" t) (bs::op::cat)]

       ; =============================== ;
       ; ======== bitwise logic ======== ;
       ; =============================== ;
       ; Bitwise Logic (8), opcodes 0x83-0x8a
       [(equal? "OP_EQUAL" t) (bs::op::equal)]
       [(equal? "OP_EQUALVERIFY" t) (bs::op::equalverify)]
       [(equal? "OP_RESERVED1" t) (bs::op::reserved1)]
       [(equal? "OP_RESERVED2" t) (bs::op::reserved2)]

       ; ==================================== ;
       ; ======== numeric/arithmetic ======== ;
       ; ==================================== ;
       ; Numeric (27), opcodes 0x8b-0xa5
       [(equal? "OP_1ADD" t) (bs::op::1add)]
       [(equal? "OP_1SUB" t) (bs::op::1sub)]
       [(equal? "OP_NEGATE" t) (bs::op::negate)]
       [(equal? "OP_ABS" t) (bs::op::abs)]
       [(equal? "OP_NOT" t) (bs::op::not)]
       [(equal? "OP_0NOTEQUAL" t) (bs::op::0notequal)]
       [(equal? "OP_ADD" t) (bs::op::add)]
       [(equal? "OP_SUB" t) (bs::op::sub)]
       [(equal? "OP_BOOLAND" t) (bs::op::booland)]
       [(equal? "OP_BOOLOR" t) (bs::op::boolor)]
       [(equal? "OP_NUMEQUAL" t) (bs::op::numequal)]
       [(equal? "OP_NUMEQUALVERIFY" t) (bs::op::numequalverify)]
       [(equal? "OP_NUMNOTEQUAL" t) (bs::op::numnotequal)]
       [(equal? "OP_LESSTHAN" t) (bs::op::lessthan)]
       [(equal? "OP_GREATERTHAN" t) (bs::op::greaterthan)]
       [(equal? "OP_LESSTHANOREQUAL" t) (bs::op::lessthanorequal)]
       [(equal? "OP_GREATERTHANOREQUAL" t) (bs::op::greaterthanorequal)]
       [(equal? "OP_MIN" t) (bs::op::min)]
       [(equal? "OP_MAX" t) (bs::op::max)]
       [(equal? "OP_WITHIN" t) (bs::op::within)]

       ; ============================== ;
       ; ======== cryptography ======== ;
       ; ============================== ;
       ; Cryptography (10), opcodes 0xa6-0xaf
       [(equal? "OP_RIPEMD160" t) (bs::op::ripemd160)]
       [(equal? "OP_SHA1" t) (bs::op::sha1)]
       [(equal? "OP_SHA256" t) (bs::op::sha256)]
       [(equal? "OP_HASH160" t) (bs::op::hash160)]
       [(equal? "OP_HASH256" t) (bs::op::hash256)]
       [(equal? "OP_CODESEPARATOR" t) (bs::op::codeseparator)]
       [(equal? "OP_CHECKSIG" t) (bs::op::checksig)]
       [(equal? "OP_CHECKSIGVERIFY" t) (bs::op::checksigverify)]
       [(equal? "OP_CHECKMULTISIG" t) (bs::op::checkmultisig)]
       [(equal? "OP_CHECKMULTISIGVERIFY" t) (bs::op::checkmultisigverify)]

       ; ================================ ;
       ; ======== locktime/other ======== ;
       ; ================================ ;
       [(equal? "OP_NOP1" t) (bs::op::nop1)]
       [(equal? "OP_CHECKLOCKTIMEVERIFY" t) (bs::op::checklocktimeverify)]
       [(equal? "OP_CHECKSEQUENCEVERIFY" t) (bs::op::checksequenceverify)]
       [(equal? "OP_CHECKSEQUENCEVERIFY" t) (bs::op::checksequenceverify)]
       [(equal? "OP_NOP4" t) (bs::op::nop4)]
       [(equal? "OP_NOP5" t) (bs::op::nop5)]
       [(equal? "OP_NOP6" t) (bs::op::nop6)]
       [(equal? "OP_NOP7" t) (bs::op::nop7)]
       [(equal? "OP_NOP8" t) (bs::op::nop8)]
       [(equal? "OP_NOP9" t) (bs::op::nop9)]
       [(equal? "OP_NOP10" t) (bs::op::nop10)]
       [(equal? "OP_CHECKSIGADD" t) (bs::op::checksigadd)]

       ; ============================== ;
       ; ======== vacant words ======== ;
       ; ============================== ;
       ; no op code here

       ; ======================================= ;
       ; ======== pomelo symbolic words ======== ;
       ; ======================================= ;
       [(equal? "PRINT_SMT" t) (bs::op::printsmt)]
       [(string-prefix? t "PUSH_SYMINT_") (parse-token/symint t)]
       [(string-prefix? t "PUSH_BIGINT_")
        (define n (string->number (substring t (string-length "PUSH_BIGINT_"))))
        (define nbits (string->number (g)))
        (define limb_size (string->number (g)))
        (define limbs_name (g))
        (bs::op::push_bigint nbits limb_size limbs_name n)]

       ; Handle OP_PUSHNUM_ and OP_PUSHBYTES_
       [(string-prefix? t "OP_PUSHNUM_")
        (parse-token/pushnum (substring t (string-length "OP_PUSHNUM_")))]
       [(string-prefix? t "OP_PUSHBYTES_")
        (parse-token/pushbytes (substring t (string-length "OP_PUSHBYTES_")) g)]
       [(string-prefix? t "OP_") (parse-token/x (substring t (string-length "OP_")))]
       [(string-prefix? t "ASSERT")
        (define parts (string-split t "_"))
        (define name
          (if (>= (length parts) 2)
              (string-join (drop parts 1) "_")
              #f))
        (define next-token (g))
        (unless (equal? next-token "{")
          (error 'parse-token "Expected '{' after ASSERT, got: ~a" next-token))
        (define expr-string
          (let loop ([content ""]
                     [paren-count 1])
            (define token (g))
            (cond
              [(equal? token "{") (loop (string-append content " " token) (add1 paren-count))]
              [(equal? token "}")
               (if (= paren-count 1)
                   content
                   (loop (string-append content " " token) (sub1 paren-count)))]
              [else (loop (string-append content " " token) paren-count)])))
        (let ([expr (parse-assert-expr (string-trim expr-string))]) (bs::op::assert name expr))]
       [(string-prefix? t "ASSUME")
        (define parts (string-split t "_"))
        (define name
          (if (>= (length parts) 2)
              (string-join (drop parts 1) "_")
              #f))
        (define next-token (g))
        (unless (equal? next-token "{")
          (error 'parse-token "Expected '{' after ASSUME, got: ~a" next-token))
        (define expr-string
          (let loop ([content ""]
                     [paren-count 1])
            (define token (g))
            (cond
              [(equal? token "{") (loop (string-append content " " token) (add1 paren-count))]
              [(equal? token "}")
               (if (= paren-count 1)
                   content
                   (loop (string-append content " " token) (sub1 paren-count)))]
              [else (loop (string-append content " " token) paren-count)])))
        (let ([expr (parse-assert-expr (string-trim expr-string))]) (bs::op::assume name expr))]
       [(string-prefix? t "EVAL")
        (define parts (string-split t "_"))
        (define name
          (if (>= (length parts) 2)
              (string-join (drop parts 1) "_")
              #f))
        (define next-token (g))
        (unless (equal? next-token "{")
          (error 'parse-token "Expected '{' after ASSUME, got: ~a" next-token))
        (define expr-string
          (let loop ([content ""]
                     [paren-count 1])
            (define token (g))
            (cond
              [(equal? token "{") (loop (string-append content " " token) (add1 paren-count))]
              [(equal? token "}")
               (if (= paren-count 1)
                   content
                   (loop (string-append content " " token) (sub1 paren-count)))]
              [else (loop (string-append content " " token) paren-count)])))
        (let ([expr (parse-assert-expr (string-trim expr-string))]) (bs::op::eval name expr))]
       [(string-prefix? t "DEFINE_")
        (define n (string->number (substring t (string-length "DEFINE_"))))
        (define next-token (g))
        (unless (equal? next-token "{")
          (error 'parse-token "Expected '{' after DEFINE_n, got: ~a" next-token))
        (define expr-string
          (let loop ([content ""]
                     [paren-count 1])
            (define token (g))
            (cond
              [(equal? token "{") (loop (string-append content " " token) (add1 paren-count))]
              [(equal? token "}")
               (if (= paren-count 1)
                   content
                   (loop (string-append content " " token) (sub1 paren-count)))]
              [else (loop (string-append content " " token) paren-count)])))
        (let ([expr (parse-assert-expr (string-trim expr-string))]) (bs::op::define_n n expr))]
       [else (error 'parse-token (format "unsupported token: ~a" t))])]))

; parse string token starting with OP_PUSHBYTES_
(define (parse-token/pushbytes n-str g)
  (define n-bytes (string->number n-str))
  (define n-bits (* 8 n-bytes))
  (define t (g))
  (if (string-prefix? t "OP_SYMINT_")
      (bs::op::pushbytes::x (parse-token/symint t))
      (begin
        (assert (= (string-length t) (* 2 n-bytes))
                (format "OP_PUSHBYTES_~a: data length mismatch, got: ~a" n-bytes t))
        (assert (<= n-bits ::bvsize)
                (format "OP_PUSHBYTES_~a: does not fit in bv ~a" n-bytes ::bvsize))
        (define bytes (hex-string->bytes t))
        (define reversed-bytes-list (reverse-bytes bytes))
        (define bits (apply concat (map (lambda (byte) (bv byte 8)) reversed-bytes-list)))
        (define bits-padded
          (if (= n-bits ::bvsize)
              bits
              (concat (bv 0 (- ::bvsize n-bits)) bits)))
        (bs::op::pushbits bits-padded))))

(define (reverse-bytes bytes)
  (reverse (bytes->list bytes)))

; parse string token starting with OP_PUSHNUM_
(define (parse-token/pushnum n-str)
  (define n (string->number n-str))
  (bs::op::pushbits (integer->bitvector n ::bitvector)))

; parse string token starting with OP_
(define (parse-token/x ns)
  ; convert to number, it's decimal (weird but true, not hex)
  (define n (string->number ns))
  (assert (integer? n) (format "OP_ argument should be integer, got: ~a" ns))
  (assert (&& (<= 2 n) (<= n 16)) (format "OP_ argument range is invalid, got: ~a" n))
  (bs::op::x n))

; parse string token starting with OP_SYMINT_
(define (parse-token/symint t)
  (let ([ns (substring t 12)])
    ; convert to number, it's decimal
    (define n (string->number ns))
    (assert (integer? n) (format "PUSH_SYMINT_ argument should be integer, got: ~a" ns))
    (assert (>= n 0) (format "PUSH_SYMINT_ argument should be non-negative, got: ~a" n))
    (bs::op::symint n)))

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

;;; Parse logical expr

; Token structure
(struct Token (type value) #:transparent)

; Tokenizer function for expressions
(define (tokenize-expr input-string)
  (define (tokenize-helper input tokens)
    (define (consume-whitespace str)
      (cond
        [(equal? str "") str]
        [(char-whitespace? (string-ref str 0)) (consume-whitespace (substring str 1))]
        [else str]))

    (define input-trimmed (consume-whitespace input))

    (cond
      [(equal? input-trimmed "") (reverse tokens)]
      [else
       (let ([first-char (string-ref input-trimmed 0)])
         (cond
           [(char-numeric? first-char)
            (define-values (num rest) (parse-number input-trimmed))
            (tokenize-helper rest (cons (Token 'NUMBER num) tokens))]
           [(char-alphabetic? first-char)
            (define-values (id rest) (parse-identifier input-trimmed))
            (tokenize-helper rest
                             (cons (cond
                                     [(equal? id "if") (Token 'IF "if")]
                                     [(equal? id "then") (Token 'THEN "then")]
                                     [(equal? id "else") (Token 'ELSE "else")]
                                     [else (Token 'IDENTIFIER id)])
                                   tokens))]
           [(char=? first-char #\()
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'LPAREN "(") tokens))]
           [(char=? first-char #\))
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'RPAREN ")") tokens))]
           [(char=? first-char #\,)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'COMMA ",") tokens))]
           [(char=? first-char #\[)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'LBRACKET "[") tokens))]
           [(char=? first-char #\.)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'DOT ".") tokens))]
           [(char=? first-char #\])
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'RBRACKET "]") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "=="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'EQUAL "==") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "<="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'LTE "<=") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) ">="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'GTE ">=") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "!="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'NEQ "!=") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) ">>"))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'SHR ">>") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "<<"))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'SHL "<<") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "++"))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'CONCAT "++") tokens))]
           [(char=? first-char #\>)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'GT ">") tokens))]
           [(char=? first-char #\<)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'LT "<") tokens))]
           [(char=? first-char #\!)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'NOT "!") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "&&"))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'AND "&&") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "||"))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'OR "||") tokens))]
           [(char=? first-char #\+)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'ADD "+") tokens))]
           [(char=? first-char #\-)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'SUB "-") tokens))]
           [(char=? first-char #\*)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'MUL "*") tokens))]
           [(char=? first-char #\/)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'DIV "/") tokens))]
           [(char=? first-char #\%)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'MOD "%") tokens))]
           [else (error 'tokenize (format "Unexpected character: ~a" first-char))]))]))

  (tokenize-helper input-string '()))

; Helper functions for tokenizer
(define (parse-number input)
  (cond
    [(string-prefix? input "0x")
     (define hex-str (list->string (take-while char-hex? (string->list (substring input 2)))))
     (values (string->number (string-append "#x" hex-str))
             (substring input (+ 2 (string-length hex-str))))]
    [else
     (define num-str (list->string (take-while char-numeric? (string->list input))))
     (values (string->number num-str) (substring input (string-length num-str)))]))

(define (char-hex? c)
  (or (char-numeric? c) (and (char-alphabetic? c) (or (char<=? #\a c #\f) (char<=? #\A c #\F)))))

(define (parse-identifier input)
  (define id-str (list->string (take-while char-identifier? (string->list input))))
  (values id-str (substring input (string-length id-str))))

(define (char-identifier? c)
  (or (char-alphabetic? c) (char-numeric? c) (equal? c #\_)))

(define (take-while pred lst)
  (if (and (not (null? lst)) (pred (car lst)))
      (cons (car lst) (take-while pred (cdr lst)))
      '()))

; Expr parser
(define (parse-expr tokens)
  (parse-comparison tokens))

(define (parse-comparison tokens)
  (let-values ([(left rest) (parse-logical-or tokens)])
    (if (null? rest)
        (values left rest)
        (case (Token-type (car rest))
          [(EQUAL)
           (let-values ([(right new-rest) (parse-logical-or (cdr rest))])
             (values (bs::expr::eq left right) new-rest))]
          [(LT)
           (let-values ([(right new-rest) (parse-logical-or (cdr rest))])
             (values (bs::expr::lt left right) new-rest))]
          [(LTE)
           (let-values ([(right new-rest) (parse-logical-or (cdr rest))])
             (values (bs::expr::lte left right) new-rest))]
          [(GT)
           (let-values ([(right new-rest) (parse-logical-or (cdr rest))])
             (values (bs::expr::gt left right) new-rest))]
          [(GTE)
           (let-values ([(right new-rest) (parse-logical-or (cdr rest))])
             (values (bs::expr::gte left right) new-rest))]
          [(NEQ)
           (let-values ([(right new-rest) (parse-logical-or (cdr rest))])
             (values (bs::expr::neq left right) new-rest))]
          [else (values left rest)]))))

(define (parse-logical-or tokens)
  (let-values ([(left rest) (parse-logical-and tokens)])
    (parse-logical-or-tail left rest)))

(define (parse-logical-or-tail left tokens)
  (if (null? tokens)
      (values left tokens)
      (case (Token-type (car tokens))
        [(OR)
         (let-values ([(right new-rest) (parse-logical-and (cdr tokens))])
           (parse-logical-or-tail (bs::expr::or left right) new-rest))]
        [else (values left tokens)])))

(define (parse-logical-and tokens)
  (let-values ([(left rest) (parse-additive tokens)])
    (parse-logical-and-tail left rest)))

(define (parse-logical-and-tail left tokens)
  (if (null? tokens)
      (values left tokens)
      (case (Token-type (car tokens))
        [(AND)
         (let-values ([(right new-rest) (parse-additive (cdr tokens))])
           (parse-logical-and-tail (bs::expr::and left right) new-rest))]
        [else (values left tokens)])))

(define (parse-additive tokens)
  (let-values ([(left rest) (parse-multiplicative tokens)])
    (parse-additive-tail left rest)))

(define (parse-additive-tail left tokens)
  (if (null? tokens)
      (values left tokens)
      (case (Token-type (car tokens))
        [(ADD)
         (let-values ([(right new-rest) (parse-multiplicative (cdr tokens))])
           (parse-additive-tail (bs::expr::add left right) new-rest))]
        [(SUB)
         (let-values ([(right new-rest) (parse-multiplicative (cdr tokens))])
           (parse-additive-tail (bs::expr::sub left right) new-rest))]
        [else (values left tokens)])))

(define (parse-multiplicative tokens)
  (let-values ([(left rest) (parse-unary tokens)])
    (parse-multiplicative-tail left rest)))

(define (parse-multiplicative-tail left tokens)
  (if (null? tokens)
      (values left tokens)
      (case (Token-type (car tokens))
        [(MUL)
         (let-values ([(right new-rest) (parse-unary (cdr tokens))])
           (parse-multiplicative-tail (bs::expr::mul left right) new-rest))]
        [(DIV)
         (let-values ([(right new-rest) (parse-unary (cdr tokens))])
           (parse-multiplicative-tail (bs::expr::div left right) new-rest))]
        [(MOD)
         (let-values ([(right new-rest) (parse-unary (cdr tokens))])
           (parse-multiplicative-tail (bs::expr::mod left right) new-rest))]
        [(SHR)
         (let-values ([(right new-rest) (parse-unary (cdr tokens))])
           (parse-multiplicative-tail (bs::expr::shr left right) new-rest))]
        [(SHL)
         (let-values ([(right new-rest) (parse-unary (cdr tokens))])
           (parse-multiplicative-tail (bs::expr::shl left right) new-rest))]
        [(CONCAT)
         (let-values ([(right new-rest) (parse-unary (cdr tokens))])
           (parse-multiplicative-tail (bs::expr::concat left right) new-rest))]
        [else (values left tokens)])))

(define (parse-unary tokens)
  (if (null? tokens)
      (error 'parse-unary "Unexpected end of input")
      (case (Token-type (car tokens))
        [(NOT)
         (let-values ([(expr rest) (parse-unary (cdr tokens))])
           (values (bs::expr::not expr) rest))]
        [else (parse-term tokens)])))

(define (parse-term tokens)
  (if (null? tokens)
      (error 'parse-term "Unexpected end of input")
      (match (car tokens)
        [(Token 'IF _) (parse-if-expr tokens)]
        [(Token 'IDENTIFIER "stack") (parse-stack-access tokens)]
        [(Token 'IDENTIFIER "altstack") (parse-altstack-access tokens)]
        [(Token 'IDENTIFIER id) (parse-var-access id tokens)]
        [(Token 'NUMBER n) (values (bs::expr::bv n) (cdr tokens))]
        [(Token 'LPAREN _) (parse-parenthesized-expr tokens)]
        [else (error 'parse-term (format "Unexpected token: ~a" (car tokens)))])))

(define (parse-parenthesized-expr tokens)
  (match tokens
    [(list (Token 'LPAREN _) rest ...)
     (if (null? rest)
         (error 'parse-parenthesized-expr "Unexpected end of input after opening parenthesis")
         (let loop ([expr-tokens rest]
                    [paren-count 1])
           (if (null? expr-tokens)
               (error 'parse-parenthesized-expr "Missing closing parenthesis")
               (match (car expr-tokens)
                 [(Token 'LPAREN _) (loop (cdr expr-tokens) (add1 paren-count))]
                 [(Token 'RPAREN _)
                  (if (= paren-count 1)
                      (let-values ([(expr _) (parse-expr rest)])
                        (values expr (cdr expr-tokens)))
                      (loop (cdr expr-tokens) (sub1 paren-count)))]
                 [_ (loop (cdr expr-tokens) paren-count)]))))]
    [else (error 'parse-parenthesized-expr "Expected opening parenthesis")]))

(define (parse-if-expr tokens)
  (match tokens
    [(list (Token 'IF _) rest ...)
     (if (null? rest)
         (error 'parse-if-expr "Unexpected end of input in if expression")
         (let-values ([(condition rest1) (parse-expr rest)])
           (match rest1
             [(list (Token 'THEN _) rest2 ...)
              (if (null? rest2)
                  (error 'parse-if-expr "Unexpected end of input after 'then' in if expression")
                  (let-values ([(then-expr rest3) (parse-expr rest2)])
                    (match rest3
                      [(list (Token 'ELSE _) rest4 ...)
                       (if (null? rest4)
                           (error 'parse-if-expr
                                  "Unexpected end of input after 'else' in if expression")
                           (let-values ([(else-expr rest5) (parse-expr rest4)])
                             (values (bs::expr::ite condition then-expr else-expr) rest5)))]
                      [else (error 'parse-if-expr "Expected 'else' in if expression")])))]
             [else (error 'parse-if-expr "Expected 'then' after condition in if expression")])))]
    [else (error 'parse-if-expr "Invalid if expression syntax")]))

(define (parse-stack-access tokens)
  (match tokens
    [(list (Token 'IDENTIFIER "stack") (Token 'LBRACKET _) rest ...)
     (if (null? rest)
         (error 'parse-stack-access "Unexpected end of input after opening bracket")
         (match rest
           [(list (Token 'NUMBER n) (Token 'RBRACKET _) rest2 ...)
            (values (bs::expr::stack-nth n) rest2)]
           [_ (error 'parse-stack-access "Invalid stack access syntax")]))]
    [_ (error 'parse-stack-access "Invalid stack access syntax")]))

(define (parse-altstack-access tokens)
  (match tokens
    [(list (Token 'IDENTIFIER "altstack") (Token 'LBRACKET _) rest ...)
     (if (null? rest)
         (error 'parse-altstack-access "Unexpected end of input after opening bracket")
         (match rest
           [(list (Token 'NUMBER n) (Token 'RBRACKET _) rest2 ...)
            (values (bs::expr::altstack-nth n) rest2)]
           [_ (error 'parse-altstack-access "Invalid altstack access syntax")]))]
    [_ (error 'parse-altstack-access "Invalid altstack access syntax")]))

(define (parse-var-access id tokens)
  (match tokens
    [(list (Token 'IDENTIFIER _) (Token 'LBRACKET _) rest ...)
     (if (null? rest)
         (error 'parse-var-access "Unexpected end of input after opening bracket")
         (match rest
           [(list (Token 'NUMBER n) (Token 'RBRACKET _) rest2 ...)
            (parse-var-access-dot (format "~a[~a]" id n) rest2)]
           [_ (error 'parse-var-access "Invalid var access syntax")]))]
    [(list (Token 'IDENTIFIER _) rest ...) (values (bs::expr::var id) rest)]
    [_ (error 'parse-limbs-access "Invalid var access syntax")]))

(define (parse-var-access-dot id tokens)
  (match tokens
    [(list (Token 'DOT _) (Token 'LPAREN _) rest ...)
     (if (null? rest)
         (error 'parse-var-access "Unexpected end of input after opening parenthesis")
         (match rest
           [(list (Token 'NUMBER n) (Token 'RPAREN _) rest2 ...)
            (values (bs::expr::bit-at (bs::expr::var id) (bs::expr::nat n)) rest2)]
           [_ (error 'parse-var-access "Expected number and closing parenthesis for bit access")]))]
    [_ (values (bs::expr::var id) tokens)]))

; Main parser for assert expressions
(define (parse-assert-expr expr-string)
  (define tokens (tokenize-expr expr-string))
  ;;; (printf "Tokens: ~a\n" tokens)
  (if (null? tokens)
      (error 'parse-assert-expr "Empty expression")
      (let-values ([(result rest) (parse-expr tokens)])
        (if (null? rest)
            result
            (error 'parse-assert-expr (format "Unexpected tokens: ~a" rest))))))

(define (expect-token! g expected)
  (define token (g))
  (unless (equal? token expected)
    (error 'expect-token! "Expected ~a, got ~a" expected token)))
