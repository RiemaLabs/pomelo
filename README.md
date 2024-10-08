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

**BitVM** allows for more expressive computations and advanced smart contract functionalities on Bitcoin. Our focus is on using formal verification to improve BitVM's ZK verifier implementation, making the process of verifying its functional correctness more straightforward and reliable.

### Symbolic Variables

Before delving into how Pomelo works, it's essential to understand the concept of **symbolic variables**. Unlike traditional variables that hold concrete values during computation, symbolic variables do not have specific values—they exist symbolically. When these symbolic variables are processed through a script, the output isn't a single number but an equation or set of constraints involving these variables.

For example, in a Bitcoin Script with symbolic inputs, the output will be an equation that incorporates those symbolic variables, enabling reasoning about all possible input values simultaneously. This approach allows developers to verify that the script behaves correctly for any valid input, rather than testing individual cases.

## How It Works

Here's how Pomelo facilitates formal verification:

1. **Script Extraction**: The developer writes or extracts the Bitcoin Script from BitVM.
2. **Specification with Assertions**: The developer provides a specification of the script's correctness using assertions embedded within the script.
3. **Automatic Verification**: Pomelo utilizes an SMT (Satisfiability Modulo Theories) solver to automatically verify the correctness of the script against the specified assertions.
4. **Guarantee of Correctness**: If all assertions are proven, Pomelo guarantees the script's correctness for all possible inputs.

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

## Using Pomelo

### Parsing a Bitcoin Script

To parse a Bitcoin Script written as a string, use the `parse.rkt` script:

```bash
racket ./parse.rkt --str "OP_1 OP_SYMINT_0 OP_ADD OP_3 OP_NUMEQUAL OP_DUP OP_SOLVE"
```

This command will output the internal representation of the parsed script:

```
(#(struct:OP_1) #(struct:OP_SYMINT 0) #(struct:OP_ADD) #(struct:OP_X 3) #(struct:OP_NUMEQUAL) #(struct:OP_DUP) #(struct:OP_SOLVE))
```

To parse a script from a file:

```bash
racket ./parse.rkt --file <path-to-file>
```

### Running a Bitcoin Script

To execute a Bitcoin Script with symbolic variables, use the `run.rkt` script:

```bash
racket ./run.rkt --str "OP_1 OP_SYMINT_0 OP_ADD OP_3 OP_NUMEQUALVERIFY" --debug
```

The output will show intermediate opcodes and the final state of the stacks:

```
# next: #(struct:OP_1)
# next: #(struct:OP_SYMINT 0)
# next: #(struct:OP_ADD)
# next: #(struct:OP_X 3)
# next: #(struct:OP_NUMEQUALVERIFY)
# result (stack):
()
# result (alt stack):
()
```

To run a script from a file:

```bash
racket ./run.rkt --file <path-to-file> --debug
```

### Performing Symbolic Reasoning and Verification

To reason about a Bitcoin Script and verify assertions using symbolic variables:

```bash
racket ./run.rkt --str "OP_1 OP_SYMINT_0 OP_ADD OP_3 OP_NUMEQUALVERIFY OP_SYMINT_0 OP_SOLVE" --debug
```

With the `--debug` flag, you'll see detailed execution steps and the result of the SMT solver:

```
# next: #(struct:OP_1)
# next: #(struct:OP_SYMINT 0)
# next: #(struct:OP_ADD)
# next: #(struct:OP_X 3)
# next: #(struct:OP_NUMEQUALVERIFY)
# next: #(struct:OP_SYMINT 0)
# next: #(struct:OP_SOLVE)
# OP_SOLVE result:
(model
 [int$0 (bv #x00000002 32)])
# result (stack):
()
# result (alt stack):
()
```

### Debug Mode

Enable debug mode for detailed execution tracing:

```bash
racket ./run.rkt --file <path-to-file> --debug
```

This mode provides step-by-step information about the stack and alternative stack at each step of execution, as well as the final state of both stacks.

### Auto-Initialization

To automatically initialize the stack, use the `--auto-init` flag:

```bash
racket ./run.rkt --file <path-to-file> --auto-init
```

### Assertions for Formal Verification

Pomelo supports assertions to specify and verify the functional correctness of scripts. Assertions are specified using the `ASSERT_X` opcode followed by a condition in curly braces `{}`. For example:

```
ASSERT_1 {stack[0] == (if v0 == 0 then 0 else 1)}
```

This assertion checks whether the top item of the stack (`stack[0]`) equals `0` when `v0` is `0`, and `1` otherwise.

