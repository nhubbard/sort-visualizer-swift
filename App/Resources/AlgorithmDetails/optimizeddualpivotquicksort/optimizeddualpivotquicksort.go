package main

import (
	"fmt"
)

const insertionThreshold = 24

// Once a range's "between the pivots" middle partition holds more than this fraction of the
// range, it's worth pausing to scan out any elements that exactly equal one of the two pivots
// before recursing into what's left.
const equalElementsMinFraction = 4

func insertionSort(arr []int, low int, high int) {
	// Sorts arr[low..high] in place (both bounds inclusive).
	for i := low + 1; i <= high; i++ {
		key := arr[i]
		j := i - 1
		for j >= low && arr[j] > key {
			arr[j+1] = arr[j]
			j--
		}
		arr[j+1] = key
	}
}

// movePivotDuplicatesOut assumes arr[low..high] holds only values in the closed range
// [pivot1, pivot2]. In a single scan, it moves every element equal to pivot1 to the front and
// every element equal to pivot2 to the back -- a Dutch-national-flag-style three-way
// partition, generalized to two specific target values instead of "less than/greater than a
// pivot". It returns the inclusive bounds of what's left strictly between the two pivots.
func movePivotDuplicatesOut(arr []int, low int, high int, pivot1 int, pivot2 int) (int, int) {
	writeLow := low
	read := low
	writeHigh := high
	for read <= writeHigh {
		if arr[read] == pivot1 {
			arr[read], arr[writeLow] = arr[writeLow], arr[read]
			writeLow++
			read++
		} else if arr[read] == pivot2 {
			arr[read], arr[writeHigh] = arr[writeHigh], arr[read]
			writeHigh--
		} else {
			read++
		}
	}
	return writeLow, writeHigh
}

func optimizedDualPivotQuickSort(arr []int, low int, high int) {
	// Sorts arr[low..high] in place (both bounds inclusive).
	size := high - low + 1
	if size <= insertionThreshold {
		if size > 1 {
			insertionSort(arr, low, high)
		}
		return
	}

	// Sample two candidates roughly a third of the way in from each end and seed the two
	// pivots from them, smaller one first.
	third := size / 3
	pivot1Index := low + third
	pivot2Index := high - third
	if arr[pivot1Index] > arr[pivot2Index] {
		arr[pivot1Index], arr[pivot2Index] = arr[pivot2Index], arr[pivot1Index]
	}
	arr[low], arr[pivot1Index] = arr[pivot1Index], arr[low]
	arr[high], arr[pivot2Index] = arr[pivot2Index], arr[high]
	pivot1 := arr[low]
	pivot2 := arr[high]

	// Single left-to-right scan splitting the interior into three regions: less than pivot1,
	// between the two pivots, and greater than pivot2.
	less := low + 1
	great := high - 1
	k := less
	for k <= great {
		if arr[k] < pivot1 {
			arr[k], arr[less] = arr[less], arr[k]
			less++
		} else if arr[k] > pivot2 {
			for k < great && arr[great] > pivot2 {
				great--
			}
			arr[k], arr[great] = arr[great], arr[k]
			great--
			if arr[k] < pivot1 {
				arr[k], arr[less] = arr[less], arr[k]
				less++
			}
		}
		k++
	}

	// Drop the two pivots into place at the boundaries of their regions.
	less--
	great++
	arr[low], arr[less] = arr[less], arr[low]
	arr[high], arr[great] = arr[great], arr[high]

	// arr[low..less-1] < pivot1, arr[less] == pivot1, arr[less+1..great-1] is the middle
	// region, arr[great] == pivot2, arr[great+1..high] > pivot2.
	optimizedDualPivotQuickSort(arr, low, less-1)
	optimizedDualPivotQuickSort(arr, great+1, high)

	middleLow := less + 1
	middleHigh := great - 1

	if pivot1 != pivot2 && middleHigh >= middleLow {
		middleSize := middleHigh - middleLow + 1
		// Equal-elements optimization: a middle region this large is usually full of values
		// tied to one pivot or the other, which would otherwise get pointlessly
		// re-partitioned by the recursive call below. Shrink it first by scanning out the
		// exact duplicates. They're already correctly positioned relative to the low and
		// high regions -- every pivot1 duplicate is >= everything already sorted into the
		// low region, and every pivot2 duplicate is <= everything already sorted into the
		// high region -- so neither of those two regions needs to be touched again.
		if middleSize > size/equalElementsMinFraction {
			middleLow, middleHigh = movePivotDuplicatesOut(arr, middleLow, middleHigh, pivot1, pivot2)
		}
	}

	if pivot1 != pivot2 && middleHigh >= middleLow {
		optimizedDualPivotQuickSort(arr, middleLow, middleHigh)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	optimizedDualPivotQuickSort(arr, 0, n-1)
	return arr
}

func main() {
	array := []int{
		55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
		21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12,
	}
	fmt.Println(sort(array))
}
