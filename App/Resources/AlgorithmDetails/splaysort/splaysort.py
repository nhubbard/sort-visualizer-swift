class Node:
    def __init__(self, key):
        self.key = key
        self.left = None
        self.right = None


def left_rotate(x):
    y = x.right
    x.right = y.left
    y.left = x
    return y


def right_rotate(x):
    y = x.left
    x.left = y.right
    y.right = x
    return y


def splay(root, key):
    if root is None:
        return root
    if root.key > key:
        if root.left is None:
            return root
        if root.left.key > key:
            root.left.left = splay(root.left.left, key)
            root = right_rotate(root)
        else:
            root.left.right = splay(root.left.right, key)
            if root.left.right is not None:
                root.left = left_rotate(root.left)
        return root if root.left is None else right_rotate(root)
    else:
        if root.right is None:
            return root
        if root.right.key > key:
            root.right.left = splay(root.right.left, key)
            if root.right.left is not None:
                root.right = right_rotate(root.right)
        else:
            root.right.right = splay(root.right.right, key)
            root = left_rotate(root)
        return root if root.right is None else left_rotate(root)


def insert_rec(root, key):
    if root is None:
        return Node(key)
    root = splay(root, key)
    n = Node(key)
    if root.key > key:
        n.right = root
        n.left = root.left
        root.left = None
    else:
        n.left = root
        n.right = root.right
        root.right = None
    return n


def sort(arr):
    root = None
    for x in arr:
        root = insert_rec(root, x)
    result = []

    def traverse(node):
        if node is not None:
            traverse(node.left)
            result.append(node.key)
            traverse(node.right)

    traverse(root)
    for i in range(len(arr)):
        arr[i] = result[i]
    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
