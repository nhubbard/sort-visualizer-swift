package main

import (
	"fmt"
	"math/rand"
)

func isPartitioned(arr []int, start int, pivot int, end int) bool {
	for i := start; i < pivot; i++ {
		if arr[i] > arr[pivot] {
			return false
		}
	}
	for i := pivot + 1; i < end; i++ {
		if arr[pivot] > arr[i] {
			return false
		}
	}
	return true
}

func sort(arr []int, start int, end int) []int {
	if start >= end-1 {
		return arr
	}

	pivot := start

	for !isPartitioned(arr, start, pivot, end) {
		for i := start; i < end; i++ {
			j := i + rand.Intn(end-i)
			if pivot == i {
				pivot = j
			} else if pivot == j {
				pivot = i
			}
			arr[i], arr[j] = arr[j], arr[i]
		}
	}

	sort(arr, start, pivot)
	sort(arr, pivot+1, end)

	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 14, 23}
	fmt.Println(sort(array, 0, len(array)))
}
