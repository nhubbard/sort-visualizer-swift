package main

import (
	"fmt"
)

const insertionRun = 4

func insertionSortRange(arr []int, lo int, hi int) {
	for i := lo + 1; i < hi; i++ {
		key := arr[i]
		j := i - 1
		for j >= lo && arr[j] > key {
			arr[j+1] = arr[j]
			j--
		}
		arr[j+1] = key
	}
}

// parityMerge merges the two equal-length sorted runs source[lo:lo+runLength] and
// source[lo+runLength:lo+2*runLength] into dest, filling from both ends toward the middle at
// once instead of scanning front to back alone.
func parityMerge(source []int, lo int, runLength int, dest []int) {
	left := lo
	right := lo + runLength
	leftEnd := lo + runLength - 1
	rightEnd := lo + 2*runLength - 1
	front := lo
	back := lo + 2*runLength - 1

	for step := 0; step < runLength; step++ {
		if source[left] <= source[right] {
			dest[front] = source[left]
			left++
		} else {
			dest[front] = source[right]
			right++
		}
		front++

		if source[leftEnd] > source[rightEnd] {
			dest[back] = source[leftEnd]
			leftEnd--
		} else {
			dest[back] = source[rightEnd]
			rightEnd--
		}
		back--
	}
}

func mergeRange(source []int, lo int, mid int, hi int, dest []int) {
	left, right, out := lo, mid, lo
	for left < mid && right < hi {
		if source[left] <= source[right] {
			dest[out] = source[left]
			left++
		} else {
			dest[out] = source[right]
			right++
		}
		out++
	}
	for left < mid {
		dest[out] = source[left]
		left++
		out++
	}
	for right < hi {
		dest[out] = source[right]
		right++
		out++
	}
}

func min(a int, b int) int {
	if a < b {
		return a
	}
	return b
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	buffer := make([]int, n)
	copy(buffer, arr)

	for lo := 0; lo < n; lo += insertionRun {
		insertionSortRange(arr, lo, min(lo+insertionRun, n))
	}

	for runLength := insertionRun; runLength < n; runLength *= 2 {
		for lo := 0; lo < n; lo += runLength * 2 {
			mid := min(lo+runLength, n)
			hi := min(lo+runLength*2, n)
			if mid-lo == runLength && hi-mid == runLength {
				parityMerge(arr, lo, runLength, buffer)
			} else if mid < hi {
				mergeRange(arr, lo, mid, hi, buffer)
			} else {
				for i := lo; i < mid; i++ {
					buffer[i] = arr[i]
				}
			}
		}
		copy(arr, buffer)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
