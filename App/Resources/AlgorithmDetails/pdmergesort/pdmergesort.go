package main

import (
	"fmt"
)

func reverseRun(arr []int, lo, hi int) {
	for lo < hi {
		arr[lo], arr[hi] = arr[hi], arr[lo]
		lo++
		hi--
	}
}

// identifyRun finds the maximal run starting at indexIn (every adjacent step
// in the same direction), reversing it in place if that direction was
// descending. It returns the index where the next run starts, or -1 if this
// was the last run.
func identifyRun(arr []int, indexIn, n int) int {
	if indexIn >= n-1 {
		return -1
	}
	startIndex := indexIn
	index := indexIn
	ascending := arr[index] <= arr[index+1]
	index++
	for index < n-1 {
		stepAscending := arr[index] <= arr[index+1]
		if stepAscending != ascending {
			break
		}
		index++
	}
	if !ascending {
		reverseRun(arr, startIndex, index)
	}
	if index >= n-1 {
		return -1
	}
	return index + 1
}

// mergeUp merges arr[start:mid] with arr[mid:end] by copying the left run
// into a scratch buffer and merging forward from the low end.
func mergeUp(arr []int, start, mid, end int, buffer []int) {
	for i := 0; i < mid-start; i++ {
		buffer[i] = arr[start+i]
	}
	bufferPointer := 0
	left := start
	right := mid
	for left < right && right < end {
		if buffer[bufferPointer] <= arr[right] {
			arr[left] = buffer[bufferPointer]
			bufferPointer++
		} else {
			arr[left] = arr[right]
			right++
		}
		left++
	}
	for left < right {
		arr[left] = buffer[bufferPointer]
		bufferPointer++
		left++
	}
}

// mergeDown merges arr[start:mid] with arr[mid:end] by copying the right run
// into a scratch buffer and merging backward from the high end.
func mergeDown(arr []int, start, mid, end int, buffer []int) {
	for i := 0; i < end-mid; i++ {
		buffer[i] = arr[mid+i]
	}
	bufferPointer := end - mid - 1
	left := mid - 1
	right := end - 1
	for right > left && left >= start {
		if buffer[bufferPointer] >= arr[left] {
			arr[right] = buffer[bufferPointer]
			bufferPointer--
		} else {
			arr[right] = arr[left]
			left--
		}
		right--
	}
	for right > left {
		arr[right] = buffer[bufferPointer]
		bufferPointer--
		right--
	}
}

// mergeRuns picks whichever of mergeUp/mergeDown needs the smaller scratch
// copy.
func mergeRuns(arr []int, leftStart, rightStart, end int, buffer []int) {
	if end-rightStart < rightStart-leftStart {
		mergeDown(arr, leftStart, rightStart, end, buffer)
	} else {
		mergeUp(arr, leftStart, rightStart, end, buffer)
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}

	var runs []int
	lastRun := 0
	for lastRun != -1 {
		runs = append(runs, lastRun)
		lastRun = identifyRun(arr, lastRun, n)
	}

	buffer := make([]int, n)
	runCount := len(runs)
	for runCount > 1 {
		i := 0
		for i < runCount-1 {
			end := n
			if i+2 < runCount {
				end = runs[i+2]
			}
			mergeRuns(arr, runs[i], runs[i+1], end, buffer)
			i += 2
		}

		compacted := make([]int, 0, (runCount+1)/2)
		for j := 0; j < runCount; j += 2 {
			compacted = append(compacted, runs[j])
		}
		runs = compacted
		runCount = len(runs)
	}

	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
