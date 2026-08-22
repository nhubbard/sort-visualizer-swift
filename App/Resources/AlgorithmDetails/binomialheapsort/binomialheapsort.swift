func sort(_ arr: inout [Int]) {
    let n = arr.count

    var index = 2
    while index <= n {
        var maxNode = index
        while true {
            let focus = maxNode
            var depth = 1
            while (focus & depth) == 0 {
                if arr[focus - depth - 1] > arr[maxNode - 1] {
                    maxNode = focus - depth
                }
                depth *= 2
            }
            if focus != maxNode {
                arr.swapAt(focus - 1, maxNode - 1)
            }
            if focus == maxNode {
                break
            }
        }
        index += 2
    }

    index = n
    while index > 2 {
        var maxNode = index
        var focus = index
        var depth = 1
        while focus != 0 {
            if (focus & depth) != 0 {
                if arr[focus - 1] > arr[maxNode - 1] {
                    maxNode = focus
                }
                focus -= depth
            }
            depth *= 2
        }

        if maxNode != index {
            focus = index
            while true {
                arr.swapAt(focus - 1, maxNode - 1)
                focus = maxNode
                var innerDepth = 1
                while (focus & innerDepth) == 0 {
                    if arr[focus - innerDepth - 1] > arr[maxNode - 1] {
                        maxNode = focus - innerDepth
                    }
                    innerDepth *= 2
                }
                if focus == maxNode {
                    break
                }
            }
        }
        index -= 1
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
