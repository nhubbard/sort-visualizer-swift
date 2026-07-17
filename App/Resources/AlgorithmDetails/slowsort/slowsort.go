package main

import (
	"fmt"
)

func slowSort(arr []int, i, j int) {
	if i >= j {
		return
	}
	m := i + (j-i)/2
	slowSort(arr, i, m)
	slowSort(arr, m+1, j)
	if arr[m] > arr[j] {
		arr[m], arr[j] = arr[j], arr[m]
	}
	slowSort(arr, i, j-1)
}

func sort(arr []int) []int {
	slowSort(arr, 0, len(arr)-1)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
