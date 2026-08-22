package main

import (
	"fmt"
)

func sort(arr []int) []int {
	for i := 1; i < len(arr); i++ {
		pos := i
		for pos > 0 && arr[pos-1] > arr[pos] {
			arr[pos-1], arr[pos] = arr[pos], arr[pos-1]
			pos--
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
