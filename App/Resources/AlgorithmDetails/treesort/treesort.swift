final class Node {
    let pointer: Int
    var left: Node?
    var right: Node?

    init(_ pointer: Int) {
        self.pointer = pointer
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    var root: Node?

    func add(_ node: Node?, _ addPtr: Int) -> Node {
        guard let node = node else {
            return Node(addPtr)
        }
        if arr[addPtr] < arr[node.pointer] {
            node.left = add(node.left, addPtr)
        } else {
            node.right = add(node.right, addPtr)
        }
        return node
    }

    for i in 0 ..< n {
        root = add(root, i)
    }

    var result: [Int] = []

    func traverse(_ node: Node?) {
        guard let node = node else {
            return
        }
        traverse(node.left)
        result.append(arr[node.pointer])
        traverse(node.right)
    }

    traverse(root)

    for i in 0 ..< n {
        arr[i] = result[i]
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
