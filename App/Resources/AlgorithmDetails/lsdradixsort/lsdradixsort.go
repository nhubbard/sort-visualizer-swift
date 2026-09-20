package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	maxValue := 0
	for _, value := range arr { if value > maxValue { maxValue = value } }
	output := make([]int, n)
	divisor := 1
	for {
		var counts [4]int
		for _, value := range arr { counts[(value/divisor)%4]++ }
		for digit := 1; digit < 4; digit++ { counts[digit] += counts[digit-1] }
		for i := n-1; i >= 0; i-- {
			digit := (arr[i]/divisor)%4
			counts[digit]--
			output[counts[digit]] = arr[i]
		}
		copy(arr, output)
		if divisor > maxValue/4 { break }
		divisor *= 4
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
