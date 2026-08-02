func reverseRange(_ arr: inout [Int], _ lo0: Int, _ hi0: Int) {
    var lo = lo0
    var hi = hi0
    while lo < hi {
        arr.swapAt(lo, hi)
        lo += 1
        hi -= 1
    }
}

func twinSwap(_ arr: inout [Int], _ nmemb: Int) -> Int {
    var index = 0
    var end = nmemb - 2
    while index <= end {
        if arr[index] <= arr[index + 1] {
            index += 2
            continue
        }
        let start = index
        index += 2
        while true {
            if index > end {
                if start == 0 && (nmemb % 2 == 0 || arr[index - 1] > arr[index]) {
                    end = nmemb - 1
                    reverseRange(&arr, start, end)
                    return 1
                }
                break
            }
            if arr[index] > arr[index + 1] {
                if arr[index - 1] > arr[index] {
                    index += 2
                    continue
                }
                arr.swapAt(index, index + 1)
            }
            break
        }
        end = index - 1
        reverseRange(&arr, start, end)
        end = nmemb - 2
        index += 2
    }
    return 0
}

func tailMerge(_ arr: inout [Int], _ buf: inout [Int], _ nmemb: Int, _ block0: Int) {
    var block = block0
    let s = 0
    while block < nmemb {
        var offset = 0
        while offset + block < nmemb {
            let a = offset
            var e = a + block - 1
            if arr[e] <= arr[e + 1] {
                offset += block * 2
                continue
            }
            var cMax: Int
            var dMax: Int
            if offset + block * 2 <= nmemb {
                cMax = s + block
                dMax = a + block * 2
            } else {
                cMax = s + nmemb - (offset + block)
                dMax = nmemb
            }
            var d = dMax - 1
            while arr[e] <= arr[d] {
                dMax -= 1
                d -= 1
                cMax -= 1
            }
            var c = s
            d = a + block
            while c < cMax {
                buf[c] = arr[d]
                c += 1
                d += 1
            }
            c -= 1
            d = a + block - 1
            e = dMax - 1
            if arr[a] <= arr[a + block] {
                arr[e] = arr[d]; e -= 1; d -= 1
                while c >= s {
                    while arr[d] > buf[c] {
                        arr[e] = arr[d]; e -= 1; d -= 1
                    }
                    arr[e] = buf[c]; e -= 1; c -= 1
                }
            } else {
                arr[e] = arr[d]; e -= 1; d -= 1
                while d >= a {
                    while arr[d] <= buf[c] {
                        arr[e] = buf[c]; e -= 1; c -= 1
                    }
                    arr[e] = arr[d]; e -= 1; d -= 1
                }
                while c >= s {
                    arr[e] = buf[c]; e -= 1; c -= 1
                }
            }
            offset += block * 2
        }
        block *= 2
    }
}

func twinsort(_ arr: inout [Int], _ nmemb: Int) {
    if twinSwap(&arr, nmemb) == 0 {
        var buf = [Int](repeating: 0, count: nmemb / 2)
        tailMerge(&arr, &buf, nmemb, 2)
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    twinsort(&arr, n)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
