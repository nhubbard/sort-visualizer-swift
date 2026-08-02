package main

import (
	"fmt"
)

func stablePartition(arr []int, start int, end int) int {
	pivotValue := arr[start]
	leftList := []int{}
	rightList := []int{}

	for i := start + 1; i <= end; i++ {
		if arr[i] < pivotValue {
			leftList = append(leftList, arr[i])
		} else {
			rightList = append(rightList, arr[i])
		}
	}

	writeIndex := start
	for _, v := range leftList {
		arr[writeIndex] = v
		writeIndex++
	}
	pivotIndex := writeIndex
	arr[writeIndex] = pivotValue
	writeIndex++
	for _, v := range rightList {
		arr[writeIndex] = v
		writeIndex++
	}
	return pivotIndex
}

func stableQuickSort(arr []int, start int, end int) {
	if start < end {
		p := stablePartition(arr, start, end)
		stableQuickSort(arr, start, p-1)
		stableQuickSort(arr, p+1, end)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	stableQuickSort(arr, 0, n-1)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
