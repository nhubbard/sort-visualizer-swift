package main

import (
	"fmt"
	"math/rand"
)

func isMinimum(arr []int, start int, end int) bool {
	for k := start + 1; k < end; k++ {
		if arr[start] > arr[k] {
			return false
		}
	}
	return true
}

func shuffleRange(arr []int, start int, end int) {
	for i := start; i < end-1; i++ {
		j := i + rand.Intn(end-i)
		arr[i], arr[j] = arr[j], arr[i]
	}
}

func sort(arr []int) []int {
	n := len(arr)
	for i := 0; i < n; i++ {
		for !isMinimum(arr, i, n) {
			shuffleRange(arr, i, n)
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23}
	fmt.Println(sort(array))
}
