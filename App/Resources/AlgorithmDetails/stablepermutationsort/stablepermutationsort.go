package main

import (
	"fmt"
)

func isSorted(arr []int) bool {
	for i := 1; i < len(arr); i++ {
		if arr[i] < arr[i-1] {
			return false
		}
	}
	return true
}

func permute(arr []int, idx []int, length int, n int) bool {
	if length < 2 {
		return isSorted(arr)
	}
	for i := length - 2; i >= 0; i-- {
		if permute(arr, idx, length-1, n) {
			return true
		}
		arr[idx[i]], arr[idx[length-1]] = arr[idx[length-1]], arr[idx[i]]
		idx[i], idx[length-1] = idx[length-1], idx[i]
	}
	if permute(arr, idx, length-1, n) {
		return true
	}
	t := idx[length-1]
	for i := length - 1; i > 0; i-- {
		idx[i] = idx[i-1]
	}
	idx[0] = t
	t = arr[idx[0]]
	for i := 1; i < length; i++ {
		arr[idx[i-1]] = arr[idx[i]]
	}
	arr[idx[length-1]] = t
	return false
}

func sort(arr []int) []int {
	n := len(arr)
	idx := make([]int, n)
	for i := 0; i < n; i++ {
		idx[i] = i
	}
	permute(arr, idx, n, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 14, 23}
	fmt.Println(sort(array))
}
