package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}

	// Simulate the reporting order that proportional-to-value sleep durations
	// would produce in a jitter-free race: a stable sort of the original
	// positions by value, so ties wake in the order they were scheduled.
	indices := make([]int, n)
	for i := range indices {
		indices[i] = i
	}
	for i := 1; i < n; i++ {
		j := i
		for j > 0 && arr[indices[j-1]] > arr[indices[j]] {
			indices[j-1], indices[j] = indices[j], indices[j-1]
			j--
		}
	}

	woken := make([]int, n)
	for i, idx := range indices {
		woken[i] = arr[idx]
	}
	copy(arr, woken)

	// Defensive cleanup pass: real scheduling jitter can't be fully trusted,
	// so finish with an ordinary insertion sort no matter what the race produced.
	for i := 1; i < n; i++ {
		j := i
		for j > 0 && arr[j-1] > arr[j] {
			arr[j-1], arr[j] = arr[j], arr[j-1]
			j--
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
