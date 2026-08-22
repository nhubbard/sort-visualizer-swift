package main

import (
	"fmt"
)

func multiSwap(arr []int, pos int, to int) {
	if to-pos > 0 {
		for i := pos; i < to; i++ {
			arr[i], arr[i+1] = arr[i+1], arr[i]
		}
	} else {
		for i := pos; i > to; i-- {
			arr[i], arr[i-1] = arr[i-1], arr[i]
		}
	}
}

func weaveInsert(arr []int, start int, end int) {
	for j := start; j < end; j++ {
		pos := j
		for pos > start && arr[pos] <= arr[pos-1] {
			arr[pos], arr[pos-1] = arr[pos-1], arr[pos]
			pos--
		}
	}
}

func weaveMerge(arr []int, min int, max int, mid int) {
	target := mid - min
	for i := 1; i <= target; i++ {
		multiSwap(arr, mid+i, min+(i*2)-1)
	}
	weaveInsert(arr, min, max+1)
}

func weaveMergeSort(arr []int, min int, max int) {
	if max-min == 0 {
		return
	} else if max-min == 1 {
		if arr[min] > arr[max] {
			arr[min], arr[max] = arr[max], arr[min]
		}
	} else {
		mid := (min + max) / 2
		weaveMergeSort(arr, min, mid)
		weaveMergeSort(arr, mid+1, max)
		weaveMerge(arr, min, max, mid)
	}
}

func sort(arr []int) []int {
	if len(arr) > 1 {
		weaveMergeSort(arr, 0, len(arr)-1)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
