package main

import (
	"fmt"
)

func stableComp(arr []int, table []int, a int, b int) bool {
	ta := table[a]
	tb := table[b]
	if arr[ta] > arr[tb] {
		return true
	}
	if arr[ta] == arr[tb] {
		return table[a] > table[b]
	}
	return false
}

func medianOfThree(arr []int, table []int, a int, b int) {
	m := a + (b-1-a)/2
	if stableComp(arr, table, a, m) {
		table[a], table[m] = table[m], table[a]
	}
	if stableComp(arr, table, m, b-1) {
		table[m], table[b-1] = table[b-1], table[m]
		if stableComp(arr, table, a, m) {
			return
		}
	}
	table[a], table[m] = table[m], table[a]
}

func partition(arr []int, table []int, a int, b int, p int) int {
	i := a - 1
	j := b
	for {
		for {
			i++
			if !(i < j && !stableComp(arr, table, i, p)) {
				break
			}
		}
		for {
			j--
			if !(j >= i && stableComp(arr, table, j, p)) {
				break
			}
		}
		if i < j {
			table[i], table[j] = table[j], table[i]
		} else {
			return j
		}
	}
}

func quickSort(arr []int, table []int, a int, b int) {
	if b-a < 3 {
		if b-a == 2 && stableComp(arr, table, a, a+1) {
			table[a], table[a+1] = table[a+1], table[a]
		}
		return
	}
	medianOfThree(arr, table, a, b)
	p := partition(arr, table, a+1, b, a)
	table[a], table[p] = table[p], table[a]
	quickSort(arr, table, a, p)
	quickSort(arr, table, p+1, b)
}

func sort(arr []int) []int {
	n := len(arr)
	table := make([]int, n)
	for i := 0; i < n; i++ {
		table[i] = i
	}
	quickSort(arr, table, 0, n)
	for i := 0; i < n; i++ {
		if table[i] != i {
			t := arr[i]
			j := i
			next := table[i]
			for {
				arr[j] = arr[next]
				table[j] = j
				j = next
				next = table[next]
				if next == i {
					break
				}
			}
			arr[j] = t
			table[j] = j
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
