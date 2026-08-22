package main

import (
	"fmt"
)

func compSwap(arr []int, a, b, end int) {
	if b < end && arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func sort(arr []int) []int {
	length := len(arr)
	end := length

	n := 1
	for n < length {
		n <<= 1
	}

	k := n >> 1
	for k > 0 {
		j := 0
		for j < length {
			for i := 0; i < k; i++ {
				compSwap(arr, j+i, j+k+i, end)
			}
			j += k << 1
		}
		k >>= 1
	}

	k = 2
	for k < n {
		m := k >> 1
		for m > 0 {
			j := 0
			for j < length {
				p := m
				for p < ((k - m) << 1) {
					for i := 0; i < m; i++ {
						compSwap(arr, j+p+i, j+p+m+i, end)
					}
					p += m << 1
				}
				j += k << 1
			}
			m >>= 1
		}
		k <<= 1
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
