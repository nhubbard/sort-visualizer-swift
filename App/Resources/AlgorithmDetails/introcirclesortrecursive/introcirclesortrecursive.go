package main

import (
	"fmt"
)

func circleSortRoutine(arr []int, lo, hi, end int) int {
	if lo == hi {
		return 0
	}
	low, high := lo, hi
	mid := (hi - lo) / 2
	swapCount := 0
	for lo < hi {
		if hi < end && arr[lo] > arr[hi] {
			arr[lo], arr[hi] = arr[hi], arr[lo]
			swapCount++
		}
		lo++
		hi--
	}
	swapCount += circleSortRoutine(arr, low, low+mid, end)
	if low+mid+1 < end {
		swapCount += circleSortRoutine(arr, low+mid+1, high, end)
	}
	return swapCount
}

func binaryInsertionSort(arr []int, end int) {
	for i := 1; i < end; i++ {
		value := arr[i]
		lo := 0
		hi := i
		for lo < hi {
			mid := lo + (hi-lo)/2
			if value < arr[mid] {
				hi = mid
			} else {
				lo = mid + 1
			}
		}
		j := i
		for j > lo {
			arr[j] = arr[j-1]
			j--
		}
		arr[lo] = value
	}
}

func sort(arr []int) []int {
	end := len(arr)
	if end <= 1 {
		return arr
	}
	n := 1
	threshold := 0
	for n < end {
		n <<= 1
		threshold++
	}
	threshold /= 2

	iterations := 0
	for {
		iterations++
		if iterations >= threshold {
			binaryInsertionSort(arr, end)
			return arr
		}
		if circleSortRoutine(arr, 0, n-1, end) == 0 {
			return arr
		}
	}
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
