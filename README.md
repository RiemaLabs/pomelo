<div align="left">
  <h1>
    <img src="./resources/pomelo.png" width=50>
  	Pomelo
  </h1>
</div>


Pomelo is a symbolic reasoning toolkit for bitcoin script. It includes a Yul to bitcoin script transpiler and a bitcoin script symbolic virtual machine.

## Dependencies

- Racket (8.0+): https://racket-lang.org/
  - Rosette (4.0+): https://github.com/emina/rosette
    - `raco pkg install --auto rosette`

## Example Commands

### Parsing a bitcoin script

To parse a bitcoin script written in string, use:

```bash
racket ./parse.rkt --str "OP_1 OP_SYMINT_0 OP_ADD OP_3 OP_NUMEQUAL OP_DUP OP_SOLVE"
```

and you'll see the internal representation of the parsed script:

```
(#(struct:OP_1) #(struct:OP_SYMINT 0) #(struct:OP_ADD) #(struct:OP_X 3) #(struct:OP_NUMEQUAL) #(struct:OP_DUP) #(struct:OP_SOLVE))
```

To parse a file, use:

```bash
racket ./parse.rkt --file <path-to-file>
```

### Running a bitcoin script

To run a bitcoin script with symbolic variable, use:

```bash
racket ./run.rkt --str "OP_1 OP_SYMINT_0 OP_ADD OP_3 OP_NUMEQUALVERIFY"
```

and you'll see the intermediate op codes and the final stacks:

```
# next: #(struct:OP_1)
# next: #(struct:OP_SYMINT 0)
# next: #(struct:OP_ADD)
# next: #(struct:OP_X 3)
# next: #(struct:OP_NUMEQUALVERIFY)
# result (stack):
()
# result (alt):
()
```

To run a file, use:

```bash
racket ./run.rkt --file <path-to-file>
```

### Reasoning about a bitcoin script

To reason about a bitcoin script with symbolic variable, use:

```bash
racket ./run.rkt --str "OP_1 OP_SYMINT_0 OP_ADD OP_3 OP_NUMEQUALVERIFY OP_SYMINT_0 OP_SOLVE" --debug
```

and you'll see the resulting stack (along with any intermediate instructed outputs if --debug is enabled):

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
# result (alt):
()
```

### Debug Mode

To enable debug output for detailed execution tracing, use the `--debug` flag:

```bash
racket ./run.rkt --file <path-to-file> --debug
```

This will provide detailed information about the stack and alt stack at each step of execution, as well as the final state of both stacks.

### Auto-initialization

To automatically initialize the stack, use the `--auto-init` flag:

```bash
racket ./run.rkt --file <path-to-file> --auto-init
```

### Assertions

Pomelo supports assertions for formal verification. Use the `ASSERT_X` opcode followed by a condition in curly braces. For example:

```
ASSERT_1 {stack[0] == (if v0 == 0 then 0 else 1)}
```

This assertion checks if the top stack item is 0 when v0 is 0, and 1 otherwise.