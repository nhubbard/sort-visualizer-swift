package main

import (
	"fmt"
)

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

func swapRange(arr []int, a int, b int, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

// rotate swaps the two adjacent blocks arr[lo:mid] and arr[mid:hi] so their order is
// reversed, using no auxiliary storage: the smaller of the two remaining pieces is
// always swapped whole against an equal-sized piece of the other, which shrinks one
// piece to nothing a little at a time until both are exhausted.
func rotate(arr []int, lo int, mid int, hi int) {
	i, j := mid-lo, hi-mid
	if i == 0 || j == 0 {
		return
	}
	for i != j {
		if i < j {
			swapRange(arr, mid-i, mid+j-i, i)
			j -= i
		} else {
			swapRange(arr, mid-i, mid, j)
			i -= j
		}
	}
	swapRange(arr, mid-i, mid, i)
}

// gallop finds the first index in [lo, hi) whose element is not less than value, by
// doubling the step size until it overshoots and then binary-searching the resulting
// bracket, rather than scanning one element at a time. Assumes arr[lo] < value.
func gallop(arr []int, lo int, hi int, value int) int {
	left := lo
	step := 1
	right := lo + step
	for right < hi && arr[right] < value {
		left = right
		step *= 2
		right = lo + step
	}
	if right > hi {
		right = hi
	}
	for right-left > 1 {
		mid := (left + right) / 2
		if arr[mid] < value {
			left = mid
		} else {
			right = mid
		}
	}
	return right
}

// merge merges the sorted run arr[lo:mid] into the sorted run arr[mid:hi] in place.
// `left` tracks the first not-yet-placed element of the left run, and `right` tracks
// the start of the not-yet-consumed remainder of the right run.
func merge(arr []int, lo int, mid int, hi int) {
	left, right := lo, mid
	for left < right && right < hi {
		if arr[left] <= arr[right] {
			left++
		} else {
			boundary := gallop(arr, right, hi, arr[left])
			rotate(arr, left, right, boundary)
			left += boundary - right
			right = boundary
		}
	}
}

func integerSqrt(n int) int {
	if n < 2 {
		return n
	}
	r := n
	for r*r > n {
		r = (r + n/r) / 2
	}
	for (r+1)*(r+1) <= n {
		r++
	}
	return r
}

func max(a int, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a int, b int) int {
	if a < b {
		return a
	}
	return b
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 16 {
		binaryInsertionSort(arr, 0, n)
		return arr
	}

	blockSize := max(16, integerSqrt(n))
	for low := 0; low < n; low += blockSize {
		binaryInsertionSort(arr, low, min(low+blockSize, n))
	}

	// Merge blocks back to front: the already-sorted run always starts at
	// mergedStart, and each step folds the block immediately before it into that run.
	numBlocks := (n + blockSize - 1) / blockSize
	mergedStart := (numBlocks - 1) * blockSize
	for i := numBlocks - 2; i >= 0; i-- {
		leftStart := i * blockSize
		merge(arr, leftStart, mergedStart, n)
		mergedStart = leftStart
	}
	return arr
}

func main() {
	array := []int{
		55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
		21, 88, 5, 51, 66, 29, 44, 12,
	}
	fmt.Println(sort(array))
}
