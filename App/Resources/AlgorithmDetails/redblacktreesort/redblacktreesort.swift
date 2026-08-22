final class Node {
    var value: Int
    var left: Node?
    var right: Node?
    var isRed = true

    init(_ value: Int) {
        self.value = value
    }
}

func isRed(_ node: Node?) -> Bool {
    node?.isRed ?? false
}

func singleRotateRight(_ node: Node) -> Node {
    let b = node.left!
    node.left = b.right
    b.right = node
    b.isRed = false
    node.isRed = true
    return b
}

func singleRotateLeft(_ node: Node) -> Node {
    let b = node.right!
    node.right = b.left
    b.left = node
    b.isRed = false
    node.isRed = true
    return b
}

func doubleRotateRight(_ node: Node) -> Node {
    node.left = singleRotateLeft(node.left!)
    return singleRotateRight(node)
}

func doubleRotateLeft(_ node: Node) -> Node {
    node.right = singleRotateRight(node.right!)
    return singleRotateLeft(node)
}

struct AddResult {
    var node: Node
    var needsFix: Bool
}

func add(_ node: Node?, _ value: Int) -> AddResult {
    guard let node = node else {
        return AddResult(node: Node(value), needsFix: false)
    }

    if !node.isRed, isRed(node.left), isRed(node.right) {
        node.isRed = true
        node.left!.isRed = false
        node.right!.isRed = false
    }

    if value < node.value {
        let child = add(node.left, value)
        node.left = child.node
        if child.needsFix {
            if isRed(node.left!.left) {
                return AddResult(node: singleRotateRight(node), needsFix: false)
            }
            return AddResult(node: doubleRotateRight(node), needsFix: false)
        }
        return AddResult(node: node, needsFix: node.isRed && isRed(node.left))
    } else {
        let child = add(node.right, value)
        node.right = child.node
        if child.needsFix {
            if isRed(node.right!.right) {
                return AddResult(node: singleRotateLeft(node), needsFix: false)
            }
            return AddResult(node: doubleRotateLeft(node), needsFix: false)
        }
        return AddResult(node: node, needsFix: node.isRed && isRed(node.right))
    }
}

func sort(_ arr: inout [Int]) {
    var root: Node?
    for v in arr {
        let inserted = add(root, v)
        root = inserted.node
        root?.isRed = false
    }

    var result: [Int] = []

    func traverse(_ node: Node?) {
        guard let node = node else { return }
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
