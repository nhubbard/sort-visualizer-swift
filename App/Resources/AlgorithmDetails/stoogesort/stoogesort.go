package main

import (
	"fmt"
)

func stoogeSort(arr []int, i, j int) {
	if arr[j] < arr[i] {
		arr[i], arr[j] = arr[j], arr[i]
	}
	if j-i > 1 {
		t := (j - i + 1) / 3
		stoogeSort(arr, i, j-t)
		stoogeSort(arr, i+t, j)
		stoogeSort(arr, i, j-t)
	}
}

func sort(arr []int) []int {
	stoogeSort(arr, 0, len(arr)-1)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
