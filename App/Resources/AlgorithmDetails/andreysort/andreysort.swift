func swap(_ arr: inout [Int], _ i: Int, _ j: Int) {
    let t = arr[i]
    arr[i] = arr[j]
    arr[j] = t
}

/// Base case below length 12: repeatedly swap the minimum of the remaining
/// range to the front.
func selectionSort(_ arr: inout [Int], _ aIn: Int, _ bIn: Int) {
    var a = aIn
    var b = bIn
    while b > 1 {
        var k = 0
        for i in 1 ..< b {
            if arr[a + k] > arr[a + i] {
                k = i
            }
        }
        swap(&arr, a, a + k)
        a += 1
        b -= 1
    }
}

/// Forward block-swap of l elements.
func aswap(_ arr: inout [Int], _ arr1In: Int, _ arr2In: Int, _ lIn: Int) {
    var arr1 = arr1In
    var arr2 = arr2In
    var l = lIn
    while l > 0 {
        swap(&arr, arr1, arr2)
        arr1 += 1
        arr2 += 1
        l -= 1
    }
}

/// Merges the two runs ending at arr1/arr2 (lengths l1/l2), working backward
/// from their high ends into the trailing buffer that starts right after
/// arr2. Returns the count of unplaced left-run elements if the right run
/// ran out first (0 otherwise).
func backmerge(_ arr: inout [Int], _ arr1In: Int, _ l1In: Int, _ arr2In: Int, _ l2In: Int) -> Int {
    var arr1 = arr1In
    var l1 = l1In
    var arr2 = arr2In
    var l2 = l2In
    var arr0 = arr2 + l1
    while true {
        if arr[arr1] > arr[arr2] {
            swap(&arr, arr1, arr0)
            arr1 -= 1
            arr0 -= 1
            l1 -= 1
            if l1 == 0 {
                return 0
            }
        } else {
            swap(&arr, arr2, arr0)
            arr2 -= 1
            arr0 -= 1
            l2 -= 1
            if l2 == 0 {
                break
            }
        }
    }
    let res = l1
    repeat {
        swap(&arr, arr1, arr0)
        arr1 -= 1
        arr0 -= 1
        l1 -= 1
    } while l1 != 0
    return res
}

// Merges arr[a..<a+l) (as l/r blocks of width r) using the buffer
// arr[a+l..<a+l+r): selection-sorts the block leaders, then backmerges each
// selected block into place.
func rmerge(_ arr: inout [Int], _ a: Int, _ l: Int, _ r: Int) {
    var i = 0
    while i < l {
        var q = i
        var j = i + r
        while j < l {
            if arr[a + q] > arr[a + j] {
                q = j
            }
            j += r
        }
        if q != i {
            aswap(&arr, a + i, a + q, r)
        }
        if i != 0 {
            aswap(&arr, a + l, a + i, r)
            _ = backmerge(&arr, a + (l + r - 1), r, a + (i - 1), r)
        }
        i += r
    }
}

/// Computes the block size: roughly sqrt(len), rounded up to a power of two.
func rbnd(_ lenIn: Int) -> Int {
    var len = lenIn / 2
    var k = 0
    var i = 1
    while i < len {
        k += 1
        i *= 2
    }
    len /= k
    k = 1
    while k <= len {
        k *= 2
    }
    return k
}

func msort(_ arr: inout [Int], _ a: Int, _ len: Int) {
    if len < 12 {
        selectionSort(&arr, a, len)
        return
    }

    let r = rbnd(len)
    let lr = (len / r - 1) * r

    var p = 2
    while p <= lr {
        if arr[a + (p - 2)] > arr[a + (p - 1)] {
            swap(&arr, a + (p - 2), a + (p - 1))
        }
        if (p & 2) != 0 {
            p += 2
            continue
        }

        aswap(&arr, a + (p - 2), a + p, 2)

        let m = len - p
        var q = 2
        while true {
            let q0 = 2 * q
            if q0 > m || (p & q0) != 0 {
                break
            }
            _ = backmerge(&arr, a + (p - q - 1), q, a + (p + q - 1), q)
            q = q0
        }
        _ = backmerge(&arr, a + (p + q - 1), q, a + (p - q - 1), q)
        let q1 = q
        q *= 2

        while (q & p) == 0 {
            q *= 2
            rmerge(&arr, a + (p - q), q, q1)
        }

        p += 2
    }

    var q1 = 0
    var q = r
    while q < lr {
        if (lr & q) != 0 {
            q1 += q
            if q1 != q {
                rmerge(&arr, a + (lr - q1), q1, r)
            }
        }
        q *= 2
    }

    let s0 = len - lr
    msort(&arr, a + lr, s0)
    aswap(&arr, a, a + lr, s0)
    let s = s0 + backmerge(&arr, a + (s0 - 1), s0, a + (lr - 1), lr - s0)
    msort(&arr, a, s)
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    msort(&arr, 0, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
