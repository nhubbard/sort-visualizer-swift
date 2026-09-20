package main

import "fmt"

func sort(a []int) []int {
	n := len(a)
	if n < 2 {
		return a
	}
	scratch := append([]int(nil), a...)
	buffer := append([]int(nil), scratch...)
	var mergeSort func(int, int)
	mergeSort = func(lo, hi int) {
		if hi-lo < 2 {
			return
		}
		mid := lo + (hi-lo)/2
		mergeSort(lo, mid)
		mergeSort(mid, hi)
		left, right, dest := lo, mid, lo
		for left < mid && right < hi {
			if scratch[left] <= scratch[right] {
				buffer[dest] = scratch[left]
				left++
			} else {
				buffer[dest] = scratch[right]
				right++
			}
			dest++
		}
		for left < mid {
			buffer[dest] = scratch[left]
			left++
			dest++
		}
		for right < hi {
			buffer[dest] = scratch[right]
			right++
			dest++
		}
		copy(scratch[lo:hi], buffer[lo:hi])
	}
	mergeSort(0, n)
	copy(a, scratch)
	for i := 1; i < n; i++ {
		for j := i; j > 0 && a[j-1] > a[j]; j-- {
			a[j-1], a[j] = a[j], a[j-1]
		}
	}
	return a
}
func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
