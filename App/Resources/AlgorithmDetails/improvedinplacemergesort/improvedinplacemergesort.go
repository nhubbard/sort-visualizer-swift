package main

import (
	"fmt"
)

func push(arr []int, p, a, b int) {
	if a == b {
		return
	}
	temp := arr[p]
	arr[p] = arr[a]
	for i := a + 1; i < b; i++ {
		arr[i-1] = arr[i]
	}
	arr[b-1] = temp
}

func merge(arr []int, a, m, b int) {
	i, j := a, m
	for i < m && j < b {
		if arr[i] > arr[j] {
			j++
		} else {
			push(arr, i, m, j)
			i++
		}
	}
	for i < m {
		push(arr, i, m, b)
		i++
	}
}

func mergeSort(arr []int, a, b int) {
	m := a + (b-a)/2
	if b-a > 2 {
		if b-a > 3 {
			mergeSort(arr, a, m)
		}
		mergeSort(arr, m, b)
	}
	merge(arr, a, m, b)
}

func sort(arr []int) []int {
	n := len(arr)
	mergeSort(arr, 0, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
