package main

import "fmt"

func sort(a []int) []int {
	n := len(a)
	if n < 2 {
		return a
	}
	swapped := true
	for swapped {
		swapped = false
		for i := 0; i+1 < n; i++ {
			if a[i] > a[i+1] {
				a[i], a[i+1] = a[i+1], a[i]
				swapped = true
			}
		}
	}
	return a
}
func main() { array := []int{0, 39, 21, 62, 91, 77, 14, 23}; fmt.Println(sort(array)) }
