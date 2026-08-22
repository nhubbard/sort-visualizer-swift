package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	max := arr[0]
	for _, v := range arr {
		if v > max {
			max = v
		}
	}

	counts := make([]int, max+1)
	for _, v := range arr {
		counts[v]++
	}
	for i := 1; i <= max; i++ {
		counts[i] += counts[i-1]
	}

	output := make([]int, n)
	for i := n - 1; i >= 0; i-- {
		counts[arr[i]]--
		output[counts[arr[i]]] = arr[i]
	}

	return output
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
