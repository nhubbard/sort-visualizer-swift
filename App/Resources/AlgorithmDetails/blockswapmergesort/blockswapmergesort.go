package main

import (
	"fmt"
)

func multiSwap(arr []int, a, b, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

func min(x, y int) int {
	if x < y {
		return x
	}
	return y
}

func binarySearchMid(arr []int, start, mid, end int) int {
	a := 0
	b := min(mid-start, end-mid)
	m := a + (b-a)/2
	for b > a {
		if arr[mid-m-1] > arr[mid+m] {
			a = m + 1
		} else {
			b = m
		}
		m = a + (b-a)/2
	}
	return m
}

func multiSwapMerge(arr []int, start, mid, end int) {
	m := binarySearchMid(arr, start, mid, end)
	for m > 0 {
		multiSwap(arr, mid-m, mid, m)
		multiSwapMerge(arr, mid, mid+m, end)
		end = mid
		mid -= m
		m = binarySearchMid(arr, start, mid, end)
	}
}

func multiSwapMergeSort(arr []int, a, b int) {
	length := b - a
	j := 1
	for j < length {
		i := a
		for ; i+2*j <= b; i += 2 * j {
			multiSwapMerge(arr, i, i+j, i+2*j)
		}
		if i+j < b {
			multiSwapMerge(arr, i, i+j, b)
		}
		j *= 2
	}
}

func sort(arr []int) []int {
	multiSwapMergeSort(arr, 0, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
