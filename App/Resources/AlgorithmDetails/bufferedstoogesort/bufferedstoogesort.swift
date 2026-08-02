func bufferedStoogeSort(_ arr: inout [Int], _ start: Int, _ stop: Int) {
    if stop - start > 1 {
        if stop - start == 2, arr[start] > arr[stop - 1] {
            arr.swapAt(start, stop - 1)
        }
        if stop - start > 2 {
            let width = stop - start
            let third = (width + 2) / 3 + start
            var twoThird = (2 * width + 2) / 3 + start
            if twoThird - third < third {
                twoThird -= 1
            }
            if (width - 2) % 3 == 0 {
                twoThird -= 1
            }

            bufferedStoogeSort(&arr, third, twoThird)
            bufferedStoogeSort(&arr, twoThird, stop)

            var left = third
            var right = twoThird
            var bufferStart = start
            while left < twoThird, right < stop {
                if arr[left] > arr[right] {
                    arr.swapAt(bufferStart, right)
                    right += 1
                } else {
                    arr.swapAt(bufferStart, left)
                    left += 1
                }
                bufferStart += 1
            }
            while right < stop {
                arr.swapAt(bufferStart, right)
                right += 1
                bufferStart += 1
            }

            bufferedStoogeSort(&arr, twoThird, stop)

            left = twoThird - 1
            right = stop - 1
            while right > left, left >= start {
                if arr[left] > arr[right] {
                    for i in left ..< right {
                        arr.swapAt(i, i + 1)
                    }
                    left -= 1
                }
                right -= 1
            }
        }
    }
}

func sort(_ arr: inout [Int]) {
    bufferedStoogeSort(&arr, 0, arr.count)
}

var array: [Int] = [
    0, 39, 21, 62, 91, 77, 14, 23,
    90, 69, 51, 81, 68, 83, 32, 56,
]
sort(&array)
print(array)
