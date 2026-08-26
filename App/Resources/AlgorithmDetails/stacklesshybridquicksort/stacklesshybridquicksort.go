package main

import (
	"fmt"
)

const insertionThreshold = 16

// medianOfThree arranges arr[start], arr[mid], arr[end-1] so the median of the three ends up at
// start, ready to serve as partition's pivot.
func medianOfThree(arr []int, start int, end int) {
	mid := start + (end-1-start)/2
	if arr[start] > arr[mid] {
		arr[start], arr[mid] = arr[mid], arr[start]
	}
	if arr[mid] > arr[end-1] {
		arr[mid], arr[end-1] = arr[end-1], arr[mid]
		if arr[start] > arr[mid] {
			return
		}
	}
	arr[start], arr[mid] = arr[mid], arr[start]
}

// partition performs a classic two-pointer Hoare partition against the pivot medianOfThree just
// placed at start. It returns the pivot's final resting index.
func partition(arr []int, start int, end int) int {
	medianOfThree(arr, start, end)
	pivot := arr[start]
	i, j := start, end

	for {
		i++
		for i < j && arr[i] < pivot {
			i++
		}
		j--
		for j >= i && arr[j] >= pivot {
			j--
		}
		if i < j {
			arr[i], arr[j] = arr[j], arr[i]
		} else {
			arr[start], arr[j] = arr[j], arr[start]
			return j
		}
	}
}

// lowerBoundIndex finds where the value at targetIndex belongs among arr[start:end], ties
// resolving toward the front (a plain lower-bound binary search).
func lowerBoundIndex(arr []int, start int, end int, targetIndex int) int {
	lo, hi := start, end
	for lo < hi {
		mid := lo + (hi-lo)/2
		if arr[targetIndex] <= arr[mid] {
			hi = mid
		} else {
			lo = mid + 1
		}
	}
	return lo
}

// binaryInsertionSort sorts arr[start:end] in place using a plain binary-search insertion sort
// -- the base case once a segment shrinks small enough that further partitioning isn't worth it.
func binaryInsertionSort(arr []int, start int, end int) {
	for i := start; i < end; i++ {
		value := arr[i]
		lo, hi := start, i
		for lo < hi {
			mid := lo + (hi-lo)/2
			if value < arr[mid] {
				hi = mid
			} else {
				lo = mid + 1
			}
		}
		j := i - 1
		for j >= lo {
			arr[j+1] = arr[j]
			j--
		}
		arr[lo] = value
	}
}

// quickSort sorts arr[start:end] in place with no recursion: a single loop processes one
// segment at a time, shrinking and partitioning it down to insertionThreshold elements,
// finishing with binaryInsertionSort, then advancing past it to the next segment.
func quickSort(arr []int, start int, end int) {
	// Move every copy of this range's maximum value to the very end first. Those elements are
	// already correctly placed relative to everything else, so the rest of the algorithm never
	// has to look at them again -- and the boundary in front of them becomes the fixed resting
	// place partition sends each finished pivot out to.
	maxValue := arr[start]
	for i := start + 1; i < end; i++ {
		if arr[i] > maxValue {
			maxValue = arr[i]
		}
	}

	tail := end
	for i := end - 1; i >= start; i-- {
		if arr[i] == maxValue {
			tail--
			arr[i], arr[tail] = arr[tail], arr[i]
		}
	}

	a := start
	segmentEnd := tail
	// False right after skipping a run of duplicates below means the next median-of-three
	// should refresh its candidates, since reusing them would just compare equal again.
	refreshMedian := true

	for {
		for segmentEnd-a > insertionThreshold {
			if refreshMedian {
				medianOfThree(arr, a, segmentEnd)
			}
			pivotIndex := partition(arr, a, segmentEnd)
			arr[pivotIndex], arr[tail] = arr[tail], arr[pivotIndex]
			segmentEnd = pivotIndex
		}

		binaryInsertionSort(arr, a, segmentEnd)

		a = segmentEnd + 1
		if a >= tail {
			if a-1 < tail {
				arr[a-1], arr[tail] = arr[tail], arr[a-1]
			}
			return
		}

		segmentEnd = lowerBoundIndex(arr, a, tail, a-1)
		arr[a-1], arr[tail] = arr[tail], arr[a-1]

		refreshMedian = true
		for a < segmentEnd && arr[a-1] == arr[a] {
			refreshMedian = false
			a++
		}
		if a == segmentEnd {
			refreshMedian = true
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	quickSort(arr, 0, n)
	return arr
}

func main() {
	array := []int{
		55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
		21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
	}
	fmt.Println(sort(array))
}
