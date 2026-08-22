class Node:
    def __init__(self, pointer):
        self.pointer = pointer
        self.left = None
        self.right = None


def sort(arr):
    n = len(arr)
    root = None

    def add(node, add_ptr):
        if node is None:
            return Node(add_ptr)
        if arr[add_ptr] < arr[node.pointer]:
            node.left = add(node.left, add_ptr)
        else:
            node.right = add(node.right, add_ptr)
        return node

    for i in range(n):
        root = add(root, i)

    result = []

    def traverse(node):
        if node is None:
            return
        traverse(node.left)
        result.append(arr[node.pointer])
        traverse(node.right)

    traverse(root)

    for i in range(n):
        arr[i] = result[i]
    return arr


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
