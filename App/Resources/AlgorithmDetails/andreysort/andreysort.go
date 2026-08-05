package main

import (
	"fmt"
)

func swap(arr []int, i int, j int) {
	arr[i], arr[j] = arr[j], arr[i]
}

// selectionSort is the base case below length 12: repeatedly swap the
// minimum of the remaining range to the front.
func selectionSort(arr []int, aIn int, bIn int) {
	a := aIn
	b := bIn
	for b > 1 {
		k := 0
		for i := 1; i < b; i++ {
			if arr[a+k] > arr[a+i] {
				k = i
			}
		}
		swap(arr, a, a+k)
		a++
		b--
	}
}

// aswap is a forward block-swap of l elements.
func aswap(arr []int, arr1In int, arr2In int, lIn int) {
	arr1 := arr1In
	arr2 := arr2In
	l := lIn
	for l > 0 {
		swap(arr, arr1, arr2)
		arr1++
		arr2++
		l--
	}
}

// backmerge merges the two runs ending at arr1/arr2 (lengths l1/l2), working
// backward from their high ends into the trailing buffer that starts right
// after arr2. Returns the count of unplaced left-run elements if the right
// run ran out first (0 otherwise).
func backmerge(arr []int, arr1In int, l1In int, arr2In int, l2In int) int {
	arr1 := arr1In
	l1 := l1In
	arr2 := arr2In
	l2 := l2In
	arr0 := arr2 + l1
	for {
		if arr[arr1] > arr[arr2] {
			swap(arr, arr1, arr0)
			arr1--
			arr0--
			l1--
			if l1 == 0 {
				return 0
			}
		} else {
			swap(arr, arr2, arr0)
			arr2--
			arr0--
			l2--
			if l2 == 0 {
				break
			}
		}
	}
	res := l1
	for {
		swap(arr, arr1, arr0)
		arr1--
		arr0--
		l1--
		if l1 == 0 {
			break
		}
	}
	return res
}

// rmerge merges arr[a..a+l) (as l/r blocks of width r) using the buffer
// arr[a+l..a+l+r): selection-sorts the block leaders, then backmerges each
// selected block into place.
func rmerge(arr []int, a int, l int, r int) {
	i := 0
	for i < l {
		q := i
		j := i + r
		for j < l {
			if arr[a+q] > arr[a+j] {
				q = j
			}
			j += r
		}
		if q != i {
			aswap(arr, a+i, a+q, r)
		}
		if i != 0 {
			aswap(arr, a+l, a+i, r)
			backmerge(arr, a+(l+r-1), r, a+(i-1), r)
		}
		i += r
	}
}

// rbnd computes the block size: roughly sqrt(len), rounded up to a power of two.
func rbnd(lenIn int) int {
	length := lenIn / 2
	k := 0
	i := 1
	for i < length {
		k++
		i *= 2
	}
	length /= k
	k = 1
	for k <= length {
		k *= 2
	}
	return k
}

func msort(arr []int, a int, length int) {
	if length < 12 {
		selectionSort(arr, a, length)
		return
	}

	r := rbnd(length)
	lr := (length/r - 1) * r

	p := 2
	for p <= lr {
		if arr[a+(p-2)] > arr[a+(p-1)] {
			swap(arr, a+(p-2), a+(p-1))
		}
		if (p & 2) != 0 {
			p += 2
			continue
		}

		aswap(arr, a+(p-2), a+p, 2)

		m := length - p
		q := 2
		for {
			q0 := 2 * q
			if q0 > m || (p&q0) != 0 {
				break
			}
			backmerge(arr, a+(p-q-1), q, a+(p+q-1), q)
			q = q0
		}
		backmerge(arr, a+(p+q-1), q, a+(p-q-1), q)
		q1 := q
		q *= 2

		for (q & p) == 0 {
			q *= 2
			rmerge(arr, a+(p-q), q, q1)
		}

		p += 2
	}

	q1 := 0
	q := r
	for q < lr {
		if (lr & q) != 0 {
			q1 += q
			if q1 != q {
				rmerge(arr, a+(lr-q1), q1, r)
			}
		}
		q *= 2
	}

	s0 := length - lr
	msort(arr, a+lr, s0)
	aswap(arr, a, a+lr, s0)
	s := s0 + backmerge(arr, a+(s0-1), s0, a+(lr-1), lr-s0)
	msort(arr, a, s)
}

func sort(arr []int) []int {
	n := len(arr)
	msort(arr, 0, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
