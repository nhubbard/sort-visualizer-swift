package main

import (
	"fmt"
)

func isValid(arr []int, loops []int, n int) bool {
	for i := 0; i < n-1; i++ {
		a := arr[loops[i]]
		b := arr[loops[i+1]]
		if a < b || (a == b && loops[i] < loops[i+1]) {
			continue
		}
		return false
	}
	return true
}

func sort(arr []int) []int {
	n := len(arr)
	loops := make([]int, n)

	for !isValid(arr, loops, n) {
		for pos := 0; pos < n; pos++ {
			if loops[pos] < n-1 {
				loops[pos]++
				break
			} else {
				loops[pos] = 0
			}
		}
	}

	mapped := make([]int, n)
	for i := 0; i < n; i++ {
		mapped[i] = arr[loops[i]]
	}
	for i := 0; i < n; i++ {
		arr[i] = mapped[i]
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 14}
	fmt.Println(sort(array))
}
