package main

import (
	"fmt"
)

func blockRoot(n int) int {
	i := 1
	for i*i < n {
		i *= 2
	}
	return i
}

func multiSwap(arr []int, a, b, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

func rotate(arr []int, a, m, b int) {
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

func selectRange(arr []int, start, end, bLen int) int {
	minIndex := start
	a := start + bLen
	for a < end {
		if arr[a] < arr[minIndex] {
			minIndex = a
		} else if arr[a] == arr[minIndex] && arr[a+bLen-1] < arr[minIndex+bLen-1] {
			minIndex = a
		}
		a += bLen
	}
	return minIndex
}

func blockSelect(arr []int, a, m, b, bLen int) {
	k := a
	j := m
	for k < m && arr[k] <= arr[m] {
		k += bLen
	}
	if k == m {
		return
	}

	i := m
	multiSwap(arr, k, j, bLen)
	k += bLen
	j += bLen

	for k < j && j < b {
		if arr[i] <= arr[j] {
			if k != i {
				multiSwap(arr, k, i, bLen)
			}
			k += bLen
			i = selectRange(arr, maxInt(m, k), j, bLen)
		} else {
			if i == k {
				i = j
			}
			if k != j {
				multiSwap(arr, k, j, bLen)
			}
			k += bLen
			j += bLen
		}
	}

	for k < j {
		i = selectRange(arr, k, b, bLen)
		if k != i {
			multiSwap(arr, k, i, bLen)
		}
		k += bLen
	}
}

func inPlaceMerge(arr []int, a, m, b int) int {
	i := a
	j := m
	for i < j && j < b {
		if arr[i] > arr[j] {
			k := j + 1
			for k < b && arr[i] > arr[k] {
				k++
			}
			rotate(arr, i, j, k)
			i += k - j
			j = k
		} else {
			i++
		}
	}
	return i
}

func inPlaceMergeBW(arr []int, a, m, b int) {
	i := m - 1
	j := b - 1
	for j > i && i >= a {
		if arr[i] > arr[j] {
			k := i - 1
			for k >= a && arr[k] > arr[j] {
				k--
			}
			rotate(arr, k+1, i+1, j+1)
			j -= i - k
			i = k
		} else {
			j--
		}
	}
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	j := 1
	for j < n {
		bLen := blockRoot(j)
		runLength := j
		b := n - n%bLen

		for runLength > 16 {
			i := 0
			for i+j < b {
				k := i
				for k+runLength < minInt(i+2*j, b) {
					blockSelect(arr, k, k+runLength, minInt(k+2*runLength, b), bLen)
					k += runLength
				}
				i += 2 * j
			}
			runLength = bLen
			bLen = blockRoot(bLen)
		}

		i := 0
		for i+j < b {
			k := i
			f := i
			for k+runLength < minInt(i+2*j, b) {
				f = inPlaceMerge(arr, f, k+runLength, minInt(k+2*runLength, b))
				k += runLength
			}
			i += 2 * j
		}

		inPlaceMergeBW(arr, n-n%(2*j), b, n)
		j *= 2
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
