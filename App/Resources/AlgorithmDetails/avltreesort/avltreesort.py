class Node:
    def __init__(self, value):
        self.value = value
        self.left = None
        self.right = None
        self.balance = 0


class AddResult:
    def __init__(self, node, height_changed):
        self.node = node
        self.height_changed = height_changed


def single_rotate_right(node):
    b = node.left
    node.left = b.right
    b.right = node
    node.balance = 0
    b.balance = 0
    return b


def single_rotate_left(node):
    b = node.right
    node.right = b.left
    b.left = node
    node.balance = 0
    b.balance = 0
    return b


def double_rotate_right(node):
    old_b_balance = node.left.right.balance
    node.left = single_rotate_left(node.left)
    b = single_rotate_right(node)
    if old_b_balance == -1:
        b.right.balance = 1
    if old_b_balance == 1:
        b.left.balance = -1
    return b


def double_rotate_left(node):
    old_b_balance = node.right.left.balance
    node.right = single_rotate_right(node.right)
    b = single_rotate_left(node)
    if old_b_balance == -1:
        b.right.balance = 1
    if old_b_balance == 1:
        b.left.balance = -1
    return b


def height_change_left(node):
    if node.balance != -1:
        node.balance -= 1
        return AddResult(node, node.balance == -1)
    if node.left.balance == -1:
        return AddResult(single_rotate_right(node), False)
    return AddResult(double_rotate_right(node), False)


def height_change_right(node):
    if node.balance != 1:
        node.balance += 1
        return AddResult(node, node.balance == 1)
    if node.right.balance == 1:
        return AddResult(single_rotate_left(node), False)
    return AddResult(double_rotate_left(node), False)


def add(node, value):
    if node is None:
        return AddResult(Node(value), True)
    if value < node.value:
        result = add(node.left, value)
        node.left = result.node
        if result.height_changed:
            return height_change_left(node)
        return AddResult(node, False)
    else:
        result = add(node.right, value)
        node.right = result.node
        if result.height_changed:
            return height_change_right(node)
        return AddResult(node, False)


def sort(arr):
    root = None
    for value in arr:
        root = add(root, value).node

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
