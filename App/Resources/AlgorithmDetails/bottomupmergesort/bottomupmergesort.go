package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	scratch := append([]int(nil), arr...)
	mergeSize := 2
	for mergeSize <= n {
		copyLength := n
		for index := 0; index < n; index += mergeSize {
			stop := merge(arr, scratch, n, index, mergeSize)
			if stop >= 0 {
				copyLength = stop
			}
		}
		copy(arr[:copyLength], scratch[:copyLength])
		mergeSize *= 2
	}
	if mergeSize/2 != n {
		stop := merge(arr, scratch, n, 0, mergeSize)
		if stop < 0 {
			stop = n
		}
		copy(arr[:stop], scratch[:stop])
	}
	return arr
}

func merge(arr, scratch []int, n, index, mergeSize int) int {
	mid := index + mergeSize/2
	end := index + mergeSize
	if end > n {
		end = n
	}
	if mid >= end {
		return index
	}
	left, right, out := index, mid, index
	for left < mid && right < end {
		if arr[left] <= arr[right] {
			scratch[out] = arr[left]
			left++
		} else {
			scratch[out] = arr[right]
			right++
		}
		out++
	}
	for left < mid {
		scratch[out] = arr[left]
		left++
		out++
	}
	for right < end {
		scratch[out] = arr[right]
		right++
		out++
	}
	return -1
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
