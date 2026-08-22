package main

import (
	"fmt"
)

func compSwap(arr []int, a int, b int) {
	if arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func sort(arr []int) []int {
	n := len(arr)
	maxVal := 1
	for maxVal*2 < n {
		maxVal *= 2
	}

	next := maxVal
	for next > 0 {
		i := 0
		for i+1 < n {
			compSwap(arr, i, i+1)
			i += 2
		}

		j := maxVal
		for j >= next && j > 1 {
			i = 1
			for i+j-1 < n {
				compSwap(arr, i, i+j-1)
				i += 2
			}
			j /= 2
		}

		next /= 2
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
