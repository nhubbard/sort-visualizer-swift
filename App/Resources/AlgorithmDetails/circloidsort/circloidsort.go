package main

import (
	"fmt"
)

func circle(arr []int, left, right int) bool {
	a := left
	b := right
	swapped := false
	for a < b {
		if arr[a] > arr[b] {
			arr[a], arr[b] = arr[b], arr[a]
			swapped = true
		}
		a++
		b--
		if a == b {
			b++
		}
	}
	return swapped
}

func circlePass(arr []int, left, right int) bool {
	if left >= right {
		return false
	}
	mid := (left + right) / 2
	l := circlePass(arr, left, mid)
	r := circlePass(arr, mid+1, right)
	c := circle(arr, left, right)
	return c || l || r
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	for circlePass(arr, 0, n-1) {
		// repeat until a full sweep makes no swaps
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
