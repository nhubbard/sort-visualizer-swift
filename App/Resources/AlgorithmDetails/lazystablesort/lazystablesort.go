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
				if len1 == 0 || arr[pos] > arr[pos+len1] {
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
				if len2 == 0 || arr[pos+len1-1] > arr[pos+len1+len2-1] {
					break
				}
			}
		}
	}
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
