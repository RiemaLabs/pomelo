<div align="left">
  <h1>
    <img src="./resources/pomelo.png" width=50>
  	Pomelo: A Symbolic Reasoning Toolkit for Bitcoin Script
  </h1>
</div>

Pomelo is a symbolic reasoning toolkit designed for Bitcoin Script, aimed at simplifying the formal verification of Bitcoin scripts and their functional correctness. At the core of Pomelo is the ability to use symbolic variables and assertions to specify and verify the correctness of scripts automatically.

## Introduction

Pomelo is a symbolic reasoning toolkit designed to simplify the formal verification of Bitcoin scripts and their functional correctness. By using symbolic variables and assertions, Pomelo allows developers to specify and verify the correctness of scripts automatically.

Before diving into Pomelo's usage, it's important to understand the context in which it operates. **Bitcoin Script** is a stack-based programming language used to control the spending conditions of Bitcoins. It enables the creation of complex transaction scripts that define how funds can be moved. Ensuring these scripts function correctly under all possible scenarios is crucial for the security and reliability of Bitcoin transactions.

## Dependencies

To use Pomelo, you'll need the following dependencies:

- **Racket (Version 8.0 or higher)**: A programming language suitable for symbolic computation.
  - Download: [https://racket-lang.org/](https://racket-lang.org/)
- **Rosette (Version 4.0 or higher)**: A toolkit for building program verifiers and synthesizers.
  - Installation:
    ```bash
    raco pkg install --auto rosette
    ```
  - Repository: [https://github.com/emina/rosette](https://github.com/emina/rosette)
- **Bitwuzla (Version 0.6.0 or higher)**: An SMT Solver for the theories of fixed-size bit-vectors
  - **Installation**: Download the source code from the [Bitwuzla Repository](https://github.com/bitwuzla/bitwuzla), then compile and run it. After installation, ensure that the `bitwuzla` binary is added to your system’s environment PATH for easy access.

## Using Pomelo

### Running a Bitcoin Script for Verification

To execute a Bitcoin Script with symbolic variables, use the `run.rkt` script:

```bash
racket ./run.rkt --file <path-to-file> --debug --solver bitwuzla
```

- By default, the SMT backend solver employed is Z3; however, users may opt to utilize Bitwuzla by specifying the `--solver bitwuzla` flag. 
- The `--debug` option facilitates the output of comprehensive stack state transitions at each execution step, thereby enhancing the debugging process, especially in instances where assertion verifications fail. 
- The input file is expected to contain Bitcoin Script code augmented with the Pomelo extension verification language, which currently supports nearly the entirety of Bitcoin Script syntax.

### Verification-Specific Syntax and Semantics

Pomelo introduces an array of extended syntactic constructs into Bitcoin Script to facilitate functional verification. These enhancements include:

1. **`PUSH_BIGINT_{i} {n_bits} {limb_size} limbs{i}`**  
   Inserts a large integer onto the stack in little-endian order, occupying ` ceil(n_bits/limb_size)` stack elements corresponding to individual limbs. Each non-base stack element represents a machine integer of `limb_size` bits, whereas the base element encapsulates `(n_bits - 1) mod limb_size + 1`$` bits.
   - Subsequently, the large integer pushed onto the stack is denoted by the symbolic variable $v_i$, with `limbs{i}[j]` representing the $j$-th limb of $v_i$.
   - The variable $v_i$ is syntactic sugar for the expression:  
     `v_i = limbsi[0] + limbsi[1] * (1 << limb_size) + ... + limbsi[ceil(n_bits/limb_size) - 1] * (1 << (ceil(n_bits/limb_size) - 1) * limb_size))`


2. **`PUSH_SYMINT_{i}`**  
   Pushes a single symbolic integer onto the stack without any range constraints.
   - In subsequent expressions, the symbolic variable $v_i$ references this single stack element.

3. **`DEFINE_{id} { expr }`**  
   Establishes an intermediate variable, $i_{id} = expr$. During evaluation, $i_{id}$ is automatically substituted with $expr$ via an assumption mechanism.

4. **`Assume_{index} { expr }`**  
   Adheres to conventional assumed semantics by introducing the $index$-th hypothesis as $expr$ within the SMT solver.

5. **`Assert_{index} { expr }`**  
   Follows standard assert semantics by invoking the SMT solver to validate whether $expr$ holds under the provided premises, substituting parts of $expr$ with actual symbolic expressions as necessary.

In addition to these primary constructs, Pomelo supports supplementary expression syntaxes to enrich assertion descriptions:

1. **`stack[i]`, `altstack[i]`**  
   Denotes the $i$-th element from the top of the primary and auxiliary stacks, respectively.

2. **`limbs{i}[j].(k)`**  
   Represents the $k$-th bit of the $j$-th limb of the large integer $v_i$, with all indices commencing at 0.

3. **`sha256`**, **`++`**  
   - `sha256` functions as a unary operator, emulating the `OP_SHA256` operation.
   - `++` concatenates two stack elements at the bit vector level, simulating the `OP_CAT` semantics.

4. **Arithmetic Operators (`+`, `-`, `*`, `/`, `%`, `<<`, `>>`)**  
   Implemented within the Quantifier-Free Bit-Vector (QF_BV) logic.

5. **Conditional Expressions**  
   - **`If bool_expr then value_expr1 else value_expr2`**  
     Serves as syntactic sugar, yielding `value_expr1` if `bool_expr` evaluates to true, and `value_expr2` otherwise.

6. **Logical Operators (`&&`, `||`, `<=`, `>=`, `<`, `>`, `==`, `!=`)**  
   Utilized for constructing boolean expressions, with the stipulation that expressions within `Assert` and `Assume` must evaluate to boolean values.

For illustrative examples, please refer to the `./benchmark` directory, which aligns with the corresponding public functions in the [BitVM](https://github.com/RiemaLabs/BitVM) repository. These examples encompass specifications generated through automated scripts, demonstrating the practical application of the extended syntactic constructs.

### Acknowledgment
This work is supported by research grants from StarkWare and Fractal Bitcoin. We extend our gratitude for their generous support, which made this project possible.
