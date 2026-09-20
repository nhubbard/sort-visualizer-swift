package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	loops := make([]int, n)
	for {
		isSorted := true
		for i := 0; i < n-1; i++ {
			a := arr[loops[i]]
			b := arr[loops[i+1]]
			if a < b || (a == b && loops[i] < loops[i+1]) {
				continue
			}
			isSorted = false
			break
		}
		if isSorted {
			break
		}
		for pos := 0; pos < n; pos++ {
			if loops[pos] < n-1 {
				loops[pos]++
				break
			}
			loops[pos] = 0
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
	array := []int{
		0, 39, 21, 62, 14,
	}
	fmt.Println(sort(array))
}
