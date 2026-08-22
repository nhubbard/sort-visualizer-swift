package main

import (
	"fmt"
)

func bufferedStoogeSort(arr []int, start, stop int) {
	if stop-start > 1 {
		if stop-start == 2 && arr[start] > arr[stop-1] {
			arr[start], arr[stop-1] = arr[stop-1], arr[start]
		}
		if stop-start > 2 {
			width := stop - start
			third := (width+2)/3 + start
			twoThird := (2*width+2)/3 + start
			if twoThird-third < third {
				twoThird--
			}
			if (width-2)%3 == 0 {
				twoThird--
			}

			bufferedStoogeSort(arr, third, twoThird)
			bufferedStoogeSort(arr, twoThird, stop)

			left := third
			right := twoThird
			bufferStart := start
			for left < twoThird && right < stop {
				if arr[left] > arr[right] {
					arr[bufferStart], arr[right] = arr[right], arr[bufferStart]
					right++
				} else {
					arr[bufferStart], arr[left] = arr[left], arr[bufferStart]
					left++
				}
				bufferStart++
			}
			for right < stop {
				arr[bufferStart], arr[right] = arr[right], arr[bufferStart]
				right++
				bufferStart++
			}

			bufferedStoogeSort(arr, twoThird, stop)

			left = twoThird - 1
			right = stop - 1
			for right > left && left >= start {
				if arr[left] > arr[right] {
					for i := left; i < right; i++ {
						arr[i], arr[i+1] = arr[i+1], arr[i]
					}
					left--
				}
				right--
			}
		}
	}
}

func sort(arr []int) []int {
	bufferedStoogeSort(arr, 0, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
