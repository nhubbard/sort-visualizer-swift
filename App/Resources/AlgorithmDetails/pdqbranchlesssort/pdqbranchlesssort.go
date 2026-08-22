package main

import (
	"fmt"
)

const insertSortThreshold = 24
const nintherThreshold = 128
const partialInsertSortLimit = 8
const blockSize = 64
const cachelineSize = 64

func pdqLog(n int) int {
	log := 0
	for {
		n >>= 1
		if n == 0 {
			break
		}
		log++
	}
	return log
}

// truncDiv divides truncating toward zero. Go's `/` already truncates toward zero for
// negative operands, which is what the pivot-position arithmetic below needs at the one
// call site where the dividend can go negative -- this helper just names that intent.
func truncDiv(a int, b int) int {
	return a / b
}

func insertSort(arr []int, begin int, end int) {
	for cur := begin + 1; cur < end; cur++ {
		if arr[cur] < arr[cur-1] {
			tmp := arr[cur]
			sift := cur
			siftMinusOne := cur - 1
			for {
				arr[sift] = arr[siftMinusOne]
				sift--
				siftMinusOne--
				if sift == begin || !(tmp < arr[siftMinusOne]) {
					break
				}
			}
			arr[sift] = tmp
		}
	}
}

func unguardInsertSort(arr []int, begin int, end int) {
	for cur := begin + 1; cur < end; cur++ {
		if arr[cur] < arr[cur-1] {
			tmp := arr[cur]
			sift := cur
			siftMinusOne := cur - 1
			for {
				arr[sift] = arr[siftMinusOne]
				sift--
				siftMinusOne--
				if !(tmp < arr[siftMinusOne]) {
					break
				}
			}
			arr[sift] = tmp
		}
	}
}

func partialInsertSort(arr []int, begin int, end int) bool {
	limit := 0
	for cur := begin + 1; cur < end; cur++ {
		if limit > partialInsertSortLimit {
			return false
		}
		if arr[cur] < arr[cur-1] {
			tmp := arr[cur]
			sift := cur
			siftMinusOne := cur - 1
			for {
				arr[sift] = arr[siftMinusOne]
				sift--
				siftMinusOne--
				if sift == begin || !(tmp < arr[siftMinusOne]) {
					break
				}
			}
			arr[sift] = tmp
			limit += cur - sift
		}
	}
	return true
}

