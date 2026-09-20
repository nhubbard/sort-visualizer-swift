package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	scratch := make([]int, n)
	subarrayCount := 1
	for subarrayCount < n {
		subarrayCount *= 2
	}

	for subarrayCount > 1 {
		for i := 0; i < subarrayCount; i += 2 {
			low := n * i / subarrayCount
			mid := n * (i + 1) / subarrayCount
			high := n * (i + 2) / subarrayCount
			merge(arr, scratch, low, mid, high)
		}
		subarrayCount /= 2
	}
	return arr
}

func merge(arr, scratch []int, low, mid, high int) {
	left, right, out := low, mid, low
	for left < mid && right < high {
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
	for right < high {
		scratch[out] = arr[right]
		right++
		out++
	}
	copy(arr[low:high], scratch[low:high])
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