## Examples

Below are some example scripts demonstrating how to use Pomelo for symbolic reasoning and verification.

### Example 1: Checking if a BigInt is Zero

```bash
racket run.rkt --file ./bigint/is_zero.bs
```

**Script**: `bigint/is_zero.bs`

```bigint/is_zero.bs
OP_0
OP_0
OP_0
OP_0
OP_0
OP_0
OP_0
OP_0
OP_PUSHBYTES_2 OP_SYMINT_0
OP_PUSHNUM_1
OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND
OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND
OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND
...
ASSERT_1 {stack[0] == (if v0 == 0 then 1 else 0)}
```

**Explanation**:

This script initializes a BigInt with a symbolic variable `v0` and checks if it is zero. The assertion ensures that `stack[0]` is `1` if `v0` is zero, and `0` otherwise.

### Example 2: Comparing Two BigInts for Equality

```bash
racket run.rkt --file ./bigint/equal.bs
```

**Script**: `bigint/equal.bs`

```bigint/equal.bs
OP_0
OP_0
OP_0
...
OP_PUSHBYTES_2 OP_SYMINT_0
...
OP_PUSHBYTES_2 OP_SYMINT_1
OP_PUSHBYTES_1 11 OP_ROLL OP_PUSHNUM_9 OP_ROLL
...
OP_EQUAL OP_TOALTSTACK
...
OP_FROMALTSTACK
...
OP_BOOLAND
...
ASSERT_1 {stack[0] == (if v0 == v1 then 1 else 0)}
```

**Explanation**:

This script compares two symbolic BigInt variables `v0` and `v1` for equality. The assertion verifies that `stack[0]` correctly reflects the result of the comparison.

### Example 3: Comparing Two BigInts with Less Than

```bash
racket run.rkt --file ./bigint/lessthan.bs
```

**Script**: `bigint/lessthan.bs`

```bigint/lessthan.bs
OP_0
OP_0
...
OP_PUSHBYTES_2 OP_SYMINT_0
...
OP_PUSHBYTES_2 OP_SYMINT_1
OP_PUSHBYTES_1 11 OP_ROLL OP_PUSHNUM_9 OP_ROLL
OP_PUSHBYTES_1 11 OP_ROLL OP_PUSHNUM_10 OP_ROLL
...
OP_FROMALTSTACK OP_FROMALTSTACK OP_ROT OP_IF OP_2DROP OP_PUSHNUM_1 OP_ELSE OP_ROT OP_DROP OP_OVER OP_BOOLOR OP_ENDIF
...
OP_BOOLAND
ASSERT_1 {stack[0] == (if v0 < v1 then 1 else 0)}
```

**Explanation**:

This script compares two symbolic BigInt variables `v0` and `v1` to determine if `v0` is less than `v1`. The assertion verifies that `stack[0]` correctly reflects the comparison result, being `1` if `v0` is less than `v1`, and `0` otherwise.


## BitVM Verification Summary

### BigInt Scripts from [`bitvm/src/bigint/std.rs`](https://github.com/BitVM/BitVM/blob/1ffef096e29a6e120e7ce43e7f042743e8591c7a/src/bigint/std.rs)

| Script        | Specification? | Verification? |
|---------------|------------------------|-------------------------|
| `roll.bs`     | Yes                    | Yes                     |
| `copy.bs`     | Yes                    | Yes                     |
| `copy_zip.bs` | Yes                    | Yes                     |
| `dup_zip.bs`  | Yes                    | Yes                     |
| `zip.bs`      | Yes                    | Yes                     |

### BigInt Scripts from [`bitvm/src/bigint/cmp.rs`]((https://github.com/BitVM/BitVM/blob/1ffef096e29a6e120e7ce43e7f042743e8591c7a/src/bigint/cmp.rs))

| Script                    | Specification? | Verification? |
|---------------------------|------------------------|-------------------------|
| `is_zero.bs`              | Yes                    | Yes                     |
| `is_zero_keep_element.bs` | Yes                    | Yes                     |
| `is_one.bs`               | Yes                    | Yes                     |
| `is_one_keep_element.bs`  | Yes                    | Yes                     |
| `equal.bs`                | Yes                    | Yes                     |
| `lessthan.bs`             | Yes                    | Yes                     |
| `lessthanorequal.bs`             | TBD                    | TBD                     |
| `greaterthan.bs`             | TBD                    | TBD                     |
| `greaterthanorequal.bs`             | TBD                    | TBD                     |