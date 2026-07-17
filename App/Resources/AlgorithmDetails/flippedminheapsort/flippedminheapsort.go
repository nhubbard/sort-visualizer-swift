package main

import (
	"fmt"
)

func idx(p int, n int) int {
	return n - p
}

func siftDown(arr []int, root int, dist int, n int) {
	for root <= dist/2 {
		leaf := 2 * root
		if leaf < dist && arr[idx(leaf, n)] > arr[idx(leaf+1, n)] {
			leaf += 1
		}
		if arr[idx(root, n)] > arr[idx(leaf, n)] {
			arr[idx(root, n)], arr[idx(leaf, n)] = arr[idx(leaf, n)], arr[idx(root, n)]
			root = leaf
		} else {
			break
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)

	i := n / 2
	for i >= 1 {
		siftDown(arr, i, n, n)
		i -= 1
	}

	i = n
	for i > 1 {
		arr[idx(1, n)], arr[idx(i, n)] = arr[idx(i, n)], arr[idx(1, n)]
		siftDown(arr, 1, i-1, n)
		i -= 1
	}

	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
