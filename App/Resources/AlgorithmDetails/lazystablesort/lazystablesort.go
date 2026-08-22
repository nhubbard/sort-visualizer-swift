package main

import (
	"fmt"
)

func multiSwap(arr []int, a int, b int, count int) {
	for i := 0; i < count; i++ {
		arr[a+i], arr[b+i] = arr[b+i], arr[a+i]
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
	left := 0
	right := length
	for left < right {
		mid := left + (right-left)/2
		var cond bool
		if isLeft {
			cond = arr[pos+mid] < arr[keyPos]
		} else {
			cond = arr[pos+mid] <= arr[keyPos]
		}
		if cond {
			left = mid + 1
		} else {
			right = mid
		}
	}
	return left
}

func mergeWithoutBuffer(arr []int, pos int, len1 int, len2 int) {
	if len1 == 0 || len2 == 0 {
		return
	}
	if len1 == 1 {
		loc := binSearch(arr, pos+1, len2, pos, true)
		rotate(arr, pos, 1, loc)
		return
	}
	if len2 == 1 {
		loc := binSearch(arr, pos, len1, pos+len1, false)
		rotate(arr, pos+loc, len1-loc, 1)
		return
	}
	mid1 := len1 / 2
	loc := binSearch(arr, pos+len1, len2, pos+mid1, true)
	rotate(arr, pos+mid1, len1-mid1, loc)
	mergeWithoutBuffer(arr, pos, mid1, loc)
	mergeWithoutBuffer(arr, pos+mid1+loc, len1-mid1, len2-loc)
}

func sort(arr []int) []int {
	n := len(arr)
	dist := 1
	for dist < n {
		if arr[dist-1] > arr[dist] {
			arr[dist-1], arr[dist] = arr[dist], arr[dist-1]
		}
		dist += 2
	}
	part := 2
	for part < n {
		left := 0
		right := n - 2*part
		for left <= right {
			mergeWithoutBuffer(arr, left, part, part)
			left += 2 * part
		}
		rest := n - left
		if rest > part {
			mergeWithoutBuffer(arr, left, part, rest-part)
		}
		part *= 2
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
