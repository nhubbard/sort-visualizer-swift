final class Node {
    var value: Int
    var left: Node?
    var right: Node?
    var level = 0

    init(_ value: Int) {
        self.value = value
    }
}

func level(_ node: Node?) -> Int {
    node?.level ?? -1
}

func skew(_ node: Node) -> Node {
    guard let l = node.left else { return node }
    node.left = l.right
    l.right = node
    return l
}

func split(_ node: Node) -> Node {
    guard let r = node.right else { return node }
    node.right = r.left
    r.left = node
    r.level += 1
    return r
}

func add(_ node: Node?, _ value: Int) -> Node {
    guard let node else { return Node(value) }
    if value < node.value {
        node.left = add(node.left, value)
        if level(node.left) == node.level {
            if node.level != level(node.right) {
                return skew(node)
            }
            node.level += 1
            return node
        }
        return node
    } else {
        node.right = add(node.right, value)
        if level(node.right?.right) == node.level {
            return split(node)
        }
        return node
    }
}

func sort(_ arr: inout [Int]) {
    var root: Node?
    for v in arr {
        root = add(root, v)
    }
    var result: [Int] = []
    func traverse(_ node: Node?) {
        guard let node else { return }
        traverse(node.left)
        result.append(node.value)
        traverse(node.right)
    }
    traverse(root)
    arr = result
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
