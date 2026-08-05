package main

import (
	"fmt"
)

const radixBase = 10

// digitAt extracts the digit at place (0 = ones place) from value, in radixBase.
func digitAt(value int, place int) int {
	divisor := 1
	for i := 0; i < place; i++ {
		divisor *= radixBase
	}
	return (value / divisor) % radixBase
}

// multiSwap swaps the two equal-length adjacent blocks [a, a+len) and [b, b+len).
func multiSwap(arr []int, a int, b int, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

// rotateBlock rotates the adjacent blocks [a, m) and [m, b) into swapped order in
// place, using only block-swaps -- no auxiliary buffer.
func rotateBlock(arr []int, a int, m int, b int) {
	l := m - a
	r := b - m
	for l > 0 && r > 0 {
		if r < l {
			multiSwap(arr, m-r, m, r)
			b -= r
			m -= r
			l -= r
		} else {
			multiSwap(arr, a, m, l)
			a += l
			m += l
			r -= l
		}
	}
}

// digitLowerBound finds the leftmost index in [a, b) whose digit-place value is
// >= d, assuming [a, b) is already sorted by that digit.
func digitLowerBound(arr []int, a int, b int, d int, place int) int {
	for a < b {
		mid := (a + b) / 2
		if digitAt(arr[mid], place) >= d {
			b = mid
		} else {
			a = mid + 1
		}
	}
	return a
}

// mergeByDigit merges the two adjacent digit-sorted runs [a, m) and [m, b), whose
// digit-place values are known to lie in [da, db), by rotating the below-threshold
// prefixes of both runs together and recursing into the two halves that produces.
func mergeByDigit(arr []int, a int, m int, b int, da int, db int, place int) {
	if b-a < 2 || db-da < 2 {
		return
	}
	dm := (da + db) / 2
	m1 := digitLowerBound(arr, a, m, dm, place)
	m2 := digitLowerBound(arr, m, b, dm, place)
	rotateBlock(arr, m1, m, m2)
	newM := m1 + (m2 - m)
	mergeByDigit(arr, newM, m2, b, dm, db, place)
	mergeByDigit(arr, a, m1, newM, da, dm, place)
}

// digitMergeSort sorts [a, b) by digit-place alone via ordinary merge-sort
// recursion on the index range, merging with mergeByDigit instead of a linear merge.
func digitMergeSort(arr []int, a int, b int, place int) {
	if b-a < 2 {
		return
	}
	mid := (a + b) / 2
	digitMergeSort(arr, a, mid, place)
	digitMergeSort(arr, mid, b, place)
	mergeByDigit(arr, a, mid, b, 0, radixBase, place)
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	maxValue := arr[0]
	for i := 1; i < n; i++ {
		if arr[i] > maxValue {
			maxValue = arr[i]
		}
	}
	maxPlace := 0
	probe := radixBase
	for probe <= maxValue {
		maxPlace++
		probe *= radixBase
	}
	for place := 0; place <= maxPlace; place++ {
		digitMergeSort(arr, 0, n, place)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
