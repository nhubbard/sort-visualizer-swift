package main

import (
	"fmt"
)

func doubleInsertionSort(arr []int, start, end int) {
	left := start + (end-start)/2 - 1
	right := left + 1
	if arr[left] > arr[right] {
		arr[left], arr[right] = arr[right], arr[left]
	}
	left--
	right++

	for left >= start && right < end {
		if arr[left] > arr[right] {
			leftItem := arr[right]
			rightItem := arr[left]

			pos := left + 1
			for pos <= right && arr[pos] <= leftItem {
				arr[pos-1] = arr[pos]
				pos++
			}
			arr[pos-1] = leftItem

			pos = right - 1
			for pos >= left && arr[pos] >= rightItem {
				arr[pos+1] = arr[pos]
				pos--
			}
			arr[pos+1] = rightItem
		} else {
			leftItem := arr[left]
			rightItem := arr[right]

			pos := left + 1
			for arr[pos] < leftItem {
				arr[pos-1] = arr[pos]
				pos++
			}
			arr[pos-1] = leftItem

			pos = right - 1
			for arr[pos] > rightItem {
				arr[pos+1] = arr[pos]
				pos--
			}
			arr[pos+1] = rightItem
		}

		left--
		right++
	}

	if right < end {
		pos := right - 1
		current := arr[right]
		for pos >= start && arr[pos] > current {
			arr[pos+1] = arr[pos]
			pos--
		}
		arr[pos+1] = current
	}
}

func sort(arr []int) []int {
	if len(arr) > 1 {
		doubleInsertionSort(arr, 0, len(arr))
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
