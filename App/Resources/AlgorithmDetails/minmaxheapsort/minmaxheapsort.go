package main

import (
	"fmt"
)

func bitLength(value int) int {
	length := 0
	for value > 0 {
		value >>= 1
		length++
	}
	return length
}

func isMinLevel(index int) bool {
	return bitLength(index+1)%2 == 1
}

func betterThan(a int, b int, minLevel bool) bool {
	if minLevel {
		return a < b
	}
	return a > b
}

func downheap(arr []int, start int, size int) {
	i := start
	for {
		minLevel := isMinLevel(i)
		left := 2*i + 1
		right := 2*i + 2
		if left >= size {
			return
		}
		winner := left
		if right < size && betterThan(arr[right], arr[winner], minLevel) {
			winner = right
		}
		base := 4*i + 3
		for offset := 0; offset < 4; offset++ {
			gc := base + offset
			if gc < size && betterThan(arr[gc], arr[winner], minLevel) {
				winner = gc
			}
		}
		isGrandchild := winner >= base
		extreme := betterThan(arr[winner], arr[i], minLevel)
		if !isGrandchild {
			if extreme {
				arr[i], arr[winner] = arr[winner], arr[i]
			}
			return
		}
		if extreme {
			arr[i], arr[winner] = arr[winner], arr[i]
		} else {
			return
		}
		parent := (winner - 1) / 2
		if minLevel {
			if arr[winner] > arr[parent] {
				arr[parent], arr[winner] = arr[winner], arr[parent]
			}
		} else {
			if arr[winner] < arr[parent] {
				arr[parent], arr[winner] = arr[winner], arr[parent]
			}
		}
		i = winner
	}
}

func heapify(arr []int, length int) {
	for i := (length - 1) / 2; i >= 0; i-- {
		downheap(arr, i, length)
	}
}

func storeMax(arr []int, heapSize int) int {
	if heapSize <= 1 {
		return heapSize
	}
	imax := 1
	if heapSize > 2 && arr[2] > arr[1] {
		imax = 2
	}
	last := heapSize - 1
	arr[imax], arr[last] = arr[last], arr[imax]
	newSize := last
	if imax < newSize {
		downheap(arr, imax, newSize)
	}
	return newSize
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	heapify(arr, n)
	heapSize := n
	for i := 0; i < n-1; i++ {
		heapSize = storeMax(arr, heapSize)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
