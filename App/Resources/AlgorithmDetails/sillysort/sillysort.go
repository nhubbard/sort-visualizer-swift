package main

import (
	"fmt"
)

func sillySort(arr []int, i, j int) {
	if i < j {
		m := i + (j-i)/2
		sillySort(arr, i, m)
		sillySort(arr, m+1, j)
		if arr[i] >= arr[m+1] {
			arr[i], arr[m+1] = arr[m+1], arr[i]
		}
		sillySort(arr, i+1, j)
	}
}

func sort(arr []int) []int {
	sillySort(arr, 0, len(arr)-1)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
