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
func shiftValue(value, places, base int) int {
	for places > 0 {
		value /= base
		places--
	}
	return value
}

func dist(arr []int, a, b, place, base int) int {
	mergeSortDigit(arr, a, b, place, base)
	return binSearchDigit(arr, a, b, 1, place, base)
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	base, maxValue := 4, 0
	for _, value := range arr {
		if value > maxValue {
			maxValue = value
		}
	}
	q, probe := 0, base
	for probe <= maxValue {
		q++
		probe *= base
	}
	m, i, b := 0, 0, n
	for i < n {
		p := i
		if b-i >= 1 {
			p = dist(arr, i, b, q, base)
		}
		if q == 0 {
			m += base
			t := m / base
			for t%base == 0 {
				t /= base
				q++
			}
			i = b
			for b < n && shiftValue(arr[b], q+1, base) == shiftValue(m, q+1, base) {
				b++
			}
		} else {
			b = p
			q--
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
