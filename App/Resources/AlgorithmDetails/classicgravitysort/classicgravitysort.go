package main

import (
	"fmt"
)

func classicGravitySort(arr []int) {
	n := len(arr)
	if n == 0 {
		return
	}

	maxValue := arr[0]
	for _, v := range arr {
		if v > maxValue {
			maxValue = v
		}
	}

	transpose := make([]int, maxValue)

	for i := 0; i < n; i++ {
		value := arr[i]
		for j := 0; j < value; j++ {
			transpose[j]++
		}
	}

	for i := 0; i < n; i++ {
		total := 0
		for j := 0; j < maxValue; j++ {
			if transpose[j] > 0 {
				total++
			}
		}
		arr[n-i-1] = total
		for j := 0; j < maxValue; j++ {
			transpose[j]--
		}
	}
}

func sort(arr []int) []int {
	classicGravitySort(arr)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
