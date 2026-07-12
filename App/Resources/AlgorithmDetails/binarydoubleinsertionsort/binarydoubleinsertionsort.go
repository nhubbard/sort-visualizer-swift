package main

import "fmt"

func leftBinarySearch(array []int, a, b, val int) int {
	lo, hi := a, b
	for lo < hi {
		mid := lo + (hi-lo)/2
		if val <= array[mid] {
			hi = mid
		} else {
			lo = mid + 1
		}
	}
	return lo
}

func rightBinarySearch(array []int, a, b, val int) int {
	lo, hi := a, b
	for lo < hi {
		mid := lo + (hi-lo)/2
		if val < array[mid] {
			hi = mid
		} else {
			lo = mid + 1
		}
	}
	return lo
}

func insertToLeft(array []int, a, b, temp int) {
	for a > b {
		array[a] = array[a-1]
		a--
	}
	array[b] = temp
}

func insertToRight(array []int, a, b, temp int) {
	for a < b {
		array[a] = array[a+1]
		a++
	}
	array[a] = temp
}

func doubleInsertion(array []int, a, b int) {
	if b-a < 2 {
		return
	}

	j := a + (b-a-2)/2 + 1
	i := a + (b-a-1)/2

	if j > i && array[i] > array[j] {
		array[i], array[j] = array[j], array[i]
	}
	i--
	j++

	for j < b {
		if array[i] > array[j] {
			l := array[j]
			r := array[i]
			m := rightBinarySearch(array, i+1, j, l)
			insertToRight(array, i, m-1, l)
			dest := leftBinarySearch(array, m, j, r)
			insertToLeft(array, j, dest, r)
		} else {
			l := array[i]
			r := array[j]
			m := leftBinarySearch(array, i+1, j, l)
			insertToRight(array, i, m-1, l)
			dest := rightBinarySearch(array, m, j, r)
			insertToLeft(array, j, dest, r)
		}
		i--
		j++
	}
}

func sort(arr []int) {
	if len(arr) > 1 {
		doubleInsertion(arr, 0, len(arr))
	}
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	sort(array)
	fmt.Println(array)
}
