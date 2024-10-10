import re

def extract_ops(input_text):
    lines = input_text.strip().split('\n')
    ops = []
    for line in lines:
        match = re.search(r'Script\((.*?)\)', line)
        if match:
            op_part = match.group(1)
            ops.append(op_part)
    return ops

input_text = """
    script: Script(OP_0)
  script: Script(OP_0)
  script: Script(OP_0)
  script: Script(OP_0)
  script: Script(OP_0)
  script: Script(OP_0)
  script: Script(OP_0)
  script: Script(OP_0)
  script: Script(OP_PUSHBYTES_2 0c62)
  script: Script(OP_PUSHNUM_1)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
  script: Script(OP_PUSHNUM_1 OP_ROLL OP_NOT OP_BOOLAND)
"""

ops = extract_ops(input_text)
for op in ops:
    print(op)