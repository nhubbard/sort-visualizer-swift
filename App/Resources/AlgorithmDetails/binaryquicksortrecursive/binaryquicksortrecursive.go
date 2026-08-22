package main

import (
	"fmt"
)

func mostSignificantBit(value int) int {
	if value == 0 {
		return -1
	}
	bit := 0
	for (value >> (bit + 1)) != 0 {
		bit++
	}
	return bit
}

func partition(arr []int, p, r, bit int) int {
	i := p - 1
	j := r + 1
	for {
		i++
		for i <= r && ((arr[i]>>bit)&1) == 0 {
			i++
		}
		j--
		for j >= p && ((arr[j]>>bit)&1) == 1 {
			j--
		}
		if i < j {
			arr[i], arr[j] = arr[j], arr[i]
		} else {
			return j
		}
	}
}

func binaryQuickSortRecursive(arr []int, p, r, bit int) {
	if p < r && bit >= 0 {
		q := partition(arr, p, r, bit)
		binaryQuickSortRecursive(arr, p, q, bit-1)
		binaryQuickSortRecursive(arr, q+1, r, bit-1)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	maxValue := arr[0]
	for i := 1; i < n; i++ {
		if arr[i] > maxValue {
			maxValue = arr[i]
		}
	}
	bit := mostSignificantBit(maxValue)
	binaryQuickSortRecursive(arr, 0, n-1, bit)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
