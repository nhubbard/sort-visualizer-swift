final class Node {
    var key: Int
    var left: Node?
    var right: Node?

    init(_ key: Int) {
        self.key = key
    }
}

func leftRotate(_ x: Node) -> Node {
    let y = x.right!
    x.right = y.left
    y.left = x
    return y
}

func rightRotate(_ x: Node) -> Node {
    let y = x.left!
    x.left = y.right
    y.right = x
    return y
}

func splay(_ rootArg: Node?, _ key: Int) -> Node? {
    guard var root = rootArg else {
        return rootArg
    }
    if root.key > key {
        guard let left = root.left else {
            return root
        }
        if left.key > key {
            root.left!.left = splay(root.left!.left, key)
            root = rightRotate(root)
        } else {
            root.left!.right = splay(root.left!.right, key)
            if root.left!.right != nil {
                root.left = leftRotate(root.left!)
            }
        }
        return root.left == nil ? root : rightRotate(root)
    } else {
        guard let right = root.right else {
            return root
        }
        if right.key > key {
            root.right!.left = splay(root.right!.left, key)
            if root.right!.left != nil {
                root.right = rightRotate(root.right!)
            }
        } else {
            root.right!.right = splay(root.right!.right, key)
            root = leftRotate(root)
        }
        return root.right == nil ? root : leftRotate(root)
    }
}

func insertRec(_ rootArg: Node?, _ key: Int) -> Node {
    guard let rootIn = rootArg else {
        return Node(key)
    }
    let root = splay(rootIn, key)!
    let n = Node(key)
    if root.key > key {
        n.right = root
        n.left = root.left
        root.left = nil
    } else {
        n.left = root
        n.right = root.right
        root.right = nil
    }
    return n
}

func sort(_ arr: inout [Int]) {
    var root: Node?
    for x in arr {
        root = insertRec(root, x)
    }
    var result: [Int] = []
    func traverse(_ node: Node?) {
        if let node = node {
            traverse(node.left)
            result.append(node.key)
            traverse(node.right)
        }
    }
    traverse(root)
    for i in 0 ..< arr.count {
        arr[i] = result[i]
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
