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
racket ./run.rkt --str "OP_1 OP_2 OP_ADD OP_3 OP_NUMEQUAL"
```

and you'll see the intermediate op codes and the final stacks:

```
# next: #(struct:OP_1)
# next: #(struct:OP_X 2)
# next: #(struct:OP_ADD)
# next: #(struct:OP_X 3)
# next: #(struct:OP_NUMEQUAL)
# result (stack):
((bv #x00000001 32))
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
racket ./run.rkt --str "OP_1 OP_SYMINT_0 OP_ADD OP_3 OP_NUMEQUAL OP_DUP OP_SOLVE"
```

and you'll see the resulting stack (along with any intermediate instructed outputs):

```
# OP_SOLVE result:
(model
 [int$0 (bv #x0000000000000000000000000000000000000000000000000000000000000002 256)])
# result (stack):
((bveq (bv #x0000000000000000000000000000000000000000000000000000000000000003 256) (bvadd (bv #x0000000000000000000000000000000000000000000000000000000000000001 256) int$0)))
```

