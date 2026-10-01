package main

import (
	"fmt"
)

var blockSize = 1

func sort(arr []int) []int {
	blockSize = 1
	for blockSize*blockSize < len(arr) {
		blockSize *= 2
	}
	sqrtSort(arr, 0, len(arr))
	return arr
}

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

func sqrtMerge(arr []int, a, m, b int) {
	if m-a <= blockSize && b-m <= blockSize {
		temp := append([]int(nil), arr[a:b]...)
		i, j := 0, m-a
		for k := a; k < b; k++ {
			if i < m-a && (j == b-a || temp[i] <= temp[j]) {
				arr[k] = temp[i]
				i++
			} else {
				arr[k] = temp[j]
				j++
			}
		}
		return
	}
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
		sqrtMerge(arr, m3+1, m2, b)
	}
	if m1-a > 0 && m3-m1 > 0 {
		sqrtMerge(arr, a, m1, m3)
	}
}

func sqrtSort(arr []int, a, b int) {
	length := b - a
	for start := a; start < b; start += 32 {
		end := start + 32
		if end > b {
			end = b
		}
		for i := start + 1; i < end; i++ {
			value, j := arr[i], i
			for j > start && arr[j-1] > value {
				arr[j] = arr[j-1]
				j--
			}
			arr[j] = value
		}
	}
	for j := 32; j < length; j *= 2 {
		i := a
		for ; i+2*j <= b; i += 2 * j {
			sqrtMerge(arr, i, i+j, i+2*j)
		}
		if i+j < b {
			sqrtMerge(arr, i, i+j, b)
		}
	}
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