func sortTwo(arr []int, a int, b int) {
	if arr[b] < arr[a] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func sortThree(arr []int, a int, b int, c int) {
	sortTwo(arr, a, b)
	sortTwo(arr, b, c)
	sortTwo(arr, a, b)
}

func swapOffsets(arr []int, first int, last int, leftOffsets []int, leftPos int, rightOffsets []int, rightPos int, num int, useSwaps bool) {
	if useSwaps {
		for i := 0; i < num; i++ {
			li := first + leftOffsets[leftPos+i]
			ri := last - rightOffsets[rightPos+i]
			arr[li], arr[ri] = arr[ri], arr[li]
		}
	} else if num > 0 {
		left := first + leftOffsets[leftPos]
		right := last - rightOffsets[rightPos]
		tmp := arr[left]
		arr[left] = arr[right]
		for i := 1; i < num; i++ {
			left = first + leftOffsets[leftPos+i]
			arr[right] = arr[left]
			right = last - rightOffsets[rightPos+i]
			arr[left] = arr[right]
		}
		arr[right] = tmp
	}
}

func partRightBranchless(arr []int, begin int, end int, leftOffsets []int, rightOffsets []int) (int, bool) {
	pivot := arr[begin]
	first := begin
	last := end

	first++
	for arr[first] < pivot {
		first++
	}

	if first-1 == begin {
		last--
		for first < last && !(arr[last] < pivot) {
			last--
		}
	} else {
		last--
		for !(arr[last] < pivot) {
			last--
		}
	}

	alreadyParted := first >= last
	if !alreadyParted {
		arr[first], arr[last] = arr[last], arr[first]
		first++
	}

	leftNum, rightNum, leftStart, rightStart := 0, 0, 0, 0

	for last-first > 2*blockSize {
		if leftNum == 0 {
			leftStart = 0
			it := first
			for i := 0; i < blockSize; i++ {
				leftOffsets[leftNum] = i
				if !(arr[it] < pivot) {
					leftNum++
				}
				it++
			}
		}
		if rightNum == 0 {
			rightStart = 0
			it := last
			for i := 0; i < blockSize; i++ {
				it--
				rightOffsets[rightNum] = i + 1
				if arr[it] < pivot {
					rightNum++
				}
			}
		}

		num := leftNum
		if rightNum < num {
			num = rightNum
		}
		swapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets, rightStart, num, leftNum == rightNum)
		leftNum -= num
		rightNum -= num
		leftStart += num
		rightStart += num
		if leftNum == 0 {
			first += blockSize
		}
		if rightNum == 0 {
			last -= blockSize
		}
	}

	leftSize, rightSize := 0, 0
	unknownLeft := (last - first)
	if rightNum != 0 || leftNum != 0 {
		unknownLeft -= blockSize
	}
	if rightNum != 0 {
		leftSize = unknownLeft
		rightSize = blockSize
	} else if leftNum != 0 {
		leftSize = blockSize
		rightSize = unknownLeft
	} else {
		leftSize = truncDiv(unknownLeft, 2)
		rightSize = unknownLeft - leftSize
	}

	if unknownLeft != 0 && leftNum == 0 {
		leftStart = 0
		it := first
		for i := 0; i < leftSize; i++ {
			leftOffsets[leftNum] = i
			if !(arr[it] < pivot) {
				leftNum++
			}
			it++
		}
	}

	if unknownLeft != 0 && rightNum == 0 {
		rightStart = 0
		it := last
		for i := 0; i < rightSize; i++ {
			it--
			rightOffsets[rightNum] = i + 1
			if arr[it] < pivot {
				rightNum++
			}
		}
	}

	num := leftNum
	if rightNum < num {
		num = rightNum
	}
	swapOffsets(arr, first, last, leftOffsets, leftStart, rightOffsets, rightStart, num, leftNum == rightNum)
	leftNum -= num
	rightNum -= num
	leftStart += num
	rightStart += num
	if leftNum == 0 {
		first += leftSize
	}
	if rightNum == 0 {
		last -= rightSize
	}

	leftOffsetsPos := 0
	rightOffsetsPos := 0

	if leftNum != 0 {
		leftOffsetsPos += leftStart
		for leftNum != 0 {
			leftNum--
			last--
			src := first + leftOffsets[leftOffsetsPos+leftNum]
			arr[src], arr[last] = arr[last], arr[src]
		}
		first = last
	}

	if rightNum != 0 {
		rightOffsetsPos += rightStart
		for rightNum != 0 {
			rightNum--
			src := last - rightOffsets[rightOffsetsPos+rightNum]
			arr[src], arr[first] = arr[first], arr[src]
			first++
		}
		last = first
	}

	pivotPos := first - 1
	arr[begin] = arr[pivotPos]
	arr[pivotPos] = pivot

	return pivotPos, alreadyParted
}

func partLeft(arr []int, begin int, end int) int {
	pivot := arr[begin]
	first := begin
	last := end

	last--
	for pivot < arr[last] {
		last--
	}

	if last+1 == end {
		first++
		for first < last && !(pivot < arr[first]) {
			first++
		}
	} else {
		first++
		for !(pivot < arr[first]) {
			first++
		}
	}

	for first < last {
		arr[first], arr[last] = arr[last], arr[first]
		last--
		for pivot < arr[last] {
			last--
		}
		first++
		for !(pivot < arr[first]) {
			first++
		}
	}

	pivotPos := last
	arr[begin] = arr[pivotPos]
	arr[pivotPos] = pivot
	return pivotPos
}

func siftDown(arr []int, begin int, root int, size int) {
	for {
		child := 2*root + 1
		if child >= size {
			break
		}
		if child+1 < size && arr[begin+child] < arr[begin+child+1] {
			child++
		}
		if arr[begin+root] < arr[begin+child] {
			arr[begin+root], arr[begin+child] = arr[begin+child], arr[begin+root]
			root = child
		} else {
			break
		}
	}
}

