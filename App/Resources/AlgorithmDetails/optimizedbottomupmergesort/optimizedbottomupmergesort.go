package main

import (
	"fmt"
)

const blockSize = 16

func binaryInsertionSort(arr []int, lo int, hi int) {
	for i := lo + 1; i < hi; i++ {
		key := arr[i]
		left, right := lo, i
		for left < right {
			mid := (left + right) / 2
			if arr[mid] <= key {
				left = mid + 1
			} else {
				right = mid
			}
		}
		for j := i; j > left; j-- {
			arr[j] = arr[j-1]
		}
		arr[left] = key
	}
}

func merge(src []int, dst []int, low int, mid int, high int) {
	i, j, k := low, mid, low
	for i < mid && j < high {
		if src[i] <= src[j] {
			dst[k] = src[i]
			i++
		} else {
			dst[k] = src[j]
			j++
		}
		k++
	}
	for i < mid {
		dst[k] = src[i]
		i++
		k++
	}
	for j < high {
		dst[k] = src[j]
		j++
		k++
	}
}

func min(a int, b int) int {
	if a < b {
		return a
	}
	return b
}

func sort(arr []int) []int {
	n := len(arr)
	if n < blockSize {
		binaryInsertionSort(arr, 0, n)
		return arr
	}

	// Pre-pass: sort fixed-size blocks with binary insertion sort so the merge phase can
	// start from already-sorted runs instead of single elements.
	for low := 0; low < n; low += blockSize {
		binaryInsertionSort(arr, low, min(low+blockSize, n))
	}

	// Merge phase: ping-pong between arr and scratch, alternating direction every pass,
	// instead of always merging into scratch and copying the whole buffer back.
	scratch := make([]int, n)
	src, dst := arr, scratch
	passes := 0
	for width := blockSize; width < n; width *= 2 {
		for low := 0; low < n; low += 2 * width {
			mid := min(low+width, n)
			high := min(low+2*width, n)
			if mid < high {
				merge(src, dst, low, mid, high)
			} else {
				copy(dst[low:mid], src[low:mid])
			}
		}
		src, dst = dst, src
		passes++
	}

	// An even number of passes lands the sorted result back in arr on its own; an odd
	// number leaves it in scratch, needing this one explicit copy back.
	if passes%2 == 1 {
		copy(arr, src)
	}
	return arr
}

func main() {
	array := []int{
		81, 14, 3, 94, 35, 31, 28, 17, 94, 13, 86, 94, 69, 11, 75, 54,
		4, 3, 11, 27, 29, 64, 77, 3, 71, 25, 91, 83, 89, 69, 53, 28,
		57, 75, 35, 0, 97, 20, 89, 54,
	}
	fmt.Println(sort(array))
}
