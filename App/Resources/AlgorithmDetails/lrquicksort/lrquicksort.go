package main

import (
	"fmt"
)

func quickSort(arr []int, p, r int) []int {
	for p < r {
		pivot := arr[p+(r-p+1)/2]
		i, j := p, r
		for i <= j {
			for arr[i] < pivot { i++ }
			for arr[j] > pivot { j-- }
			if i <= j {
				arr[i], arr[j] = arr[j], arr[i]
				i++
				j--
			}
		}
		if j-p < r-i {
			if p < j { quickSort(arr, p, j) }
			p = i
		} else {
			if i < r { quickSort(arr, i, r) }
			r = j
		}
	}
	return arr
}

func sort(arr []int) []int {
	return quickSort(arr, 0, len(arr)-1)
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
