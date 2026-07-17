package main

import (
	"fmt"
)

func binarySearch(arr []int, item int, start int, end int) int {
	lo := start
	hi := end
	for lo < hi {
		mid := lo + (hi-lo)/2
		if item < arr[mid] {
			hi = mid
		} else {
			lo = mid + 1
		}
	}
	return lo
}

func binaryInsertionSort(arr []int, start int, end int) {
	for i := start + 1; i < end; i++ {
		item := arr[i]
		pos := binarySearch(arr, item, start, i)
		j := i
		for j > pos {
			arr[j] = arr[j-1]
			j--
		}
		arr[pos] = item
	}
}

func rebalance(arr []int, temp []int, counts []int, locations []int, spineSize int, batchEnd int) {
	for i := 0; i < spineSize; i++ {
		counts[i+1] = counts[i+1] + counts[i] + 1
	}

	k := 0
	for i := spineSize; i < batchEnd; i++ {
		gap := locations[k]
		position := counts[gap]
		temp[position] = arr[i]
		counts[gap] = position + 1
		k++
	}

	for i := 0; i < spineSize; i++ {
		position := counts[i]
		temp[position] = arr[i]
		counts[i] = position + 1
	}

	for i := 0; i < batchEnd; i++ {
		arr[i] = temp[i]
	}

	binaryInsertionSort(arr, 0, counts[0]-1)
	for i := 0; i < spineSize-1; i++ {
		binaryInsertionSort(arr, counts[i], counts[i+1]-1)
	}
	binaryInsertionSort(arr, counts[spineSize-1], counts[spineSize])

	for i := 0; i < spineSize+2; i++ {
		counts[i] = 0
	}
}

func librarySort(arr []int) {
	n := len(arr)
	if n < 2 {
		return
	}

	rebalanceFactor := 2
	spineSize := 1
	binaryInsertionSort(arr, 0, spineSize)

	maxLevel := spineSize
	for maxLevel*rebalanceFactor < n {
		maxLevel *= rebalanceFactor
	}

	temp := make([]int, n)
	counts := make([]int, maxLevel+2)
	locations := make([]int, n)

	i := spineSize
	k := 0
	for i < n {
		if rebalanceFactor*spineSize == i {
			rebalance(arr, temp, counts, locations, spineSize, i)
			spineSize = i
			k = 0
		}
		gap := binarySearch(arr, arr[i], 0, spineSize)
		counts[gap+1]++
		locations[k] = gap
		k++
		i++
	}
	rebalance(arr, temp, counts, locations, spineSize, n)
}

func sort(arr []int) []int {
	librarySort(arr)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
