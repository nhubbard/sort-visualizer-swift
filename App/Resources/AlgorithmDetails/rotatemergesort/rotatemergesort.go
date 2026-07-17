package main

import (
	"fmt"
)

func multiSwap(arr []int, a, b, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

func rotate(arr []int, a, m, b int) {
	l, r := m-a, b-m
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

func binarySearch(arr []int, a, b, value int, left bool) int {
	for a < b {
		mid := a + (b-a)/2
		var comp bool
		if left {
			comp = value <= arr[mid]
		} else {
			comp = value < arr[mid]
		}
		if comp {
			b = mid
		} else {
			a = mid + 1
		}
	}
	return a
}

func rotateMerge(arr []int, a, m, b int) {
	var m1, m2, m3 int
	if m-a >= b-m {
		m1 = a + (m-a)/2
		value := arr[m1]
		m2 = binarySearch(arr, m, b, value, true)
		m3 = m1 + (m2 - m)
	} else {
		m2 = m + (b-m)/2
		value := arr[m2]
		m1 = binarySearch(arr, a, m, value, false)
		m3 = m2 - (m - m1)
		m2 = m2 + 1
	}
	rotate(arr, m1, m, m2)
	if m2-(m3+1) > 0 && b-m2 > 0 {
		rotateMerge(arr, m3+1, m2, b)
	}
	if m1-a > 0 && m3-m1 > 0 {
		rotateMerge(arr, a, m1, m3)
	}
}

func rotateMergeSort(arr []int, a, b int) {
	length := b - a
	for j := 1; j < length; j *= 2 {
		i := a
		for ; i+2*j <= b; i += 2 * j {
			rotateMerge(arr, i, i+j, i+2*j)
		}
		if i+j < b {
			rotateMerge(arr, i, i+j, b)
		}
	}
}

func sort(arr []int) []int {
	rotateMergeSort(arr, 0, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
