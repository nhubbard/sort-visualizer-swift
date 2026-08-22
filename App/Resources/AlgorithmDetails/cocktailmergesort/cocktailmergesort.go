package main

import (
	"fmt"
)

func minRunLength(n int) int {
	r := 0
	for n >= 64 {
		r |= n & 1
		n >>= 1
	}
	return n + r
}

func cocktailShakerSort(arr []int, start, end int) {
	length := end - start
	if length <= 1 {
		return
	}
	i := 0
	for i < length/2 {
		isSorted := true
		j := i
		for j < length-i-1 {
			if arr[start+j] > arr[start+j+1] {
				arr[start+j], arr[start+j+1] = arr[start+j+1], arr[start+j]
				isSorted = false
			}
			j++
		}
		j = length - i - 1
		for j > i {
			if arr[start+j-1] > arr[start+j] {
				arr[start+j-1], arr[start+j] = arr[start+j], arr[start+j-1]
				isSorted = false
			}
			j--
		}
		if isSorted {
			break
		}
		i++
	}
}

func merge(arr []int, start, mid, end int) {
	left := append([]int{}, arr[start:mid]...)
	right := append([]int{}, arr[mid:end]...)
	i, j, k := 0, 0, start
	for i < len(left) && j < len(right) {
		if left[i] <= right[j] {
			arr[k] = left[i]
			i++
		} else {
			arr[k] = right[j]
			j++
		}
		k++
	}
	for i < len(left) {
		arr[k] = left[i]
		i++
		k++
	}
	for j < len(right) {
		arr[k] = right[j]
		j++
		k++
	}
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

func cocktailMergeSort(arr []int) {
	n := len(arr)
	if n <= 1 {
		return
	}
	minRun := minRunLength(n)
	if n == minRun {
		cocktailShakerSort(arr, 0, n)
		return
	}
	i := 0
	for i <= n-minRun {
		cocktailShakerSort(arr, i, i+minRun)
		i += minRun
	}
	if i < n {
		cocktailShakerSort(arr, i, n)
	}
	width := minRun
	for width < n {
		i = 0
		for i < n {
			mid := min(i+width, n)
			end := min(i+2*width, n)
			if mid < end {
				merge(arr, i, mid, end)
			}
			i += 2 * width
		}
		width *= 2
	}
}

func sort(arr []int) []int {
	cocktailMergeSort(arr)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
