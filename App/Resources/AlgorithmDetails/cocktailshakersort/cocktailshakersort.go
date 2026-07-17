package main

import (
	"fmt"
)

func cocktailShakerSort(arr []int) []int {
	n := len(arr)
	i := 0
	for i < n/2 {
		sorted := true
		for j := i; j < n-i-1; j++ {
			if arr[j] > arr[j+1] {
				arr[j], arr[j+1] = arr[j+1], arr[j]
				sorted = false
			}
		}
		for j := n - i - 1; j > i; j-- {
			if arr[j] < arr[j-1] {
				arr[j], arr[j-1] = arr[j-1], arr[j]
				sorted = false
			}
		}
		if sorted {
			break
		}
		i++
	}
	return arr
}

func sort(arr []int) []int {
	return cocktailShakerSort(arr)
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
