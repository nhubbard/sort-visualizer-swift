package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	for i := n/2 - 1; i >= 0; i-- {
		siftDown(arr, i, n)
	}
	for i := n - 1; i > 0; i-- {
		arr[0], arr[i] = arr[i], arr[0]
		siftDown(arr, 0, i)
	}
	return arr
}

func siftDown(arr []int, root, size int) {
	for {
		largest := root
		left := 2*root + 1
		right := left + 1
		if left < size && arr[largest] < arr[left] {
			largest = left
		}
		if right < size && arr[largest] < arr[right] {
			largest = right
		}
		if largest == root {
			break
		}
		arr[root], arr[largest] = arr[largest], arr[root]
		root = largest
	}
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
