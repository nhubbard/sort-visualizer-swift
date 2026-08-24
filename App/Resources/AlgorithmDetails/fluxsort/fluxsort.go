package main

import (
	"fmt"
)

const insertionThreshold = 16

func insertionSort(arr []int, lo int, hi int) {
	for i := lo + 1; i < hi; i++ {
		key := arr[i]
		j := i - 1
		for j >= lo && arr[j] > key {
			arr[j+1] = arr[j]
			j--
		}
		arr[j+1] = key
	}
}

// medianOfThree returns whichever of a, b, c indexes the middle value of the three.
func medianOfThree(arr []int, a int, b int, c int) int {
	if arr[a] > arr[b] {
		a, b = b, a
	}
	if arr[b] > arr[c] {
		b = c
		if arr[a] > arr[b] {
			b = a
		}
	}
	return b
}

func fluxSortRange(arr []int, lo int, hi int, swap []int) {
	n := hi - lo
	if n <= insertionThreshold {
		insertionSort(arr, lo, hi)
		return
	}

	mid := lo + n/2
	pivot := arr[medianOfThree(arr, lo, mid, hi-1)]

	// Partition into arr (elements <= pivot) and swap (elements > pivot). Ties go to the
	// low side, which is what keeps the sort stable.
	lowWrite := lo
	highWrite := 0
	for read := lo; read < hi; read++ {
		value := arr[read]
		if value > pivot {
			swap[highWrite] = value
			highWrite++
		} else {
			arr[lowWrite] = value
			lowWrite++
		}
	}

	for i := 0; i < highWrite; i++ {
		arr[lowWrite+i] = swap[i]
	}

	if lowWrite == hi {
		// Every element in range was <= pivot -- a run of duplicates around the pivot
		// value can cause this. There's no split to recurse into, so finish directly.
		insertionSort(arr, lo, hi)
		return
	}

	fluxSortRange(arr, lo, lowWrite, swap)
	fluxSortRange(arr, lowWrite, hi, swap)
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	swap := make([]int, n)
	fluxSortRange(arr, 0, n, swap)
	return arr
}

func main() {
	array := []int{
		55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97,
		15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12,
	}
	fmt.Println(sort(array))
}
