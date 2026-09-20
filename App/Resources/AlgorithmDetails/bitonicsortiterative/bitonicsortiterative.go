package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	for k := 2; k < 2*n; k *= 2 {
		m := ((n + k - 1) / k % 2) != 0
		for j := k / 2; j > 0; j /= 2 {
			for i := 0; i < n; i++ {
				l := i ^ j
				if l > i && l < n {
					ascending := ((i & k) == 0) == m
					if (ascending && arr[i] > arr[l]) || (!ascending && arr[i] < arr[l]) {
						arr[i], arr[l] = arr[l], arr[i]
					}
				}
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
