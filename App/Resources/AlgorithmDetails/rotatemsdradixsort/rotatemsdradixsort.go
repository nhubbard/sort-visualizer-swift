package main

import (
	"fmt"
)

func intPow(base, exponent int) int {
	result := 1
	for i := 0; i < exponent; i++ {
		result *= base
	}
	return result
}

func getDigit(value, place, base int) int {
	return (value / intPow(base, place)) % base
}

func multiSwap(arr []int, a, b, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

func rotateBlocks(arr []int, a, m, b int) {
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

func binSearchDigit(arr []int, a, b, d, place, base int) int {
	for a < b {
		mid := (a + b) / 2
		if getDigit(arr[mid], place, base) >= d {
			b = mid
		} else {
			a = mid + 1
		}
	}
	return a
}

func mergeDigit(arr []int, a, m, b, da, db, place, base int) {
	if b-a < 2 || db-da < 2 {
		return
	}
	dm := (da + db) / 2
	m1 := binSearchDigit(arr, a, m, dm, place, base)
	m2 := binSearchDigit(arr, m, b, dm, place, base)
	rotateBlocks(arr, m1, m, m2)
	newM := m1 + (m2 - m)
	mergeDigit(arr, newM, m2, b, dm, db, place, base)
	mergeDigit(arr, a, m1, newM, da, dm, place, base)
}

func mergeSortDigit(arr []int, a, b, place, base int) {
	if b-a < 2 {
		return
	}
	mid := (a + b) / 2
	mergeSortDigit(arr, a, mid, place, base)
	mergeSortDigit(arr, mid, b, place, base)
	mergeDigit(arr, a, mid, b, 0, base, place, base)
}

// msdRotateSort digit-sorts arr[a:b] in place by place using rotation instead
// of counting buckets, then recurses into every resulting digit bucket one
// place lower -- an ordinary MSD radix sort built entirely out of the LSD
// variant's rotate/binary-search machinery.
func msdRotateSort(arr []int, a, b, place, base int) {
	if b-a < 2 || place < 0 {
		return
	}
	mergeSortDigit(arr, a, b, place, base)
	start := a
	for d := 0; d < base; d++ {
		end := binSearchDigit(arr, start, b, d+1, place, base)
		msdRotateSort(arr, start, end, place-1, base)
		start = end
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	base := 4
	maxValue := arr[0]
	for _, v := range arr {
		if v > maxValue {
			maxValue = v
		}
	}
	highestPlace := 0
	probe := base
	for probe <= maxValue {
		highestPlace++
		probe *= base
	}
	msdRotateSort(arr, 0, n, highestPlace, base)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
