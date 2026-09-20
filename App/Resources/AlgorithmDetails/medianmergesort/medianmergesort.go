package main

import "fmt"

func mergeSort(arr, scratch []int, start, end int) {
	if end-start < 2 {
		return
	}
	middle := (start + end) / 2
	mergeSort(arr, scratch, start, middle)
	mergeSort(arr, scratch, middle, end)
	left, right, dest := start, middle, start
	for left < middle && right < end {
		if arr[left] <= arr[right] {
			scratch[dest] = arr[left]
			left++
		} else {
			scratch[dest] = arr[right]
			right++
		}
		dest++
	}
	for left < middle {
		scratch[dest] = arr[left]
		left++
		dest++
	}
	for right < end {
		scratch[dest] = arr[right]
		right++
		dest++
	}
	copy(arr[start:end], scratch[start:end])
}

func sort(arr []int) []int {
	scratch := make([]int, len(arr))
	start, end := 0, len(arr)
	for end-start > 16 {
		x, y, z := arr[start], arr[(start+end-1)/2], arr[end-1]
		if x > y {
			x, y = y, x
		}
		if y > z {
			y, z = z, y
		}
		if x > y {
			y = x
		}
		pivot := y
		left, right := start, end-1
		for left <= right {
			for left <= right && arr[left] < pivot {
				left++
			}
			for left <= right && arr[right] > pivot {
				right--
			}
			if left <= right {
				arr[left], arr[right] = arr[right], arr[left]
				left++
				right--
			}
		}
		if left == start || left == end {
			mergeSort(arr, scratch, start, end)
			return arr
		}
		if left-start <= end-left {
			mergeSort(arr, scratch, start, left)
			start = left
		} else {
			mergeSort(arr, scratch, left, end)
			end = left
		}
	}
	for i := start + 1; i < end; i++ {
		value, j := arr[i], i
		for j > start && arr[j-1] > value {
			arr[j] = arr[j-1]
			j--
		}
		arr[j] = value
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56,
		10, 2, 95, 46, 21, 74, 6, 38}
	fmt.Println(sort(array))
}
