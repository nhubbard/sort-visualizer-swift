func sort(_ arr: inout [Int]) {
    let n = arr.count

    func compSwap(_ start: Int, _ end: Int) {
        if arr[start] > arr[end] {
            arr.swapAt(start, end)
        }
    }

    func merge(_ start1: Int, _ len1: Int, _ start2: Int, _ len2: Int) {
        if len1 == 1, len2 == 1 {
            compSwap(start1, start2)
        } else if len1 == 1, len2 == 2 {
            compSwap(start1, start2 + 1)
            compSwap(start1, start2)
        } else if len1 == 2, len2 == 1 {
            compSwap(start1, start2)
            compSwap(start1 + 1, start2)
        } else {
            let mid1 = len1 / 2
            let mid2 = len1 % 2 == 1 ? len2 / 2 : (len2 + 1) / 2
            merge(start1, mid1, start2, mid2)
            merge(start1 + mid1, len1 - mid1, start2 + mid2, len2 - mid2)
            merge(start1 + mid1, len1 - mid1, start2, mid2)
        }
    }

    func boseNelson(_ start: Int, _ length: Int) {
        if length > 1 {
            let mid = length / 2
            boseNelson(start, mid)
            boseNelson(start + mid, length - mid)
            merge(start, mid, start + mid, length - mid)
        }
    }

    boseNelson(0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
