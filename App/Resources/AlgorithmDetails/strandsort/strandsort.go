package main

import (
	"fmt"
)

func mergeTo(arr []int, subList []int, a int, m int, b int) {
	i := 0
	s := m - a
	for i < s && m < b {
		if subList[i] < arr[m] {
			arr[a] = subList[i]
			a++
			i++
		} else {
			arr[a] = arr[m]
			a++
			m++
		}
	}
	for i < s {
		arr[a] = subList[i]
		a++
		i++
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}

	subList := make([]int, n)

	j := n
	k := j
	for j > 0 {
		subList[0] = arr[0]
		k--

		i := 0
		p := 0
		for m := 1; m < j; m++ {
			if arr[m] >= subList[i] {
				i++
				subList[i] = arr[m]
				k--
			} else {
				arr[p] = arr[m]
				p++
			}
		}

		mergeTo(arr, subList, k, j, n)
		j = k
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
