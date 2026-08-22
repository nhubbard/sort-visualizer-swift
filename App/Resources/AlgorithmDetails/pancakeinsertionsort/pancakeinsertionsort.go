package main

import (
	"fmt"
)

// flip reverses arr[0..hi] in place. This is the only move the algorithm ever performs; there
// is no per-element shift anywhere.
func flip(arr []int, hi int) {
	lo := 0
	for lo < hi {
		arr[lo], arr[hi] = arr[hi], arr[lo]
		lo++
		hi--
	}
}

// searchAscending is a monobound binary search: it locates the index within the ascending run
// arr[start:end] at which arr[valueIndex] belongs, using one comparison per halving instead of
// the usual two.
func searchAscending(arr []int, start, end, valueIndex int) int {
	top := end - start
	for top > 1 {
		mid := top / 2
		if arr[valueIndex] <= arr[end-mid] {
			end -= mid
		}
		top -= mid
	}
	if arr[valueIndex] <= arr[end-1] {
		return end - 1
	}
	return end
}

// searchDescending is the mirror image of searchAscending for a descending run arr[start:end].
func searchDescending(arr []int, start, end, valueIndex int) int {
	top := end - start
	for top > 1 {
		mid := top / 2
		if arr[start+mid] > arr[valueIndex] {
			start += mid
		}
		top -= mid
	}
	if arr[start] > arr[valueIndex] {
		return start + 1
	}
	return start
}

// sortFirstThree hand-sorts arr[0:n] for n <= 3 via a small decision tree, reporting whether the
// result runs ascending (true) or descending (false).
func sortFirstThree(arr []int, n int) bool {
	if n < 2 {
		return false
	}
	if arr[0] > arr[1] {
		flip(arr, 1)
	}
	if n > 2 {
		if arr[1] > arr[2] {
			if arr[0] > arr[2] {
				flip(arr, 1)
			} else {
				flip(arr, 2)
				flip(arr, 1)
			}
			return false
		}
		return true
	}
	return true
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}

	ascending := sortFirstThree(arr, n)

	for i := 3; i < n; i++ {
		if ascending {
			if arr[i-1] <= arr[i] {
				// Already fits; the ascending prefix already ends at or below the new element.
				continue
			}
			if arr[0] > arr[i] {
				// The new element is smaller than everything in the prefix -- one flip turns the
				// whole thing, including the new element, into a descending run.
				flip(arr, i-1)
				ascending = false
				continue
			}
			idx := searchAscending(arr, 0, i, i)
			flip(arr, i)
			tail := i - idx
			flip(arr, tail)
			flip(arr, tail-1)
			ascending = false
		} else {
			if arr[i-1] > arr[i] {
				continue
			}
			if arr[0] <= arr[i] {
				flip(arr, i-1)
				ascending = true
				continue
			}
			idx := searchDescending(arr, 0, i, i)
			flip(arr, i)
			tail := i - idx
			flip(arr, tail)
			flip(arr, tail-1)
			ascending = true
		}
	}

	if !ascending {
		flip(arr, n-1)
	}

	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
