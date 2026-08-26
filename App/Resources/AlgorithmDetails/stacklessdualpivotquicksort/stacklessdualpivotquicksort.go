package main

import (
	"fmt"
)

const insertionThreshold = 24

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

// partition performs a dual-pivot partition of arr[start:end]. scratch is a fixed index outside
// this range, borrowed briefly as scratch space by the closing rotation and immediately
// restored. It returns the boundary between the low region and everything at or above the
// smaller of the two pivots.
func partition(arr []int, start int, end int, scratch int) int {
	m1 := (start + start + end) / 3
	m2 := (start + end + end) / 3

	if arr[m1] > arr[m2] {
		arr[m1], arr[start] = arr[start], arr[m1]
		end--
		arr[m2], arr[end] = arr[end], arr[m2]
	} else {
		arr[m2], arr[start] = arr[start], arr[m2]
		end--
		arr[m1], arr[end] = arr[end], arr[m1]
	}

	low := start
	high := end
	// Reversed from the usual low/high naming: after the swaps above, start holds the larger of
	// the two chosen medians and end the smaller. Neither position moves again until the
	// closing rotation below, so their values are safe to hold onto directly.
	pivotMax := arr[start]
	pivotMin := arr[end]

	k := low + 1
	for k < high {
		if arr[k] < pivotMin {
			low++
			arr[k], arr[low] = arr[low], arr[k]
		} else if arr[k] >= pivotMax {
			for {
				high--
				if !(high > k && arr[high] >= pivotMax) {
					break
				}
			}
			arr[k], arr[high] = arr[high], arr[k]
			if arr[k] < pivotMin {
				low++
				arr[k], arr[low] = arr[low], arr[k]
			}
		}
		k++
	}

	arr[start], arr[low] = arr[low], arr[start]
	// Three-way rotation: the value at end moves to scratch, whatever was borrowed from scratch
	// moves to high, and whatever was at high moves to end.
	displaced := arr[end]
	arr[end] = arr[high]
	arr[high] = arr[scratch]
	arr[scratch] = displaced

	return low
}

// quickSort sorts arr[start:end] in place with no recursion: a single loop processes one
// segment at a time, shrinking and partitioning it down to insertionThreshold elements,
// finishing with binaryInsertionSort, then advancing past it to the next segment.
func quickSort(arr []int, start int, end int) {
	// Move every copy of this range's maximum value to the very end first. Those elements are
	// already correctly placed relative to everything else, so the rest of the algorithm never
	// has to look at them again -- and the boundary in front of them becomes fixed scratch
	// space partition can borrow from.
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
	// should refresh one of its two candidates, since reusing them would just compare equal
	// again.
	reuseMedianCandidates := true

	for {
		for segmentEnd-a > insertionThreshold {
			if !reuseMedianCandidates {
				m := (a + a + segmentEnd) / 3
				arr[a], arr[m] = arr[m], arr[a]
			}
			segmentEnd = partition(arr, a, segmentEnd, tail)
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

		reuseMedianCandidates = true
		for a < segmentEnd && arr[a-1] == arr[a] {
			reuseMedianCandidates = false
			a++
		}
		if a == segmentEnd {
			reuseMedianCandidates = true
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
