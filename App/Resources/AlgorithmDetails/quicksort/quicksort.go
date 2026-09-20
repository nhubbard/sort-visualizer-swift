package main

import (
	"fmt"
)

func sort(arr []int) []int {
	return quickSort(arr, 0, len(arr)-1)
}

func partition(arr []int, left, right int) int {
	i, j := left, right
	for i < j {
		for i < j && arr[i] <= arr[left] {
			i++
		}
		for arr[j] > arr[left] {
			j--
		}
		if i < j {
			arr[i], arr[j] = arr[j], arr[i]
		}
	}
	arr[left], arr[j] = arr[j], arr[left]
	return j
}

func quickSort(arr []int, low, high int) []int {
	if low < high {
		p := partition(arr, low, high)
		arr = quickSort(arr, low, p-1)
		arr = quickSort(arr, p+1, high)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
