package main

import (
	"fmt"
)

func compositeLess(arr []int, key []int, mid int, i int) bool {
	if arr[mid] < arr[i] {
		return true
	}
	if arr[mid] == arr[i] {
		return key[mid] < key[i]
	}
	return false
}

func binarySearch(arr []int, key []int, n int, i int) int {
	start := 0
	end := n - 1
	for start < end {
		mid := (start + end) / 2
		if compositeLess(arr, key, mid, i) {
			start = mid + 1
		} else {
			end = mid
		}
	}
	return start
}

func sort(arr []int) []int {
	n := len(arr)
	key := make([]int, n)
	for i := 0; i < n; i++ {
		key[i] = i
	}

	for i := 1; i < n; i++ {
		done := false
		for !done {
			pos := binarySearch(arr, key, n, i)
			if pos == i {
				done = true
			} else if i < pos-1 {
				arr[i], arr[pos-1] = arr[pos-1], arr[i]
				key[i], key[pos-1] = key[pos-1], key[i]
			} else {
				arr[i], arr[pos] = arr[pos], arr[i]
				key[i], key[pos] = key[pos], key[i]
			}
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
