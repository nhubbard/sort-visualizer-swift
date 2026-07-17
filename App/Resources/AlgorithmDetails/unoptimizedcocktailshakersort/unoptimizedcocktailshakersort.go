package main

import (
	"fmt"
)

func unoptimizedCocktailShakerSort(arr []int) []int {
	n := len(arr)
	i := 0
	for i < n/2 {
		for j := i; j < n-i-1; j++ {
			if arr[j] > arr[j+1] {
				arr[j], arr[j+1] = arr[j+1], arr[j]
			}
		}
		for j := n - i - 1; j > i; j-- {
			if arr[j] < arr[j-1] {
				arr[j], arr[j-1] = arr[j-1], arr[j]
			}
		}
		i++
	}
	return arr
}

func sort(arr []int) []int {
	return unoptimizedCocktailShakerSort(arr)
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
