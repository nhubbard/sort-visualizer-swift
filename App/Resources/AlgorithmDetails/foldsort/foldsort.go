package main

import (
	"fmt"
)

func compSwap(arr []int, a, b, end int) {
	if b < end && arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func halver(arr []int, low, high, end int) {
	for low < high {
		compSwap(arr, low, high, end)
		low++
		high--
	}
}

func sort(arr []int) []int {
	n := len(arr)
	ceilLog := 1
	for (1 << ceilLog) < n {
		ceilLog++
	}
	end := n
	size2 := 1 << ceilLog

	k := size2 >> 1
	for k > 0 {
		i := size2
		for i >= k {
			j := 0
			for j < end {
				halver(arr, j, j+i-1, end)
				j += i
			}
			i >>= 1
		}
		k >>= 1
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
