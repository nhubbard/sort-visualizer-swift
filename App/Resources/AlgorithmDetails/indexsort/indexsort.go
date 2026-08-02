package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	minValue := arr[0]
	for _, v := range arr {
		if v < minValue {
			minValue = v
		}
	}

	for i := 0; i < n; i++ {
		cmpCount := 0
		for arr[i]-minValue != i && cmpCount < n {
			j := arr[i] - minValue
			arr[i], arr[j] = arr[j], arr[i]
			cmpCount++
		}
		if cmpCount >= n-1 {
			break
		}
	}
	return arr
}

func main() {
	array := []int{7, 3, 14, 0, 9, 5, 12, 1,
		15, 4, 10, 2, 13, 6, 11, 8}
	fmt.Println(sort(array))
}
