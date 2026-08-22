package main

import (
	"fmt"
)

func compare3(arr []int, a, b int) int {
	if arr[a] == arr[b] {
		return 0
	}
	if arr[a] > arr[b] {
		return 1
	}
	return -1
}

func selectPivot(arr []int, lo, hi int) int {
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

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func quicksortTernaryLR(arr []int, lo, hi int) {
	if hi <= lo {
		return
	}

	piv := selectPivot(arr, lo, hi+1)
	arr[piv], arr[hi] = arr[hi], arr[piv]
	pivotIndex := hi

	i, j := lo, hi-1
	p, q := lo, hi-1

	for {
		var cmp int
		for i <= j {
			cmp = compare3(arr, i, pivotIndex)
			if cmp > 0 {
				break
			}
			if cmp == 0 {
				arr[i], arr[p] = arr[p], arr[i]
				p++
			}
			i++
		}
		for i <= j {
			cmp = compare3(arr, j, pivotIndex)
			if cmp < 0 {
				break
			}
			if cmp == 0 {
				arr[j], arr[q] = arr[q], arr[j]
				q--
			}
			j--
		}
		if i > j {
			break
		}
		arr[i], arr[j] = arr[j], arr[i]
		i++
		j--
	}

	arr[i], arr[hi] = arr[hi], arr[i]

	numLess := i - p
	numGreater := q - j

	j = i - 1
	i = i + 1

	pe := lo + minInt(p-lo, numLess)
	for k := lo; k < pe; k, j = k+1, j-1 {
		arr[k], arr[j] = arr[j], arr[k]
	}

	qe := hi - 1 - minInt(hi-1-q, numGreater-1)
	for k := hi - 1; k > qe; k, i = k-1, i+1 {
		arr[i], arr[k] = arr[k], arr[i]
	}

	quicksortTernaryLR(arr, lo, lo+numLess-1)
	quicksortTernaryLR(arr, hi-numGreater+1, hi)
}

func sort(arr []int) []int {
	quicksortTernaryLR(arr, 0, len(arr)-1)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
