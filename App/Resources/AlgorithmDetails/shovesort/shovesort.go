package main

import (
	"fmt"
)

func sort(arr []int) []int {
	end := len(arr)
	i := 0
	for i < end-1 {
		if arr[i] > arr[i+1] {
			for f := i; f < end-1; f++ {
				arr[f], arr[f+1] = arr[f+1], arr[f]
			}
			if i > 0 {
				i--
			}
			continue
		}
		i++
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
