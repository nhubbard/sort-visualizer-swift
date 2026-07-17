package main

import (
	"fmt"
)

func traverse(arr []int, temp []int, lower []int, upper []int, idx *int, r int) {
	if lower[r] != 0 {
		traverse(arr, temp, lower, upper, idx, lower[r])
	}
	temp[*idx] = arr[r]
	*idx++
	if upper[r] != 0 {
		traverse(arr, temp, lower, upper, idx, upper[r])
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	lower := make([]int, n)
	upper := make([]int, n)

	for i := 1; i < n; i++ {
		c := 0
		for {
			var next []int
			if arr[i] < arr[c] {
				next = lower
			} else {
				next = upper
			}
			if next[c] == 0 {
				next[c] = i
				break
			} else {
				c = next[c]
			}
		}
	}

	temp := make([]int, n)
	idx := 0
	traverse(arr, temp, lower, upper, &idx, 0)
	copy(arr, temp)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
