package main

import (
	"fmt"
)

func compSwap(arr []int, start, end int) {
	if arr[start] > arr[end] {
		arr[start], arr[end] = arr[end], arr[start]
	}
}

func merge(arr []int, start1, len1, start2, len2 int) {
	if len1 == 1 && len2 == 1 {
		compSwap(arr, start1, start2)
	} else if len1 == 1 && len2 == 2 {
		compSwap(arr, start1, start2+1)
		compSwap(arr, start1, start2)
	} else if len1 == 2 && len2 == 1 {
		compSwap(arr, start1, start2)
		compSwap(arr, start1+1, start2)
	} else {
		mid1 := len1 / 2
		var mid2 int
		if len1%2 == 1 {
			mid2 = len2 / 2
		} else {
			mid2 = (len2 + 1) / 2
		}
		merge(arr, start1, mid1, start2, mid2)
		merge(arr, start1+mid1, len1-mid1, start2+mid2, len2-mid2)
		merge(arr, start1+mid1, len1-mid1, start2, mid2)
	}
}

func boseNelson(arr []int, start, length int) {
	if length > 1 {
		mid := length / 2
		boseNelson(arr, start, mid)
		boseNelson(arr, start+mid, length-mid)
		merge(arr, start, mid, start+mid, length-mid)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	boseNelson(arr, 0, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
