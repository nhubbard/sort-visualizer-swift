final class Node {
    var value: Int
    var left: Node?
    var right: Node?
    var balance = 0

    init(_ value: Int) {
        self.value = value
    }
}

struct AddResult {
    var node: Node
    var heightChanged: Bool
}

func singleRotateRight(_ node: Node) -> Node {
    let b = node.left!
    node.left = b.right
    b.right = node
    node.balance = 0
    b.balance = 0
    return b
}

func singleRotateLeft(_ node: Node) -> Node {
    let b = node.right!
    node.right = b.left
    b.left = node
    node.balance = 0
    b.balance = 0
    return b
}

func doubleRotateRight(_ node: Node) -> Node {
    let oldBBalance = node.left!.right!.balance
    node.left = singleRotateLeft(node.left!)
    let b = singleRotateRight(node)
    if oldBBalance == -1 {
        b.right!.balance = 1
    }
    if oldBBalance == 1 {
        b.left!.balance = -1
    }
    return b
}

func doubleRotateLeft(_ node: Node) -> Node {
    let oldBBalance = node.right!.left!.balance
    node.right = singleRotateRight(node.right!)
    let b = singleRotateLeft(node)
    if oldBBalance == -1 {
        b.right!.balance = 1
    }
    if oldBBalance == 1 {
        b.left!.balance = -1
    }
    return b
}

func heightChangeLeft(_ node: Node) -> AddResult {
    if node.balance != -1 {
        node.balance -= 1
        return AddResult(node: node, heightChanged: node.balance == -1)
    }
    if node.left!.balance == -1 {
        return AddResult(node: singleRotateRight(node), heightChanged: false)
    }
    return AddResult(node: doubleRotateRight(node), heightChanged: false)
}

func heightChangeRight(_ node: Node) -> AddResult {
    if node.balance != 1 {
        node.balance += 1
        return AddResult(node: node, heightChanged: node.balance == 1)
    }
    if node.right!.balance == 1 {
        return AddResult(node: singleRotateLeft(node), heightChanged: false)
    }
    return AddResult(node: doubleRotateLeft(node), heightChanged: false)
}

func add(_ node: Node?, _ value: Int) -> AddResult {
    guard let node = node else {
        return AddResult(node: Node(value), heightChanged: true)
    }
    if value < node.value {
        let result = add(node.left, value)
        node.left = result.node
        if result.heightChanged {
            return heightChangeLeft(node)
        }
        return AddResult(node: node, heightChanged: false)
    } else {
        let result = add(node.right, value)
        node.right = result.node
        if result.heightChanged {
            return heightChangeRight(node)
        }
        return AddResult(node: node, heightChanged: false)
    }
}

func sort(_ arr: inout [Int]) {
    var root: Node?
    for value in arr {
        root = add(root, value).node
    }

    var result: [Int] = []

    func traverse(_ node: Node?) {
        guard let node = node else {
            return
        }
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