func heapSort(arr []int, begin int, end int) {
	n := end - begin
	for i := n/2 - 1; i >= 0; i-- {
		siftDown(arr, begin, i, n)
	}
	for i := n - 1; i > 0; i-- {
		arr[begin], arr[begin+i] = arr[begin+i], arr[begin]
		siftDown(arr, begin, 0, i)
	}
}

func pdqLoop(arr []int, begin int, end int, badAllowed int, leftOffsets []int, rightOffsets []int) {
	leftmost := true
	for {
		size := end - begin

		if size < insertSortThreshold {
			if leftmost {
				insertSort(arr, begin, end)
			} else {
				unguardInsertSort(arr, begin, end)
			}
			return
		}

		halfSize := size / 2
		if size > nintherThreshold {
			sortThree(arr, begin, begin+halfSize, end-1)
			sortThree(arr, begin+1, begin+halfSize-1, end-2)
			sortThree(arr, begin+2, begin+halfSize+1, end-3)
			sortThree(arr, begin+halfSize-1, begin+halfSize, begin+halfSize+1)
			arr[begin], arr[begin+halfSize] = arr[begin+halfSize], arr[begin]
		} else {
			sortThree(arr, begin+halfSize, begin, end-1)
		}

		if !leftmost && !(arr[begin-1] < arr[begin]) {
			begin = partLeft(arr, begin, end) + 1
			continue
		}

		pivotPos, alreadyParted := partRightBranchless(arr, begin, end, leftOffsets, rightOffsets)

		leftSize := pivotPos - begin
		rightSize := end - (pivotPos + 1)
		highUnbalance := leftSize < size/8 || rightSize < size/8

		if highUnbalance {
			badAllowed--
			if badAllowed == 0 {
				heapSort(arr, begin, end)
				return
			}

			if leftSize >= insertSortThreshold {
				arr[begin], arr[begin+leftSize/4] = arr[begin+leftSize/4], arr[begin]
				arr[pivotPos-1], arr[pivotPos-leftSize/4] = arr[pivotPos-leftSize/4], arr[pivotPos-1]
				if leftSize > nintherThreshold {
					arr[begin+1], arr[begin+(leftSize/4+1)] = arr[begin+(leftSize/4+1)], arr[begin+1]
					arr[begin+2], arr[begin+(leftSize/4+2)] = arr[begin+(leftSize/4+2)], arr[begin+2]
					arr[pivotPos-2], arr[pivotPos-(leftSize/4+1)] = arr[pivotPos-(leftSize/4+1)], arr[pivotPos-2]
					arr[pivotPos-3], arr[pivotPos-(leftSize/4+2)] = arr[pivotPos-(leftSize/4+2)], arr[pivotPos-3]
				}
			}

			if rightSize >= insertSortThreshold {
				arr[pivotPos+1], arr[pivotPos+(1+rightSize/4)] = arr[pivotPos+(1+rightSize/4)], arr[pivotPos+1]
				arr[end-1], arr[end-rightSize/4] = arr[end-rightSize/4], arr[end-1]
				if rightSize > nintherThreshold {
					arr[pivotPos+2], arr[pivotPos+(2+rightSize/4)] = arr[pivotPos+(2+rightSize/4)], arr[pivotPos+2]
					arr[pivotPos+3], arr[pivotPos+(3+rightSize/4)] = arr[pivotPos+(3+rightSize/4)], arr[pivotPos+3]
					arr[end-2], arr[end-(1+rightSize/4)] = arr[end-(1+rightSize/4)], arr[end-2]
					arr[end-3], arr[end-(2+rightSize/4)] = arr[end-(2+rightSize/4)], arr[end-3]
				}
			}
		} else {
			if alreadyParted && partialInsertSort(arr, begin, pivotPos) && partialInsertSort(arr, pivotPos+1, end) {
				return
			}
		}

		pdqLoop(arr, begin, pivotPos, badAllowed, leftOffsets, rightOffsets)
		begin = pivotPos + 1
		leftmost = false
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	leftOffsets := make([]int, blockSize+cachelineSize)
	rightOffsets := make([]int, blockSize+cachelineSize)
	pdqLoop(arr, 0, n, pdqLog(n), leftOffsets, rightOffsets)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
