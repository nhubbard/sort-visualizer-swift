package main

import (
	"fmt"
)

func stableComp(arr []int, key []int, a int, b int) bool {
	if arr[a] > arr[b] {
		return true
	}
	if arr[a] == arr[b] {
		return key[a] > key[b]
	}
	return false
}

func stableSwap(arr []int, key []int, a int, b int) {
	arr[a], arr[b] = arr[b], arr[a]
	key[a], key[b] = key[b], key[a]
}

func medianOfThree(arr []int, key []int, a int, b int) {
	m := a + (b-1-a)/2
	if stableComp(arr, key, a, m) {
		stableSwap(arr, key, a, m)
	}
	if stableComp(arr, key, m, b-1) {
		stableSwap(arr, key, m, b-1)
		if stableComp(arr, key, a, m) {
			return
		}
	}
	stableSwap(arr, key, a, m)
}

func partition(arr []int, key []int, a int, b int, p int) int {
	i := a - 1
	j := b
	for {
		for {
			i++
			if !(i < j && !stableComp(arr, key, i, p)) {
				break
			}
		}
		for {
			j--
			if !(j >= i && stableComp(arr, key, j, p)) {
				break
			}
		}
		if i < j {
			stableSwap(arr, key, i, j)
		} else {
			return j
		}
	}
}

func quickSort(arr []int, key []int, a int, b int) {
	if b-a < 3 {
		if b-a == 2 && stableComp(arr, key, a, a+1) {
			stableSwap(arr, key, a, a+1)
		}
		return
	}
	medianOfThree(arr, key, a, b)
	p := partition(arr, key, a+1, b, a)
	stableSwap(arr, key, a, p)
	quickSort(arr, key, a, p)
	quickSort(arr, key, p+1, b)
}

func sort(arr []int) []int {
	n := len(arr)
	key := make([]int, n)
	for i := 0; i < n; i++ {
		key[i] = i
	}
	quickSort(arr, key, 0, n)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
