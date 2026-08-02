func sort(_ arr: inout [Int]) {
    func dirCompareVal(_ left: Int, _ right: Int, _ dir: Bool) -> Int {
        let res: Int
        if left > right {
            res = 1
        } else if left < right {
            res = -1
        } else {
            res = 0
        }
        return dir ? res : -res
    }

    func gapReverse(_ start: Int, _ end: Int, _ gap: Int) {
        var i = start
        var j = end
        while i < j {
            let tmp = arr[i]
            arr[i] = arr[j - gap]
            arr[j - gap] = tmp
            i += gap
            j -= gap
        }
    }

    func insertLast(_ a: Int, _ b: Int, _ gap: Int, _ dir: Bool) -> Bool {
        var did = false
        let key = arr[b]
        var j = b - gap
        while j >= a && dirCompareVal(key, arr[j], dir) < 0 {
            arr[j + gap] = arr[j]
            did = true
            j -= gap
        }
        arr[j + gap] = key
        return did
    }

    struct MatrixShape {
        let width: Int
        let insertLast: Bool
    }

    func getMatrixDims(_ length: Int) -> MatrixShape {
        var dim = Int(Double(length).squareRoot())
        let insertLastFlag = dim * dim == length - 1
        while length % dim != 0 {
            dim -= 1
        }
        let width = dim
        let height = length / dim
        let unbalanced = (width == 1) != (height == 1)
        return MatrixShape(width: width, insertLast: unbalanced || insertLastFlag)
    }

    func matrixSort(_ start: Int, _ end: Int, _ gap: Int, _ dir: Bool) -> Bool {
        let length = (end - start) / gap
        if length < 2 {
            return false
        } else if length <= 16 {
            var did = false
            var i = start
            while i < end {
                did = insertLast(start, i, gap, dir) || did
                i += gap
            }
            return did
        } else {
            let matShape = getMatrixDims(length)
            if matShape.insertLast {
                let did1 = matrixSort(start, end - gap, gap, dir)
                let did2 = insertLast(start, end - gap, gap, dir)
                return did1 || did2
            }

            var i = start + matShape.width * gap
            while i < end {
                gapReverse(i, i + matShape.width * gap, gap)
                i += 2 * matShape.width * gap
            }

            var did = false
            var newdid = true
            while newdid {
                newdid = false
                var curdir = dir
                i = start
                while i < end {
                    newdid = matrixSort(i, i + matShape.width * gap, gap, curdir) || newdid
                    did = did || newdid
                    curdir.toggle()
                    i += matShape.width * gap
                }

                newdid = false
                for k in 0 ..< matShape.width {
                    newdid = matrixSort(start + k * gap, end + k * gap, gap * matShape.width, dir) || newdid
                    did = did || newdid
                }
            }
            i = start + matShape.width * gap
            while i < end {
                gapReverse(i, i + matShape.width * gap, gap)
                i += 2 * matShape.width * gap
            }

            return did
        }
    }

    matrixSort(0, arr.count, 1, true)
}

var array: [Int] = [
    15, 3, 22, 8, 19, 1, 24, 11, 6, 20,
    9, 17, 2, 14, 23, 5, 18, 0, 12, 21,
    7, 16, 4, 13, 10,
]
sort(&array)
print(array)
