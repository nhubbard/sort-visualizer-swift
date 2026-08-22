func sort(_ arr: inout [Int]) {
    let end = arr.count

    func compSwap(_ a: Int, _ b: Int) {
        if b < end, arr[a] > arr[b] {
            arr.swapAt(a, b)
        }
    }

    func circle(_ pos: Int, _ ln: Int, _ gap: Int) {
        if ln < 2 {
            return
        }
        var i = 0
        while 2 * i < (ln - 1) * gap {
            compSwap(pos + i, pos + (ln - 1) * gap - i)
            i += gap
        }
        circle(pos, ln / 2, gap)
        if pos + ln * gap / 2 < end {
            circle(pos + ln * gap / 2, ln / 2, gap)
        }
    }

    func weaveCircle(_ pos: Int, _ ln: Int, _ gap: Int) {
        if ln < 2 {
            return
        }
        weaveCircle(pos, ln / 2, 2 * gap)
        weaveCircle(pos + gap, ln / 2, 2 * gap)
        circle(pos, ln, gap)
    }

    var padded = 1
    while padded < end {
        padded *= 2
    }

    weaveCircle(0, padded, 1)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
