class Node:
    def __init__(self, value):
        self.value = value
        self.level = 0
        self.left = None
        self.right = None


def level(node):
    return -1 if node is None else node.level


def skew(node):
    if node.left is None:
        return node
    l = node.left
    node.left = l.right
    l.right = node
    return l


def split(node):
    if node.right is None:
        return node
    r = node.right
    node.right = r.left
    r.left = node
    r.level += 1
    return r


def add(node, value):
    if node is None:
        return Node(value)
    if value < node.value:
        node.left = add(node.left, value)
        if level(node.left) == node.level:
            if node.level != level(node.right):
                return skew(node)
            node.level += 1
            return node
        return node
    else:
        node.right = add(node.right, value)
        if level(node.right.right) == node.level:
            return split(node)
        return node


def sort(arr):
    n = len(arr)
    root = None
    for i in range(n):
        root = add(root, arr[i])

    result = []

    def traverse(node):
        if node is None:
            return
        traverse(node.left)
        result.append(node.value)
        traverse(node.right)

    traverse(root)

    for i in range(n):
        arr[i] = result[i]


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
