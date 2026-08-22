package main

import (
	"fmt"
)

func pairOk(arr []int, loops []int, i int) bool {
	a := arr[loops[i]]
	b := arr[loops[i+1]]
	if a < b {
		return true
	}
	if a == b && loops[i] < loops[i+1] {
		return true
	}
	return false
}

func firstFailure(arr []int, loops []int, n int) int {
	i := n - 2
	for i >= 0 && pairOk(arr, loops, i) {
		i -= 1
	}
	return i
}

func sort(arr []int) []int {
	n := len(arr)
	loops := make([]int, n)

	for {
		i := firstFailure(arr, loops, n)
		if i < 0 {
			break
		}
		for pos := 0; pos < n; pos++ {
			if pos >= i && loops[pos] < n-1 {
				loops[pos] += 1
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
	array := []int{0, 39, 21, 62, 91, 14, 23}
	fmt.Println(sort(array))
}
