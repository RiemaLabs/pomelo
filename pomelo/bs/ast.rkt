#lang rosette
(provide (all-defined-out))

; bitcoin script grammar
;  - ref: https://learnmeabitcoin.com/technical/script/
;  - ref: https://en.bitcoin.it/wiki/Script
;  - slightly packed opcodes for bitcoin script, with symbolic opcodes
;  - original bitcoin script postfix form, e.g., even with op::if, it doesn't take arguments
;  - TODO: we will have infix/prefix form added later

; ======================================= ;
; ======== data types/structures ======== ;
; ======================================= ;

; see: https://en.bitcoin.it/wiki/BIP_0137
(struct prvkey (x) #:mutable #:transparent #:reflection-name 'prvkey)
(struct pubkey (pfx x) #:mutable #:transparent #:reflection-name 'pubkey)

; =========================== ;
; ======== push data ======== ;
; =========================== ;

; opcode 0 (0x00)
; op::0 and op::false share the same opcode
(struct op::0 () #:mutable #:transparent #:reflection-name 'OP_0)
(struct op::false () #:mutable #:transparent #:reflection-name 'OP_FALSE)

; opcodes 1-75 (0x01-0x4b) | x: 1-75
(struct op::pushbytes::x (x) #:mutable #:transparent #:reflection-name 'OP_PUSHBYTES_X)

; opcodes 76/77/78 (0x4c/0x4d/0x4e) | x: 1/2/4
; yes OP_PUSHDATAX is the word, no underscore
(struct op::pushdata::x (x) #:mutable #:transparent #:reflection-name 'OP_PUSHDATAX)

; opcode 79 (0x4f)
(struct op::1negate () #:mutable #:transparent #:reflection-name 'OP_1NEGATE)

; opcode 80 (0x50)
(struct op::reserved () #:mutable #:transparent #:reflection-name 'OP_RESERVED)

; opcode 81 (0x51)
; op::1 and op::true share the same opcode
(struct op::1 () #:mutable #:transparent #:reflection-name 'OP_1)
(struct op::true () #:mutable #:transparent #:reflection-name 'OP_TRUE)

; opcodes 82-96 (0x52-0x60) | x: 2-16
(struct op::x (x) #:mutable #:transparent #:reflection-name 'OP_X)

; ============================== ;
; ======== control flow ======== ;
; ============================== ;

; opcode 97 (0x61)
(struct op::nop () #:mutable #:transparent #:reflection-name 'OP_NOP)

; opcode 98 (0x62)
(struct op::ver () #:mutable #:transparent #:reflection-name 'OP_VER)

; opcode 99 (0x63)
(struct op::if () #:mutable #:transparent #:reflection-name 'OP_IF)

; opcode 100 (0x64)
(struct op::notif () #:mutable #:transparent #:reflection-name 'OP_NOTIF)

; opcode 101 (0x65)
(struct op::verif () #:mutable #:transparent #:reflection-name 'OP_VERIF)

; opcode 102 (0x66)
(struct op::vernotif () #:mutable #:transparent #:reflection-name 'OP_VERNOTIF)

; opcode 103 (0x67)
(struct op::else () #:mutable #:transparent #:reflection-name 'OP_ELSE)

; opcode 104 (0x68)
(struct op::endif () #:mutable #:transparent #:reflection-name 'OP_ENDIF)

; opcode 105 (0x69)
(struct op::verify () #:mutable #:transparent #:reflection-name 'OP_VERIFY)

; opcode 106 (0x6a)
(struct op::return () #:mutable #:transparent #:reflection-name 'OP_RETURN)

; ================================= ;
; ======== stack operators ======== ;
; ================================= ;

; opcode 107 (0x6b)
(struct op::toaltstack () #:mutable #:transparent #:reflection-name 'OP_TOALTSTACK)

; opcode 108 (0x6c)
(struct op::fromaltstack () #:mutable #:transparent #:reflection-name 'OP_FROMALTSTACK)

; opcode 109 (0x6d)
(struct op::2drop () #:mutable #:transparent #:reflection-name 'OP_2DROP)

; opcode 110 (0x6e)
(struct op::2dup () #:mutable #:transparent #:reflection-name 'OP_2DUP)

; opcode 111 (0x6f)
(struct op::3dup () #:mutable #:transparent #:reflection-name 'OP_3DUP)

; opcode 112 (0x70)
(struct op::2over () #:mutable #:transparent #:reflection-name 'OP_2OVER)

; opcode 113 (0x71)
(struct op::2rot () #:mutable #:transparent #:reflection-name 'OP_2ROT)

; opcode 114 (0x72)
(struct op::2swap () #:mutable #:transparent #:reflection-name 'OP_2SWAP)

; opcode 115 (0x73)
(struct op::ifdup () #:mutable #:transparent #:reflection-name 'OP_IFDUP)

; opcode 116 (0x74)
(struct op::depth () #:mutable #:transparent #:reflection-name 'OP_DEPTH)

; opcode 117 (0x75)
(struct op::drop () #:mutable #:transparent #:reflection-name 'OP_DROP)

; opcode 118 (0x76)
(struct op::dup () #:mutable #:transparent #:reflection-name 'OP_DUP)

; opcode 119 (0x77)
(struct op::nip () #:mutable #:transparent #:reflection-name 'OP_NIP)

; opcode 120 (0x78)
(struct op::over () #:mutable #:transparent #:reflection-name 'OP_OVER)

; opcode 121 (0x79)
(struct op::pick () #:mutable #:transparent #:reflection-name 'OP_PICK)

; opcode 122 (0x7a)
(struct op::roll () #:mutable #:transparent #:reflection-name 'OP_ROLL)

; opcode 123 (0x7b)
(struct op::rot () #:mutable #:transparent #:reflection-name 'OP_ROT)

; opcode 124 (0x7c)
(struct op::swap () #:mutable #:transparent #:reflection-name 'OP_SWAP)

; opcode 125 (0x7d)
(struct op::tuck () #:mutable #:transparent #:reflection-name 'OP_TUCK)

; ================================ ;
; ======== strings/splice ======== ;
; ================================ ;

; opcode 126 (0x7e)
(struct op::cat () #:mutable #:transparent #:reflection-name 'OP_CAT)

; opcode 127 (0x7f)
(struct op::substr () #:mutable #:transparent #:reflection-name 'OP_SUBSTR)

; opcode 128 (0x80)
(struct op::left () #:mutable #:transparent #:reflection-name 'OP_LEFT)

; opcode 129 (0x81)
(struct op::right () #:mutable #:transparent #:reflection-name 'OP_RIGHT)

; opcode 130 (0x82)
(struct op::size () #:mutable #:transparent #:reflection-name 'OP_SIZE)

; =============================== ;
; ======== bitwise logic ======== ;
; =============================== ;

; opcode 131 (0x83)
(struct op::invert () #:mutable #:transparent #:reflection-name 'OP_INVERT)

; opcode 132 (0x84)
(struct op::and () #:mutable #:transparent #:reflection-name 'OP_AND)

; opcode 133 (0x85)
(struct op::or () #:mutable #:transparent #:reflection-name 'OP_OR)

; opcode 134 (0x86)
(struct op::xor () #:mutable #:transparent #:reflection-name 'OP_XOR)

; opcode 135 (0x87)
(struct op::equal () #:mutable #:transparent #:reflection-name 'OP_EQUAL)

; opcode 136 (0x88)
(struct op::equalverify () #:mutable #:transparent #:reflection-name 'OP_EQUALVERIFY)

; opcode 137 (0x89)
(struct op::reserved1 () #:mutable #:transparent #:reflection-name 'OP_RESERVED1)

; opcode 138 (0x8a)
(struct op::reserved2 () #:mutable #:transparent #:reflection-name 'OP_RESERVED2)

; ==================================== ;
; ======== numeric/arithmetic ======== ;
; ==================================== ;

; opcode 139 (0x8b)
(struct op::1add () #:mutable #:transparent #:reflection-name 'OP_1ADD)

; opcode 140 (0x8c)
(struct op::1sub () #:mutable #:transparent #:reflection-name 'OP_1SUB)

; opcode 141 (0x8d)
(struct op::2mul () #:mutable #:transparent #:reflection-name 'OP_2MUL)

; opcode 142 (0x8e)
(struct op::2div () #:mutable #:transparent #:reflection-name 'OP_2DIV)

; opcode 143 (0x8f)
(struct op::negate () #:mutable #:transparent #:reflection-name 'OP_NEGATE)

; opcode 144 (0x90)
(struct op::abs () #:mutable #:transparent #:reflection-name 'OP_ABS)

; opcode 145 (0x91)
(struct op::not () #:mutable #:transparent #:reflection-name 'OP_NOT)

; opcode 146 (0x92)
(struct op::0notequal () #:mutable #:transparent #:reflection-name 'OP_0NOTEQUAL)

; opcode 147 (0x93)
(struct op::add () #:mutable #:transparent #:reflection-name 'OP_ADD)

; opcode 148 (0x94)
(struct op::sub () #:mutable #:transparent #:reflection-name 'OP_SUB)

; opcode 149 (0x95)
(struct op::mul () #:mutable #:transparent #:reflection-name 'OP_MUL)

; opcode 150 (0x96)
(struct op::div () #:mutable #:transparent #:reflection-name 'OP_DIV)

; opcode 151 (0x97)
(struct op::mod () #:mutable #:transparent #:reflection-name 'OP_MOD)

; opcode 152 (0x98)
(struct op::lshift () #:mutable #:transparent #:reflection-name 'OP_LSHIFT)

; opcode 153 (0x99)
(struct op::rshift () #:mutable #:transparent #:reflection-name 'OP_RSHIFT)

; opcode 154 (0x9a)
(struct op::booland () #:mutable #:transparent #:reflection-name 'OP_BOOLAND)

; opcode 155 (0x9b)
(struct op::boolor () #:mutable #:transparent #:reflection-name 'OP_BOOLOR)

; opcode 156 (0x9c)
(struct op::numequal () #:mutable #:transparent #:reflection-name 'OP_NUMEQUAL)

; opcode 157 (0x9d)
(struct op::numequalverify () #:mutable #:transparent #:reflection-name 'OP_NUMEQUALVERIFY)

; opcode 158 (0x9e)
(struct op::numnotequal () #:mutable #:transparent #:reflection-name 'OP_NUMNOTEQUAL)

; opcode 159 (0x9f)
(struct op::lessthan () #:mutable #:transparent #:reflection-name 'OP_LESSTHAN)

; opcode 160 (0xa0)
(struct op::greaterthan () #:mutable #:transparent #:reflection-name 'OP_GREATERTHAN)

; opcode 161 (0xa1)
(struct op::lessthanorequal () #:mutable #:transparent #:reflection-name 'OP_LESSTHANOREQUAL)

; opcode 162 (0xa2)
(struct op::greaterthanorequal () #:mutable #:transparent #:reflection-name 'OP_GREATERTHANOREQUAL)

; opcode 163 (0xa3)
(struct op::min () #:mutable #:transparent #:reflection-name 'OP_MIN)

; opcode 164 (0xa4)
(struct op::max () #:mutable #:transparent #:reflection-name 'OP_MAX)

; opcode 165 (0xa5)
(struct op::within () #:mutable #:transparent #:reflection-name 'OP_WITHIN)

; ============================== ;
; ======== cryptography ======== ;
; ============================== ;

; opcode 166 (0xa6)
(struct op::ripemd160 () #:mutable #:transparent #:reflection-name 'OP_RIPEMD160)

; opcode 167 (0xa7)
(struct op::sha1 () #:mutable #:transparent #:reflection-name 'OP_SHA1)

; opcode 168 (0xa8)
(struct op::sha256 () #:mutable #:transparent #:reflection-name 'OP_SHA256)

; opcode 169 (0xa9)
(struct op::hash160 () #:mutable #:transparent #:reflection-name 'OP_HASH160)

; opcode 170 (0xaa)
(struct op::hash256 () #:mutable #:transparent #:reflection-name 'OP_HASH256)

; opcode 171 (0xab)
(struct op::codeseparator () #:mutable #:transparent #:reflection-name 'OP_CODESEPARATOR)

; opcode 172 (0xac)
(struct op::checksig () #:mutable #:transparent #:reflection-name 'OP_CHECKSIG)

; opcode 173 (0xad)
(struct op::checksigverify () #:mutable #:transparent #:reflection-name 'OP_CHECKSIGVERIFY)

; opcode 174 (0xae)
(struct op::checkmultisig () #:mutable #:transparent #:reflection-name 'OP_CHECKMULTISIG)

; opcode 175 (0xaf)
(struct op::checkmultisigverify () #:mutable #:transparent #:reflection-name 'OP_CHECKMULTISIGVERIFY)

; ================================ ;
; ======== locktime/other ======== ;
; ================================ ;

; opcode 176 (0xb0)
(struct op::nop1 () #:mutable #:transparent #:reflection-name 'OP_NOP1)

; opcode 177 (0xb1)
; previously OP_NOP2
(struct op::checklocktimeverify () #:mutable #:transparent #:reflection-name 'OP_CHECKLOCKTIMEVERIFY)

; opcode 178 (0xb2)
; previously OP_NOP3
(struct op::checksequenceverify () #:mutable #:transparent #:reflection-name 'OP_CHECKSEQUENCEVERIFY)

; opcode 179 (0xb3)
(struct op::nop4 () #:mutable #:transparent #:reflection-name 'OP_NOP4)

; opcode 180 (0xb4)
(struct op::nop5 () #:mutable #:transparent #:reflection-name 'OP_NOP5)

; opcode 181 (0xb5)
(struct op::nop6 () #:mutable #:transparent #:reflection-name 'OP_NOP6)

; opcode 182 (0xb6)
(struct op::nop7 () #:mutable #:transparent #:reflection-name 'OP_NOP7)

; opcode 183 (0xb7)
(struct op::nop8 () #:mutable #:transparent #:reflection-name 'OP_NOP8)

; opcode 184 (0xb8)
(struct op::nop9 () #:mutable #:transparent #:reflection-name 'OP_NOP9)

; opcode 185 (0xb9)
(struct op::nop10 () #:mutable #:transparent #:reflection-name 'OP_NOP10)

; opcode 186 (0xba)
(struct op::checksigadd () #:mutable #:transparent #:reflection-name 'OP_CHECKSIGADD)

; ============================== ;
; ======== vacant words ======== ;
; ============================== ;

; opcode 187 (0xbb)
; opcode 188 (0xbc)
; ...

; ======================================= ;
; ======== pomela symbolic words ======== ;
; ======================================= ;

; opcode 240 (0xf0) | x: non-negative integer
; x is the name of the symbolic int
(struct op::symint (x) #:mutable #:transparent #:reflection-name 'OP_SYMINT)

; opcode 241 (0xf1) | x: non-negative integer
; x is the name of the symbolic bool
(struct op::symbool (x) #:mutable #:transparent #:reflection-name 'OP_SYMBOOL)

; opcode 242 (0xf2)
(struct op::assert () #:mutable #:transparent #:reflection-name 'OP_ASSERT)

; opcode 243 (0xf3)
(struct op::solve () #:mutable #:transparent #:reflection-name 'OP_SOLVE)

; ======================================= ;
; ============ custom opcodes =========== ;
; ======================================= ;
(struct op::branch (then else) #:mutable #:transparent #:reflection-name 'OP_BRANCH)