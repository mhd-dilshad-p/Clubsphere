import sys

paths = [line.strip() for line in open("tree_output.txt").readlines() if line.strip()]
tree = {}
for path in paths:
    parts = path.split("/")
    current = tree
    for part in parts:
        current = current.setdefault(part, {})

def print_tree(d, prefix=""):
    keys = sorted(list(d.keys()))
    for i, k in enumerate(keys):
        is_last = (i == len(keys) - 1)
        marker = "└── " if is_last else "├── "
        print(f"{prefix}{marker}{k}")
        print_tree(d[k], prefix + ("    " if is_last else "│   "))

with open("formatted_tree.md", "w") as f:
    sys.stdout = f
    for root in sorted(tree.keys()):
        print(root)
        print_tree(tree[root])
