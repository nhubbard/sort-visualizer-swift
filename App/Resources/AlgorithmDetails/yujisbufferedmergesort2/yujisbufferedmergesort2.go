package main

import (
	"fmt"
)

func ceilLog(n int) int {
	i := 0
	for (1 << i) < n {
		i++
	}
	return i
}

func multiSwap(arr []int, a, b, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

func insertTo(arr []int, a, b int) {
	temp := arr[a]
	for a > b {
		a--
		arr[a+1] = arr[a]
	}
	arr[b] = temp
}

func binarySearch(arr []int, start, end, value int, left bool) int {
	a := start
	b := end
	for a < b {
		m := a + (b-a)/2
		var comp bool
		if left {
			comp = value <= arr[m]
		} else {
			comp = value < arr[m]
		}
		if comp {
			b = m
		} else {
			a = m + 1
		}
	}
	return a
}

func binaryInsertion(arr []int, a, b int) {
	i := a + 1
	for i < b {
		value := arr[i]
		insertTo(arr, i, binarySearch(arr, a, i, value, false))
		i++
	}
}

func merge(arr []int, a, m, b, p int) int {
	i := a
	j := m
	for i < m && j < b {
		if arr[i] <= arr[j] {
			arr[p], arr[i] = arr[i], arr[p]
			p++
			i++
		} else {
			arr[p], arr[j] = arr[j], arr[p]
			p++
			j++
		}
	}
	leftover := 0
	for i < m {
		arr[p], arr[i] = arr[i], arr[p]
		p++
		i++
	}
	for j < b {
		arr[p], arr[j] = arr[j], arr[p]
		p++
		j++
		leftover++
	}
	return leftover
}

func mergeWithBufStatic(arr []int, a, m, b, p int, useBinarySearch bool) {
	i := 0
	j := m
	k := a
	if useBinarySearch {
		for i < m-a && j < b {
			if arr[j] < arr[p+i] {
				value := arr[p+i]
				q := binarySearch(arr, j, b, value, true)
				for j < q {
					arr[k], arr[j] = arr[j], arr[k]
					k++
					j++
				}
			}
			arr[k], arr[p+i] = arr[p+i], arr[k]
			k++
			i++
		}
		for i < m-a {
			arr[k], arr[p+i] = arr[p+i], arr[k]
			k++
			i++
		}
	} else {
		for i < m-a && j < b {
			if arr[p+i] <= arr[j] {
				arr[k], arr[p+i] = arr[p+i], arr[k]
				k++
				i++
			} else {
				arr[k], arr[j] = arr[j], arr[k]
				k++
				j++
			}
		}
		for i < m-a {
			arr[k], arr[p+i] = arr[p+i], arr[k]
			k++
			i++
		}
	}
}

func mergeSort(arr []int, a, p, length int) {
	j := 16
	ceilLogValue := ceilLog(length)
	pos := a
	if length > 16 && (ceilLogValue&1) == 1 {
		pos = p
	}

	i := pos
	for i+16 <= pos+length {
		binaryInsertion(arr, i, i+16)
		i += 16
	}
	binaryInsertion(arr, i, pos+length)

	nxt := pos
	for j < length {
		pos = nxt
		nxt ^= a ^ p
		posNext := nxt

		i = pos
		for i+2*j <= pos+length {
			merge(arr, i, i+j, i+2*j, posNext)
			i += 2 * j
			posNext += 2 * j
		}
		if i+j < pos+length {
			merge(arr, i, i+j, pos+length, posNext)
		} else {
			for i < pos+length {
				arr[i], arr[posNext] = arr[posNext], arr[i]
				i++
				posNext++
			}
		}
		j *= 2
	}
}

func bufferedMerge(arr []int, a, b int) {
	if b-a <= 16 {
		binaryInsertion(arr, a, b)
		return
	}

	m := (a + b + 1) / 2
	mergeSort(arr, m, 2*m-b, b-m)

	n := (a + m + 1) / 2
	limit := (b - a) / 16
	for m-a > limit {
		mergeSort(arr, 2*n-m, n, m-n)
		mergeWithBufStatic(arr, n, m, b, 2*n-m, (b-m)/(m-n) >= ceilLog(n-a))
		m = n
		n = (a + m + 1) / 2
	}

	bufferedMerge(arr, a, m)
	multiSwap(arr, a, b-(m-a), m-a)
	s := merge(arr, m, b-(m-a), b, a)
	bufferedMerge(arr, b-(m-a)-s, b)
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}
	bufferedMerge(arr, 0, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
