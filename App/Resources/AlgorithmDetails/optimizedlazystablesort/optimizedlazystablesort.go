package main

import (
	"fmt"
)

func swap(arr []int, a int, b int) {
	arr[a], arr[b] = arr[b], arr[a]
}

func multiSwap(arr []int, a int, b int, count int) {
	for i := 0; i < count; i++ {
		swap(arr, a+i, b+i)
	}
}

func rotate(arr []int, pos int, lenA int, lenB int) {
	for lenA != 0 && lenB != 0 {
		if lenA <= lenB {
			multiSwap(arr, pos, pos+lenA, lenA)
			pos += lenA
			lenB -= lenA
		} else {
			multiSwap(arr, pos+(lenA-lenB), pos+lenA, lenB)
			lenA -= lenB
		}
	}
}

func binSearch(arr []int, pos int, length int, keyPos int, isLeft bool) int {
	left := -1
	right := length
	key := arr[keyPos]
	for left < right-1 {
		mid := left + (right-left)/2
		var cond bool
		if isLeft {
			cond = arr[pos+mid] >= key
		} else {
			cond = arr[pos+mid] > key
		}
		if cond {
			right = mid
		} else {
			left = mid
		}
	}
	return right
}

func mergeWithoutBuffer(arr []int, pos int, len1 int, len2 int) {
	if len1 == 0 || len2 == 0 {
		return
	}
	if len1 < len2 {
		for len1 != 0 {
			loc := binSearch(arr, pos+len1, len2, pos, true)
			if loc != 0 {
				rotate(arr, pos, len1, loc)
				pos += loc
				len2 -= loc
			}
			if len2 == 0 {
				break
			}
			for {
				pos++
				len1--
				if !(len1 != 0 && arr[pos] <= arr[pos+len1]) {
					break
				}
			}
		}
	} else {
		for len2 != 0 {
			loc := binSearch(arr, pos, len1, pos+len1+len2-1, false)
			if loc != len1 {
				rotate(arr, pos+loc, len1-loc, len2)
				len1 = loc
			}
			if len1 == 0 {
				break
			}
			for {
				len2--
				if !(len2 != 0 && arr[pos+len1-1] <= arr[pos+len1+len2-1]) {
					break
				}
			}
		}
	}
}

// Guard: a chunk of length <= 1 has nothing to compare. ArrayV's own source skips this
// check and unconditionally reads arr[a] / arr[a + 1], which crashes whenever chunking
// leaves a trailing 1-element chunk (e.g. n = 17 leaves a final [16, 17) chunk).
func insertionSortChunk(arr []int, a int, b int) {
	if b-a <= 1 {
		return
	}
	i := a + 1
	descending := arr[i-1] > arr[i]
	i++
	if descending {
		for i < b && arr[i-1] > arr[i] {
			i++
		}
		lo, hi := a, i-1
		for lo < hi {
			swap(arr, lo, hi)
			lo++
			hi--
		}
	} else {
		for i < b && arr[i-1] <= arr[i] {
			i++
		}
	}
	for i < b {
		current := arr[i]
		pos := i - 1
		for pos >= a && arr[pos] > current {
			arr[pos+1] = arr[pos]
			pos--
		}
		arr[pos+1] = current
		i++
	}
}

func lazyStableSort(arr []int, pos int, length int) {
	dist := 0
	for dist+16 < length {
		insertionSortChunk(arr, pos+dist, pos+dist+16)
		dist += 16
	}
	if dist < length {
		insertionSortChunk(arr, pos+dist, pos+length)
	}

	part := 16
	for part < length {
		left := 0
		right := length - 2*part
		for left <= right {
			mergeWithoutBuffer(arr, pos+left, part, part)
			left += 2 * part
		}
		rest := length - left
		if rest > part {
			mergeWithoutBuffer(arr, pos+left, part, rest-part)
		}
		part *= 2
	}
}

func sort(arr []int) []int {
	n := len(arr)
	lazyStableSort(arr, 0, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
