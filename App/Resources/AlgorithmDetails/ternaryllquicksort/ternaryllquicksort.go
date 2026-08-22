package main

import (
	"fmt"
)

func compare3(arr []int, a int, b int) int {
	if arr[a] == arr[b] {
		return 0
	}
	if arr[a] > arr[b] {
		return 1
	}
	return -1
}

func selectPivot(arr []int, lo int, hi int) int {
	mid := (lo + hi) / 2
	cLoMid := compare3(arr, lo, mid)
	if cLoMid == 0 {
		return lo
	}
	cLoHi := compare3(arr, lo, hi-1)
	cMidHi := compare3(arr, mid, hi-1)
	if cLoHi == 0 || cMidHi == 0 {
		return hi - 1
	}

	if cLoMid < 0 {
		if cMidHi < 0 {
			return mid
		}
		if cLoHi < 0 {
			return hi - 1
		}
		return lo
	}
	if cMidHi > 0 {
		return mid
	}
	if cLoHi < 0 {
		return lo
	}
	return hi - 1
}

func partitionTernaryLL(arr []int, lo int, hi int) (int, int) {
	p := selectPivot(arr, lo, hi)
	arr[p], arr[hi-1] = arr[hi-1], arr[p]
	pivotIndex := hi - 1

	i := lo
	k := hi - 1

	for j := lo; j < k; j++ {
		cmp := compare3(arr, j, pivotIndex)
		if cmp == 0 {
			k--
			arr[k], arr[j] = arr[j], arr[k]
			j--
		} else if cmp < 0 {
			arr[i], arr[j] = arr[j], arr[i]
			i++
		}
	}

	for s := 0; s < hi-k; s++ {
		arr[i+s], arr[hi-1-s] = arr[hi-1-s], arr[i+s]
	}

	return i, i + (hi - k)
}

func quicksortTernaryLL(arr []int, lo int, hi int) {
	if lo+1 < hi {
		first, second := partitionTernaryLL(arr, lo, hi)
		quicksortTernaryLL(arr, lo, first)
		quicksortTernaryLL(arr, second, hi)
	}
}

func sort(arr []int) []int {
	quicksortTernaryLL(arr, 0, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
