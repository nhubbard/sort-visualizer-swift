package main

import (
	"fmt"
)

func multiSwap(arr []int, a, b, length int) {
	for i := 0; i < length; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
	}
}

func rotate(arr []int, a, m, b int) {
	l, r := m-a, b-m
	for l > 0 && r > 0 {
		if r < l {
			multiSwap(arr, m-r, m, r)
			b -= r
			m -= r
			l -= r
		} else {
			multiSwap(arr, a, m, l)
			a += l
			m += l
			r -= l
		}
	}
}

func maxInt(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func minInt(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// partitionMerge selects the c smallest combined elements of the two
// already-sorted runs arr[a:m] and arr[m:b] into the front half via a
// single rotation. It uses a merge-path (co-rank) binary search over
// whichever run is shorter: it looks for the split count r such that taking
// r elements from the tail of one run and (c - r) from the head of the
// other yields exactly the c smallest values in order, rather than
// searching for a value directly.
func partitionMerge(arr []int, a, m, b, c int) {
	lenA, lenB := m-a, b-m
	if lenA < 1 || lenB < 1 {
		return
	}

	if lenB < lenA {
		cc := (lenA + lenB) - c
		r1 := maxInt(0, cc-lenA)
		r2 := minInt(cc, lenB)
		for r1 < r2 {
			ml := r1 + (r2-r1)/2
			if arr[m-(cc-ml)] > arr[b-ml-1] {
				r2 = ml
			} else {
				r1 = ml + 1
			}
		}
		rotate(arr, m-(cc-r1), m, b-r1)
	} else {
		r1 := maxInt(0, c-lenB)
		r2 := minInt(c, lenA)
		for r1 < r2 {
			ml := r1 + (r2-r1)/2
			if arr[a+ml] > arr[m+(c-ml)-1] {
				r2 = ml
			} else {
				r1 = ml + 1
			}
		}
		rotate(arr, a+r1, m, m+(c-r1))
	}
}

// rotateMerge finds the first place inside arr[a:b] where ascending order
// breaks, then partition-merges the sorted piece before it with the sorted
// piece after it. A no-op if arr[a:b] is already one ascending run.
func rotateMerge(arr []int, a, b, c int) {
	i := a + 1
	for i < b && arr[i-1] <= arr[i] {
		i++
	}
	if i < b {
		partitionMerge(arr, a, i, b, c)
	}
}

func rotatePartitionMergeSort(arr []int, n int) {
	if n < 2 {
		return
	}

	for i := 1; i < n; i += 2 {
		if arr[i-1] > arr[i] {
			arr[i-1], arr[i] = arr[i], arr[i-1]
		}
	}

	for j := 2; j < n; j *= 2 {
		b1 := 0
		blockStart := 0
		for blockStart+j < n {
			b1 = minInt(blockStart+2*j, n)
			partitionMerge(arr, blockStart, blockStart+j, b1, j)
			blockStart += 2 * j
		}

		for k := j / 2; k > 1; k /= 2 {
			seamStart := 0
			for seamStart+k < b1 {
				seamEnd := minInt(seamStart+2*k, n)
				rotateMerge(arr, seamStart, seamEnd, k)
				seamStart += 2 * k
			}
		}

		for m := 1; m < b1; m += 2 {
			if arr[m-1] > arr[m] {
				arr[m-1], arr[m] = arr[m], arr[m-1]
			}
		}
	}
}

func sort(arr []int) []int {
	rotatePartitionMergeSort(arr, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
