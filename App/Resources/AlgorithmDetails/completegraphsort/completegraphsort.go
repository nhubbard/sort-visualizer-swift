package main

import (
	"fmt"
	"math"
)

func compSwap(arr []int, a int, b int) {
	if arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func split(arr []int, a int, m int, b int) {
	if b-a < 2 {
		return
	}
	c, len1 := 0, (b-a)/2
	odd := (b-a)%2 == 1
	if odd {
		if m-a > b-m {
			c = a
			a++
		} else {
			b--
			c = b
		}
	}
	for s := 0; s < len1; s++ {
		i := a
		for j := s; j < len1; j++ {
			compSwap(arr, i, m+j)
			i++
		}
		for j := 0; j < s; j++ {
			compSwap(arr, i, m+j)
			i++
		}
	}
	if odd {
		if c < m {
			for j := 0; j < len1; j++ {
				compSwap(arr, c, m+j)
			}
		} else {
			for j := 0; j < len1; j++ {
				compSwap(arr, a+j, c)
			}
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)
	d, end := 2, 1<<int(math.Log(float64(n-1))/math.Log(2)+1)
	for d <= end {
		i, dec := 0, 0
		for i < n {
			j := i
			dec += n
			for dec >= d {
				dec -= d
				j++
			}
			k := j
			dec += n
			for dec >= d {
				dec -= d
				k++
			}
			split(arr, i, j, k)
			i = k
		}
		d *= 2
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
