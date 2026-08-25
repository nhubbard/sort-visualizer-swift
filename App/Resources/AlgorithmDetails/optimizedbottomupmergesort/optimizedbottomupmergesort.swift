import Foundation

let blockSize = 16

func binaryInsertionSort(_ arr: inout [Int], _ lo: Int, _ hi: Int) {
    var i = lo + 1
    while i < hi {
        let key = arr[i]
        var left = lo
        var right = i
        while left < right {
            let mid = (left + right) / 2
            if arr[mid] <= key {
                left = mid + 1
            } else {
                right = mid
            }
        }
        var j = i
        while j > left {
            arr[j] = arr[j - 1]
            j -= 1
        }
        arr[left] = key
        i += 1
    }
}

func merge(_ src: [Int], _ dst: inout [Int], _ low: Int, _ mid: Int, _ high: Int) {
    var i = low
    var j = mid
    var k = low
    while i < mid, j < high {
        if src[i] <= src[j] {
            dst[k] = src[i]
            i += 1
        } else {
            dst[k] = src[j]
            j += 1
        }
        k += 1
    }
    while i < mid {
        dst[k] = src[i]
        i += 1
        k += 1
    }
    while j < high {
        dst[k] = src[j]
        j += 1
        k += 1
    }
}

func sort(_ arr: inout [Int]) {
    let n = arr.count
    if n < blockSize {
        binaryInsertionSort(&arr, 0, n)
        return
    }

    // Pre-pass: sort fixed-size blocks with binary insertion sort so the merge phase can
    // start from already-sorted runs instead of single elements.
    var low = 0
    while low < n {
        binaryInsertionSort(&arr, low, min(low + blockSize, n))
        low += blockSize
    }

    // Merge phase: ping-pong between arr and scratch, alternating direction every pass,
    // instead of always merging into scratch and copying the whole buffer back.
    var src = arr
    var dst = [Int](repeating: 0, count: n)
    var width = blockSize
    while width < n {
        low = 0
        while low < n {
            let mid = min(low + width, n)
            let high = min(low + 2 * width, n)
            if mid < high {
                merge(src, &dst, low, mid, high)
            } else {
                for i in low ..< mid {
                    dst[i] = src[i]
                }
            }
            low += 2 * width
        }
        swap(&src, &dst)
        width *= 2
    }

    // Unlike an array in most of this bundle's other languages, Swift's Array is a value
    // type with copy-on-write storage rather than a true reference type: writing through
    // `dst` after it has been swapped back to alias `arr`'s original buffer triggers a
    // silent copy-on-write fork instead of mutating `arr` in place, so the "an even number
    // of passes lands the result back in the main array for free" trick that pointer-based
    // languages get does not hold here. Copying the final buffer back unconditionally is
    // the correct fix -- and it costs nothing extra, since nothing mutates `src` afterward,
    // so copy-on-write never actually duplicates the storage.
    arr = src
}

var array: [Int] = [
    81, 14, 3, 94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11, 75, 54,
    4, 3, 11, 27, 29, 64, 77, 3, 71, 25, 91, 83, 89, 69, 53, 28,
    57, 75, 35, 0, 97, 20, 89, 54,
]
sort(&array)
print(array)
