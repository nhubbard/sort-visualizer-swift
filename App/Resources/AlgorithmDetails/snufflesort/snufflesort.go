package main

import (
	"fmt"
)

func snuffleSort(arr []int, start, stop int) {
	if stop-start+1 >= 2 {
		if arr[start] > arr[stop] {
			arr[start], arr[stop] = arr[stop], arr[start]
		}
		if stop-start+1 >= 3 {
			mid := (stop-start)/2 + start
			iterations := (stop - start + 1) / 2
			for i := 0; i < iterations; i++ {
				snuffleSort(arr, start, mid)
				snuffleSort(arr, mid, stop)
			}
		}
	}
}

func sort(arr []int) []int {
	snuffleSort(arr, 0, len(arr)-1)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23}
	fmt.Println(sort(array))
}
