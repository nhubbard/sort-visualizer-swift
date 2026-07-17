package main

import (
	"fmt"
)

func siftDown(arr []int, root, size int) {
	for {
		smallest := root
		left := 2*root + 1
		right := 2*root + 2
		if left < size && arr[left] < arr[smallest] {
			smallest = left
		}
		if right < size && arr[right] < arr[smallest] {
			smallest = right
		}
		if smallest == root {
			break
		}
		arr[root], arr[smallest] = arr[smallest], arr[root]
		root = smallest
	}
}

func heapify(arr []int) {
	n := len(arr)
	for i := n/2 - 1; i >= 0; i-- {
		siftDown(arr, i, n)
	}
}

func reverse(arr []int) {
	low, high := 0, len(arr)-1
	for low < high {
		arr[low], arr[high] = arr[high], arr[low]
		low++
		high--
	}
}

func sort(arr []int) []int {
	heapify(arr)
	for end := len(arr) - 1; end > 0; end-- {
		arr[0], arr[end] = arr[end], arr[0]
		siftDown(arr, 0, end)
	}
	reverse(arr)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
