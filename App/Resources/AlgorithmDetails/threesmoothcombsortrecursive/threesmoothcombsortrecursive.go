package main

import (
	"fmt"
)

func powerOfThree(arr []int, pos, gap, end int) {
	if pos+gap > end {
		return
	}

	powerOfThree(arr, pos, gap*3, end)
	powerOfThree(arr, pos+gap, gap*3, end)
	powerOfThree(arr, pos+2*gap, gap*3, end)

	for i := pos; i+gap < end; i += gap {
		if arr[i] > arr[i+gap] {
			arr[i], arr[i+gap] = arr[i+gap], arr[i]
		}
	}
}

func recursiveComb(arr []int, pos, gap, end int) {
	if pos+gap > end {
		return
	}

	recursiveComb(arr, pos, gap*2, end)
	recursiveComb(arr, pos+gap, gap*2, end)

	powerOfThree(arr, pos, gap, end)
}

func sort(arr []int) []int {
	n := len(arr)
	if n > 1 {
		recursiveComb(arr, 0, 1, n)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
