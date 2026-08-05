package main

import (
	"fmt"
)

func merge(arr []int, low, mid, high int) {
	left := make([]int, mid-low)
	right := make([]int, high-mid)
	copy(left, arr[low:mid])
	copy(right, arr[mid:high])
	i, j, k := 0, 0, low
	for i < len(left) && j < len(right) {
		if left[i] <= right[j] {
			arr[k] = left[i]
			i++
		} else {
			arr[k] = right[j]
			j++
		}
		k++
	}
	for i < len(left) {
		arr[k] = left[i]
		i++
		k++
	}
	for j < len(right) {
		arr[k] = right[j]
		j++
		k++
	}
}

func sort(arr []int) []int {
	n := len(arr)
	subarrayCount := 1
	for subarrayCount < n {
		subarrayCount *= 2
	}

	for subarrayCount > 1 {
		for i := 0; i < subarrayCount; i += 2 {
			low := n * i / subarrayCount
			mid := n * (i + 1) / subarrayCount
			high := n * (i + 2) / subarrayCount
			merge(arr, low, mid, high)
		}
		subarrayCount /= 2
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
