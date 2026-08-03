class Node:
    def __init__(self, value):
        self.value = value
        self.left = None
        self.right = None
        self.is_red = True


def is_red(node):
    return node is not None and node.is_red


def single_rotate_right(node):
    b = node.left
    node.left = b.right
    b.right = node
    b.is_red = False
    node.is_red = True
    return b


def single_rotate_left(node):
    b = node.right
    node.right = b.left
    b.left = node
    b.is_red = False
    node.is_red = True
    return b


def double_rotate_right(node):
    node.left = single_rotate_left(node.left)
    return single_rotate_right(node)


def double_rotate_left(node):
    node.right = single_rotate_right(node.right)
    return single_rotate_left(node)


def add(node, value):
    if node is None:
        return Node(value), False

    if not node.is_red and is_red(node.left) and is_red(node.right):
        node.is_red = True
        node.left.is_red = False
        node.right.is_red = False

    if value < node.value:
        child, needs_fix = add(node.left, value)
        node.left = child
        if needs_fix:
            if is_red(node.left.left):
                return single_rotate_right(node), False
            return double_rotate_right(node), False
        return node, node.is_red and is_red(node.left)
    else:
        child, needs_fix = add(node.right, value)
        node.right = child
        if needs_fix:
            if is_red(node.right.right):
                return single_rotate_left(node), False
            return double_rotate_left(node), False
        return node, node.is_red and is_red(node.right)


def sort(arr):
    root = None
    for v in arr:
        root, _ = add(root, v)
        root.is_red = False

    result = []

    def traverse(node):
        if node is None:
            return
        traverse(node.left)
        result.append(node.value)
        traverse(node.right)

    traverse(root)

    for i in range(len(arr)):
        arr[i] = result[i]
    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
