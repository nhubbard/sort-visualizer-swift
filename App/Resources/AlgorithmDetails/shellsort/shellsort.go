package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	for _, gap := range []int{8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1} {
		if gap >= n {
			continue
		}
		for i := gap; i < n; i++ {
			for j := i; j >= gap && arr[j] < arr[j-gap]; j -= gap {
				arr[j], arr[j-gap] = arr[j-gap], arr[j]
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
