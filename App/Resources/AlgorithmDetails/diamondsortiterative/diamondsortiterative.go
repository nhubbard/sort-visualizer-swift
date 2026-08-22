package main

import (
	"fmt"
)

func compSwap(arr []int, a, b int) {
	if arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func sort(arr []int) []int {
	n := len(arr)
	p := 1
	for p < n {
		p *= 2
	}

	m := 4
	for m <= p {
		for k := 0; k < m/2; k++ {
			cnt := k
			if k > m/4 {
				cnt = m/2 - k
			}
			j := 0
			for j < n {
				if j+cnt+1 < n {
					i := j + cnt
					for i+1 < min(n, j+m-cnt) {
						compSwap(arr, i, i+1)
						i += 2
					}
				}
				j += m
			}
		}
		m *= 2
	}
	m /= 2
	for k := 0; k <= m/2; k++ {
		i := k
		for i+1 < min(n, m-k) {
			compSwap(arr, i, i+1)
			i += 2
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
