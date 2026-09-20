package main

import (
	"fmt"
	stdsort "sort"
)

func sort(arr []int) []int {
	n := len(arr)
	permutationSort(arr, 0, n)
	return arr
}

func isSorted(arr []int) bool {
	return stdsort.IntsAreSorted(arr)
}

func permutationSort(arr []int, depth int, n int) bool {
	if depth >= n-1 {
		return isSorted(arr)
	}
	for i := n - 1; i > depth; i-- {
		if permutationSort(arr, depth+1, n) {
			return true
		}
		if (n-depth)%2 == 0 {
			arr[depth], arr[i] = arr[i], arr[depth]
		} else {
			arr[depth], arr[n-1] = arr[n-1], arr[depth]
		}
	}
	return permutationSort(arr, depth+1, n)
}

func main() {
	array := []int{
		0, 39, 21, 62, 91, 14, 23,
	}
	fmt.Println(sort(array))
}
