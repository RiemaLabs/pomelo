<div align="left"> <h1> <img src="./resources/pomelo.png" width="50"> Pomelo: A Symbolic Reasoning Toolkit for Bitcoin Script </h1> </div>
Pomelo is a comprehensive symbolic reasoning toolkit designed for Bitcoin Script. It simplifies the formal verification of Bitcoin scripts by enabling the use of symbolic variables and assertions to specify and verify functional correctness automatically.

Introduction
Bitcoin Script is a stack-based language used to define conditions for spending Bitcoin. While powerful, ensuring the correctness of these scripts under all scenarios is critical for secure transactions.

Pomelo addresses this challenge by introducing a symbolic reasoning framework. With its extended syntax and semantics, developers can verify Bitcoin scripts against formal specifications efficiently and reliably.

Dependencies
To use Pomelo, ensure the following dependencies are installed:

1. Racket (Version 8.0 or higher)
Download: https://racket-lang.org/
2. Rosette (Version 4.0 or higher)
Install:
bash
raco pkg install --auto rosette
Repository: https://github.com/emina/rosette
3. Bitwuzla (Version 0.6.0 or higher)
Install:
Download the source code from Bitwuzla Repository.
Compile and run it.
Add the bitwuzla binary to your system’s environment PATH.
Using Pomelo
Running Bitcoin Script Verification
Run a Bitcoin Script for symbolic reasoning with the following command:

bash
racket ./run.rkt --file <path-to-file> --debug --solver bitwuzla
Default Solver: Z3 (can be switched to Bitwuzla with --solver bitwuzla).
Debugging: The --debug flag outputs detailed stack transitions for easier debugging during verification failures.
Input Format: Scripts should include Pomelo's extended syntax, compatible with Bitcoin Script.
Syntax and Semantics
Pomelo extends Bitcoin Script with new syntactic constructs for symbolic reasoning:

PUSH_BIGINT_{i} {n_bits} {limb_size} limbs{i}
Pushes a large integer onto the stack using little-endian encoding.

Symbolic Variable: $v_i represents the value.
Formula:
𝑣
𝑖
=
𝑙
𝑖
𝑚
𝑏
𝑠
[
𝑖
]
[
0
]
+
𝑙
𝑖
𝑚
𝑏
𝑠
[
𝑖
]
[
1
]
∗
(
1
<
<
𝑙
𝑖
𝑚
𝑏
𝑠
𝑖
𝑧
𝑒
)
+
.
.
.
v 
i
​
 =limbs[i][0]+limbs[i][1]∗(1<<limb 
s
​
 ize)+...
PUSH_SYMINT_{i}
Pushes a symbolic integer onto the stack.

DEFINE_{id} {expr}
Defines intermediate variables as $i_{id} = expr.

Assume_{index} {expr}
Adds $index-th hypothesis to the SMT solver.

Assert_{index} {expr}
Validates that expr holds under provided assumptions.

Additional Syntax
Stack Access

stack[i]: Access the $i$-th stack element.
altstack[i]: Access the $i$-th altstack element.
Bit Manipulation

limbs[i][j].(k): Access the $k$-th bit of the $j$-th limb.
Operators

Logical: &&, ||, <=, >=, <, >, ==, !=.
Arithmetic: +, -, *, /, %, <<, >>.
Conditional Expressions

If bool_expr then value_expr1 else value_expr2.
Examples
Explore the ./benchmark directory for examples, including automated specifications for public functions from BitVM.

Acknowledgment
This project is supported by research grants from StarkWare and Fractal Bitcoin. We are deeply grateful for their contributions, which made this work possible.
