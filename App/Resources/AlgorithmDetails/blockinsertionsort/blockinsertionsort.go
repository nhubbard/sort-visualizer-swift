package main

import (
	"fmt"
)

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	i := findRun(arr, 0, n)
	for i < n {
		j := findRun(arr, i, n)
		length := j - i
		if length == 1 {
			insert1(arr, 0, i)
		} else if length == 2 {
			insert2(arr, 0, i, i+1)
		} else {
			mergeWithoutBuffer(arr, 0, i, length)
		}
		i = j
	}
	return arr
}

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

func findRun(arr []int, a int, b int) int {
	i := a + 1
	if i == b {
		return i
	}
	if arr[i-1] > arr[i] {
		i++
		for i < b && arr[i-1] > arr[i] {
			i++
		}
		lo := a
		hi := i - 1
		for lo < hi {
			arr[lo], arr[hi] = arr[hi], arr[lo]
			lo++
			hi--
		}
	} else {
		i++
		for i < b && arr[i-1] <= arr[i] {
			i++
		}
	}
	return i
}

func insert1(arr []int, a int, l int) {
	tmp := arr[l]
	l--
	for l >= a && arr[l] > tmp {
		arr[l+1] = arr[l]
		l--
	}
	arr[l+1] = tmp
}

func insert2(arr []int, a int, l int, r int) {
	tmpL := arr[l]
	tmpR := arr[r]
	l--
	for l >= a && arr[l] > tmpR {
		arr[l+2] = arr[l]
		l--
	}
	arr[l+2] = tmpR
	for l >= a && arr[l] > tmpL {
		arr[l+1] = arr[l]
		l--
	}
	arr[l+1] = tmpL
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
