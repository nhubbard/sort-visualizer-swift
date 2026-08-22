package main

import (
	"fmt"
)

func compSwap(arr []int, a, b int) bool {
	if arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
		return true
	}
	return false
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func stoogeSort(arr []int, a, m, b int, merge bool) bool {
	if a >= m {
		return false
	}
	if b-a == 2 {
		return compSwap(arr, a, m)
	}

	lChange := false
	rChange := false

	a2 := (a + a + b) / 3
	b2 := (a + b + b + 2) / 3

	if m < b2 {
		lChange = stoogeSort(arr, a, m, b2, merge)
		if merge {
			rChange = stoogeSort(arr, maxInt(a+b2-m, a2), b2, b, true)
			if rChange {
				stoogeSort(arr, a+b2-m, a2, 2*a2-a, true)
			}
		} else {
			rChange = stoogeSort(arr, a2, b2, b, false)
			if rChange {
				stoogeSort(arr, a, a2, 2*a2-a, true)
			}
		}
	} else {
		rChange = stoogeSort(arr, a2, m, b, merge)
		if rChange {
			stoogeSort(arr, a, a2, a2+b-m, true)
		}
	}

	return lChange || rChange
}

func sort(arr []int) []int {
	stoogeSort(arr, 0, 1, len(arr), false)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
