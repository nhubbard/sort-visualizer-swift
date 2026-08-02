package main

import (
	"fmt"
)

func compSwap(arr []int, a, b, end int) {
	if b < end && arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func pairwiseMerge(arr []int, a, b, end int) {
	m := (a + b) / 2
	m1 := (a + m) / 2
	g := m - m1

	for i := 0; i < m-m1; i++ {
		j := m1
		k := g
		for k > 0 {
			compSwap(arr, j+i, j+i+k, end)
			k >>= 1
			j -= k - (i & k)
		}
	}
	if b-a > 4 {
		pairwiseMerge(arr, m, b, end)
	}
}

func pairwiseMergeSort(arr []int, a, b, end int) {
	m := (a + b) / 2
	i, j := a, m
	for i < m {
		compSwap(arr, i, j, end)
		i++
		j++
	}
	if b-a > 2 {
		pairwiseMergeSort(arr, a, m, end)
		pairwiseMergeSort(arr, m, b, end)
		pairwiseMerge(arr, a, b, end)
	}
}

func sort(arr []int) []int {
	length := len(arr)
	end := length

	n := 1
	for n < length {
		n <<= 1
	}

	pairwiseMergeSort(arr, 0, n, end)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
