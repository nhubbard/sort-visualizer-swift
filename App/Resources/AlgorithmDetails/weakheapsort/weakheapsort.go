package main

import (
	"fmt"
)

func flagBit(b bool) int {
	if b {
		return 1
	}
	return 0
}

func merge(arr []int, flags []bool, i int, j int) {
	if arr[i] < arr[j] {
		flags[j] = !flags[j]
		arr[i], arr[j] = arr[j], arr[i]
	}
}

func sort(arr []int) []int {
	n := len(arr)
	flags := make([]bool, n)

	for i := n - 1; i > 0; i-- {
		j := i
		for (j & 1) == flagBit(flags[j>>1]) {
			j >>= 1
		}
		gparent := j >> 1
		merge(arr, flags, gparent, i)
	}

	for i := n - 1; i > 1; i-- {
		arr[0], arr[i] = arr[i], arr[0]
		x := 1
		for {
			y := 2*x + flagBit(flags[x])
			if y >= i {
				break
			}
			x = y
		}
		for x > 0 {
			merge(arr, flags, 0, x)
			x >>= 1
		}
	}
	arr[0], arr[1] = arr[1], arr[0]
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
