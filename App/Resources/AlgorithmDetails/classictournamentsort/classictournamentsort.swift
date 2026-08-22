import Foundation

func ceilPow2(_ value: Int) -> Int {
    var r = 1
    while r < value {
        r *= 2
    }
    return r
}

func sort(_ array: inout [Int]) {
    let n = array.count
    guard n > 1 else {
        return
    }

    let size = ceilPow2(n) - 1
    let mod = n % 2
    let treeSize = n + size + mod
    var tree = [Int](repeating: -1, count: treeSize)

    func treeCompare(_ a: Int, _ b: Int) -> Bool {
        array[tree[a]] <= array[tree[b]]
    }

    for i in size ..< (treeSize - mod) {
        tree[i] = i - size
    }
    var j = size
    var k = treeSize - mod
    while j > 0 {
        var i = j
        while i + 1 < k {
            tree[i / 2] = treeCompare(i, i + 1) ? tree[i] : tree[i + 1]
            i += 2
        }
        if i < k {
            tree[i / 2] = tree[i]
        }
        j /= 2
        k /= 2
    }

    func findNext() -> Int {
        var path = tree[0] + size
        while path > 0 {
            tree[path] = -1
            path = (path - 1) / 2
        }

        var node = tree[0] + size
        while node > 0 {
            let sibling = node % 2 == 1 ? node + 1 : node - 1
            let nodeValid = tree[node] != -1
            let siblingValid = tree[sibling] != -1
            let winner: Int
            if nodeValid && siblingValid {
                winner =
                    node < sibling
                        ? (treeCompare(node, sibling) ? tree[node] : tree[sibling])
                        : (treeCompare(sibling, node) ? tree[sibling] : tree[node])
            } else if nodeValid {
                winner = tree[node]
            } else if siblingValid {
                winner = tree[sibling]
            } else {
                winner = -1
            }
            node = (node - 1) / 2
            if winner != -1 {
                tree[node] = winner
            }
        }
        return array[tree[0]]
    }

    var output = [Int](repeating: 0, count: n)
    output[0] = array[tree[0]]
    for i in 1 ..< n {
        output[i] = findNext()
    }
    array = output
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
