package main

import (
	"fmt"
)

func quadStooge(arr []int, pos, length int) {
	if length >= 2 && arr[pos] > arr[pos+length-1] {
		arr[pos], arr[pos+length-1] = arr[pos+length-1], arr[pos]
	}
	if length <= 2 {
		return
	}

	len1 := length / 2
	len2 := (length + 1) / 2
	len3 := (len1+1)/2 + (len2+1)/2

	quadStooge(arr, pos, len1)
	quadStooge(arr, pos+len1, len2)
	quadStooge(arr, pos+len1/2, len3)
	quadStooge(arr, pos+len1, len2)
	quadStooge(arr, pos, len1)
	if length > 3 {
		quadStooge(arr, pos+len1/2, len3)
	}
}

func sort(arr []int) []int {
	quadStooge(arr, 0, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
