package main

import (
	"fmt"
)

func siftDown(arr []int, root int, size int) {
	index := root
	for 2*index+1 < size {
		child := 2*index + 1
		if child+1 < size && arr[child+1] > arr[child] {
			child++
		}
		index = child
	}
	rootValue := arr[root]
	for rootValue > arr[index] {
		index = (index - 1) / 2
	}
	for index != root {
		arr[root], arr[index] = arr[index], arr[root]
		index = (index - 1) / 2
	}
}

func heapify(arr []int, length int) {
	for i := (length - 1) / 2; i >= 0; i-- {
		siftDown(arr, i, length)
	}
}

func findNext(arr []int, size int) {
	hole := 0
	left := 1
	right := 2
	for right < size && !(arr[left] == -1 && arr[right] == -1) {
		if arr[left] == -1 {
			arr[hole], arr[right] = arr[right], arr[hole]
			hole = right
		} else if arr[right] == -1 {
			arr[hole], arr[left] = arr[left], arr[hole]
			hole = left
		} else if arr[right] > arr[left] {
			arr[hole], arr[right] = arr[right], arr[hole]
			hole = right
		} else {
			arr[hole], arr[left] = arr[left], arr[hole]
			hole = left
		}
		left = 2*hole + 1
		right = left + 1
	}
	if left < size && arr[left] != -1 {
		arr[hole], arr[left] = arr[left], arr[hole]
	}
}

func sort(arr []int) []int {
	n := len(arr)
	output := make([]int, n)
	if n <= 1 {
		if n == 1 {
			output[0] = arr[0]
		}
		return output
	}
	heapify(arr, n)
	for i := n - 1; i >= 0; i-- {
		output[i] = arr[0]
		arr[0] = -1
		findNext(arr, n)
	}
	return output
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
