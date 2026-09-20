package main

import "fmt"

func sort(a []int) []int {
	n := len(a)
	if n < 2 {
		return a
	}
	ordered := true
	for i := 1; i < n; i++ {
		if a[i] < a[i-1] {
			ordered = false
			break
		}
	}
	if ordered {
		return a
	}
	reverse := func(lo, hi int) {
		for lo < hi {
			a[lo], a[hi] = a[hi], a[lo]
			lo++
			hi--
		}
	}
	for {
		pivot := n - 2
		for pivot >= 0 && a[pivot] >= a[pivot+1] {
			pivot--
		}
		if pivot < 0 {
			break
		}
		successor := n - 1
		for a[successor] <= a[pivot] {
			successor--
		}
		a[pivot], a[successor] = a[successor], a[pivot]
		reverse(pivot+1, n-1)
	}
	reverse(0, n-1)
	return a
}
func main() { array := []int{0, 39, 21, 62, 91, 77, 14, 23}; fmt.Println(sort(array)) }
