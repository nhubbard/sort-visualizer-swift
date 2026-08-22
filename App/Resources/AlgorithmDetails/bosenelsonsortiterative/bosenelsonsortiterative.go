package main

import (
	"fmt"
)

func compSwap(arr []int, a, b, end int) {
	if b >= end {
		return
	}
	if arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func rangeComp(arr []int, a, b, offset, end int) {
	half := (b - a) / 2
	m := a + half
	base := a + offset
	for i := 0; i < half-offset; i++ {
		if (i &^ offset) == i {
			compSwap(arr, base+i, m+i, end)
		}
	}
}

func sort(arr []int) []int {
	end := len(arr)
	if end <= 1 {
		return arr
	}
	paddedLength := 1
	for paddedLength < end {
		paddedLength <<= 1
	}

	for k := 2; k <= paddedLength; k *= 2 {
		for j := 0; j < k/2; j++ {
			for i := 0; i+j < end; i += k {
				rangeComp(arr, i, i+k, j, end)
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
