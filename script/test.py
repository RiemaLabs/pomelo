filepath = input()
with open(filepath, 'r') as f:
    loc = sum(1 for word in f.read().split() if word.startswith('OP_'))
print(loc)
