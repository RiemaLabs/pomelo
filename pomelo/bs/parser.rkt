#lang rosette
(require racket/sequence)
(require racket/generator)
(require racket/string)
(require file/sha1)
(require
  "../utils.rkt"
  "../config.rkt"
  (prefix-in bs:: "./ast.rkt")
  )
(provide (all-defined-out))
(provide parse-assert-expr)


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
       [(string-prefix? t "PUSH_BIGINT_")
        (define n (string->number (substring t (string-length "PUSH_BIGINT_"))))
        (define nbits (string->number (g)))
        (define limb_size (string->number (g)))
        (define limbs_name (g))
        (bs::op::push_bigint nbits limb_size limbs_name n)]

       ; Handle OP_PUSHNUM_ and OP_PUSHBYTES_
       [(string-prefix? t "OP_PUSHNUM_") (parse-token/pushnum (substring t (string-length "OP_PUSHNUM_")))]
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
   (let loop ([content ""] [paren-count 1])
     (define token (g))
     (cond
       [(equal? token "{") (loop (string-append content " " token) (add1 paren-count))]
       [(equal? token "}") 
        (if (= paren-count 1)
            content
            (loop (string-append content " " token) (sub1 paren-count)))]
       [else (loop (string-append content " " token) paren-count)])))
 (let ([expr (parse-assert-expr (string-trim expr-string))])
   (bs::op::assert name expr))]
       [else (error 'parse-token (format "unsupported token: ~a" t))]
       )
     ]
  ))


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
        (define bits #f)
        (for ([byte (in-bytes bytes)])
          (if (not bits)
              (set! bits (bv byte 8))
              (set! bits (concat bits (bv byte 8)))))
        (define bits-padded
          (if (= n-bits ::bvsize)
              bits
              (concat (bv 0 (- ::bvsize n-bits)) bits)))
        (bs::op::pushbits bits-padded))))

        

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
        [(char-whitespace? (string-ref str 0))
         (consume-whitespace (substring str 1))]
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
           [(char=? first-char #\])
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'RBRACKET "]") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "=="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'EQUAL "==") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "<="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'LTE "<=") tokens))]
           [(char=? first-char #\<)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'LT "<") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) ">="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'GTE ">=") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "!="))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'NEQ "!=") tokens))]
           [(char=? first-char #\>)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'GT ">") tokens))]
           [(char=? first-char #\!)
            (tokenize-helper (substring input-trimmed 1) (cons (Token 'NOT "!") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "&&"))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'AND "&&") tokens))]
           [(and (>= (string-length input-trimmed) 2) (string=? (substring input-trimmed 0 2) "||"))
            (tokenize-helper (substring input-trimmed 2) (cons (Token 'OR "||") tokens))]
           [else (error 'tokenize (format "Unexpected character: ~a" first-char))]))]))
  
  (tokenize-helper input-string '()))

; Helper functions for tokenizer
(define (parse-number input)
  (define num-str (list->string (take-while char-numeric? (string->list input))))
  (values (string->number num-str) (substring input (string-length num-str))))

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
  (if (null? tokens)
      (error 'parse-expr "Unexpected end of input")
      (let-values ([(left rest) (parse-and-expr tokens)])
        (if (and (not (null? rest)) (equal? (Token-type (car rest)) 'OR))
            (let-values ([(right new-rest) (parse-expr (cdr rest))])
              (values (bs::expr::or left right) new-rest))
            (values left rest)))))

(define (parse-and-expr tokens)
  (let-values ([(left rest) (parse-comparison tokens)])
    (if (and (not (null? rest)) (equal? (Token-type (car rest)) 'AND))
        (let-values ([(right new-rest) (parse-and-expr (cdr rest))])
          (values (bs::expr::and left right) new-rest))
        (values left rest))))

(define (parse-comparison tokens)
  (let-values ([(left rest) (parse-term tokens)])
    (if (null? rest)
        (values left rest)
        (case (Token-type (car rest))
          [(EQUAL) (let-values ([(right new-rest) (parse-comparison (cdr rest))])
                     (values (bs::expr::eq left right) new-rest))]
          [(LT) (let-values ([(right new-rest) (parse-comparison (cdr rest))])
                  (values (bs::expr::lt left right) new-rest))]
          [(LTE) (let-values ([(right new-rest) (parse-comparison (cdr rest))])
                   (values (bs::expr::lte left right) new-rest))]
          [(GT) (let-values ([(right new-rest) (parse-comparison (cdr rest))])
                  (values (bs::expr::gt left right) new-rest))]
          [(GTE) (let-values ([(right new-rest) (parse-comparison (cdr rest))])
                   (values (bs::expr::gte left right) new-rest))]
          [(NEQ) (let-values ([(right new-rest) (parse-comparison (cdr rest))])
                   (values (bs::expr::neq left right) new-rest))]
          [else (values left rest)]))))

(define (parse-term tokens)
  (if (null? tokens)
      (error 'parse-term "Unexpected end of input")
      (match (car tokens)
        [(Token 'IF _) (parse-if-expr tokens)]
        [(Token 'NOT _) 
         (let-values ([(expr rest) (parse-term (cdr tokens))])
           (values (bs::expr::not expr) rest))]
        [(Token 'IDENTIFIER "stack") (parse-stack-access tokens)]
        [(Token 'IDENTIFIER id) 
         (if (string-prefix? id "v")
             (values (bs::expr::var (string->number (substring id 1))) (cdr tokens))
             (error 'parse-term (format "Unexpected identifier: ~a" id)))]
        [(Token 'NUMBER n) (values (bs::expr::bv n) (cdr tokens))]
        [(Token 'LPAREN _) (parse-parenthesized-expr tokens)]
        [else (error 'parse-term (format "Unexpected token: ~a" (car tokens)))])))

(define (parse-parenthesized-expr tokens)
  (match tokens
    [(list (Token 'LPAREN _) rest ...)
     (if (null? rest)
         (error 'parse-parenthesized-expr "Unexpected end of input after opening parenthesis")
         (let-values ([(expr rest1) (parse-expr rest)])
           (if (null? rest1)
               (error 'parse-parenthesized-expr "Missing closing parenthesis")
               (match rest1
                 [(list (Token 'RPAREN _) rest2 ...)
                  (values expr rest2)]
                 [else (error 'parse-parenthesized-expr "Expected closing parenthesis")]))))]
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
                           (error 'parse-if-expr "Unexpected end of input after 'else' in if expression")
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