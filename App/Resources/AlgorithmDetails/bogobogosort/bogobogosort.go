package main

import (
	"fmt"
)

// A literal Bogo Bogo Sort re-derives the "is it sorted?" answer through a recursive sort of its
// own, so its real cost grows worse than n! squared -- even a handful of elements can take an
// unreasonable amount of time. To keep this example runnable, the true recursive algorithm below
// is only ever applied to a small leading slice of the array (chaosLimit elements); the rest is
// finished with an ordinary insertion sort, and the two already-sorted pieces are merged back
// together at the end. The random reshuffle is also replaced with a deterministic, never-repeating
// permutation walk, so neither piece can wander into an unbounded random search.
const chaosLimit = 5

// nextPermutation advances arr to its next lexicographic permutation in place. It returns false
// (after resetting arr to its first, fully ascending permutation) once every arrangement has been
// visited -- a deterministic stand-in for "shuffle the array at random".
func nextPermutation(arr []int) bool {
	n := len(arr)
	i := n - 2
	for i >= 0 && arr[i] >= arr[i+1] {
		i--
	}
	if i < 0 {
		for lo, hi := 0, n-1; lo < hi; lo, hi = lo+1, hi-1 {
			arr[lo], arr[hi] = arr[hi], arr[lo]
		}
		return false
	}
	j := n - 1
	for arr[j] <= arr[i] {
		j--
	}
	arr[i], arr[j] = arr[j], arr[i]
	for lo, hi := i+1, n-1; lo < hi; lo, hi = lo+1, hi-1 {
		arr[lo], arr[hi] = arr[hi], arr[lo]
	}
	return true
}

// bogoBogoIsSorted is the heart of the joke: rather than scanning arr once, it decides whether
// arr is sorted by copying it, recursively Bogo-Bogo-sorting the copy's first n - 1 elements with
// this exact same process one level down, reshuffling the whole copy until its last two elements
// land in order, and comparing the result against the original. A match means the copy is now the
// true sorted arrangement of the same values, which is only possible if arr was already sorted.
func bogoBogoIsSorted(arr []int) bool {
	n := len(arr)
	if n <= 1 {
		return true
	}
	cp := make([]int, n)
	copy(cp, arr)
	prefix := make([]int, n-1)
	copy(prefix, cp[:n-1])
	bogoBogoSort(prefix)
	copy(cp[:n-1], prefix)
	candidate := 0
	for cp[n-2] > cp[n-1] {
		cp[candidate], cp[n-1] = cp[n-1], cp[candidate]
		candidate++
		copy(prefix, cp[:n-1])
		bogoBogoSort(prefix)
		copy(cp[:n-1], prefix)
	}
	for k := 0; k < n; k++ {
		if cp[k] != arr[k] {
			return false
		}
	}
	return true
}

func bogoBogoSort(arr []int) {
	for !bogoBogoIsSorted(arr) {
		nextPermutation(arr)
	}
}

func insertionSort(arr []int) {
	for i := 1; i < len(arr); i++ {
		key := arr[i]
		j := i - 1
		for j >= 0 && arr[j] > key {
			arr[j+1] = arr[j]
			j--
		}
		arr[j+1] = key
	}
}

func mergeSorted(a, b []int) []int {
	merged := make([]int, 0, len(a)+len(b))
	i, j := 0, 0
	for i < len(a) && j < len(b) {
		if a[i] <= b[j] {
			merged = append(merged, a[i])
			i++
		} else {
			merged = append(merged, b[j])
			j++
		}
	}
	merged = append(merged, a[i:]...)
	merged = append(merged, b[j:]...)
	return merged
}

func sort(arr []int) []int {
	n := len(arr)
	limit := chaosLimit
	if n < limit {
		limit = n
	}
	chaos := make([]int, limit)
	copy(chaos, arr[:limit])
	rest := make([]int, n-limit)
	copy(rest, arr[limit:])

	bogoBogoSort(chaos) // the real, recursive-check algorithm -- kept tiny on purpose
	insertionSort(rest) // an ordinary fast sort for the rest of the array

	merged := mergeSorted(chaos, rest)
	copy(arr, merged)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
