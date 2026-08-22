import Foundation

// [start, stop) is the half-open range being sorted. merge selects whether
// the two halves are recursively pre-sorted before the fixed diamond
// comparison pattern below merges them together.

func sort(_ arr: inout [Int], _ start: Int, _ stop: Int, _ merge: Bool) {
    if stop - start == 2 {
        if arr[start] > arr[stop - 1] {
            arr.swapAt(start, stop - 1)
        }
    } else if stop - start >= 3 {
        let div = Double(stop - start) / 4.0
        let mid = (stop - start) / 2 + start
        let quarter = Int(div) + start
        let threeQuarters = Int(div * 3) + start

        if merge {
            sort(&arr, start, mid, true)
            sort(&arr, mid, stop, true)
        }
        sort(&arr, quarter, threeQuarters, false)
        sort(&arr, start, mid, false)
        sort(&arr, mid, stop, false)
        sort(&arr, quarter, threeQuarters, false)
    }
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array, 0, array.count, true)
print(array)
