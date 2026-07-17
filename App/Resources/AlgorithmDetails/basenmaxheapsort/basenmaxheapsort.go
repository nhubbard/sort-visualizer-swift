package main

import (
	"fmt"
)

const base = 4

func siftDown(arr []int, node int, stop int) {
	left := node*base + 1
	if left >= stop {
		return
	}
	maxIndex := left
	for i := left + 1; i < left+base && i < stop; i++ {
		if arr[maxIndex] < arr[i] {
			maxIndex = i
		}
	}
	if arr[node] < arr[maxIndex] {
		arr[node], arr[maxIndex] = arr[maxIndex], arr[node]
		siftDown(arr, maxIndex, stop)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	for i := n - 1; i >= 0; i-- {
		siftDown(arr, i, n)
	}
	for end := n - 1; end > 0; end-- {
		arr[0], arr[end] = arr[end], arr[0]
		siftDown(arr, 0, end)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
