package main

import (
	"fmt"
)

const recency = 8
const earlyOutTestAt = 4
const earlyOutDisorderFraction = 0.6

// Branched PDQ fallback, matching the app PDQSortingTemplate.
const insertSortThreshold = 24
const nintherThreshold = 128
const partialInsertSortLimit = 8

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

func partRight(arr []int, begin int, end int) (int, bool) {
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
	for first < last {
		arr[first], arr[last] = arr[last], arr[first]
		first++
		for arr[first] < pivot {
			first++
		}
		last--
		for !(arr[last] < pivot) {
			last--
		}
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

func pdqLoop(arr []int, begin int, end int, badAllowed int) {
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

		pivotPos, alreadyParted := partRight(arr, begin, end)

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

		pdqLoop(arr, begin, pivotPos, badAllowed)
		begin = pivotPos + 1
		leftmost = false
	}
}

func pdqSort(arr []int, begin, end int) {
	if end-begin > 1 {
		pdqLoop(arr, begin, end, pdqLog(end-begin))
	}
}

func sort(arr []int) []int {
	length := len(arr)
	if length < 2 {
		return arr
	}

	dropped := []int{}
	numDroppedInARow := 0
	read := 0
	write := 0
	iteration := 0
	earlyOutStop := length / earlyOutTestAt

	for read < length {
		iteration++
		if iteration == earlyOutStop && float64(len(dropped)) > float64(read)*earlyOutDisorderFraction {
			// Too disordered for the adaptive approach to be worth it: flush what's been
			// dropped so far back into the array and fall back to a plain full sort.
			for _, value := range dropped {
				arr[write] = value
				write++
			}
			dropped = dropped[:0]
			pdqSort(arr, 0, length)
			return arr
		}

		if write == 0 || arr[read] >= arr[write-1] {
			// In order -- keep it.
			arr[write] = arr[read]
			write++
			read++
			numDroppedInARow = 0
		} else if numDroppedInARow == 0 && write >= 2 && arr[read] >= arr[write-2] {
			// Quick undo: the element two back would have accepted this one just fine, so
			// drop the one right before it instead of the new element.
			dropped = append(dropped, arr[write-1])
			arr[write-1] = arr[read]
			read++
		} else if numDroppedInARow < recency {
			dropped = append(dropped, arr[read])
			read++
			numDroppedInARow++
		} else {
			// Accepting something numDroppedInARow elements back made every subsequent
			// element drop -- that accept was a mistake. Undo it, and any other recently
			// accepted elements bigger than the dropped run's maximum.
			dropped = dropped[:len(dropped)-numDroppedInARow]
			read -= numDroppedInARow

			numBacktracked := 1
			write--

			maxOfDropped := arr[read]
			for i := read + 1; i <= read+numDroppedInARow; i++ {
				if arr[i] > maxOfDropped {
					maxOfDropped = arr[i]
				}
			}

			for write >= 1 && maxOfDropped < arr[write-1] {
				write--
				numBacktracked++
			}

			for i := write; i < write+numBacktracked; i++ {
				dropped = append(dropped, arr[i])
			}

			numDroppedInARow = 0
		}
	}

	for offset, value := range dropped {
		arr[write+offset] = value
	}

	pdqSort(arr, write, length)

	// Copy the now-sorted dropped tail before the final backward merge starts overwriting
	// arr[write:] in place.
	buffer := make([]int, len(dropped))
	copy(buffer, arr[write:write+len(dropped)])

	i := len(buffer) - 1
	j := write - 1
	k := length - 1

	for i >= 0 {
		if j < 0 || buffer[i] > arr[j] {
			arr[k] = buffer[i]
			k--
			i--
		} else {
			arr[k] = arr[j]
			k--
			j--
		}
	}

	return arr
}

func main() {
	array := []int{
		0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15,
		21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29,
	}
	fmt.Println(sort(array))
}
