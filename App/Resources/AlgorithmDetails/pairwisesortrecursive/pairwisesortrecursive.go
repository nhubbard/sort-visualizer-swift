package main

import (
	"fmt"
)

func compSwap(arr []int, a, b int) {
	if arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func pairwiseRecursive(arr []int, start, end, gap int) {
	if start == end-gap {
		return
	}
	b := start + gap
	for b < end {
		compSwap(arr, b-gap, b)
		b += 2 * gap
	}

	if ((end-start)/gap)%2 == 0 {
		pairwiseRecursive(arr, start, end, gap*2)
		pairwiseRecursive(arr, start+gap, end+gap, gap*2)
	} else {
		pairwiseRecursive(arr, start, end+gap, gap*2)
		pairwiseRecursive(arr, start+gap, end, gap*2)
	}

	a := 1
	for a < (end-start)/gap {
		a = (a * 2) + 1
	}

	b = start + gap
	for b+gap < end {
		c := a
		for c > 1 {
			c /= 2
			if b+(c*gap) < end {
				compSwap(arr, b, b+(c*gap))
			}
		}
		b += 2 * gap
	}
}

func sort(arr []int) []int {
	pairwiseRecursive(arr, 0, len(arr), 1)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
