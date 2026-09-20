package main

import (
	"fmt"
)

func binarySearch(arr []int, item, start, end int) int {
	low := start
	high := end
	for low < high {
		mid := low + (high-low)/2
		if item < arr[mid] {
			high = mid
		} else {
			low = mid + 1
		}
	}
	return low
}

func sort(arr []int) []int {
	for i := 1; i < len(arr); i++ {
		item := arr[i]
		pos := binarySearch(arr, item, 0, i)
		j := i
		for j > pos {
			arr[j], arr[j-1] = arr[j-1], arr[j]
			j--
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
