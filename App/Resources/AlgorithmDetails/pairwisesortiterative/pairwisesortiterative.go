package main

import (
	"fmt"
)

func sort(arr []int) []int {
	length := len(arr)
	a := 1
	for a < length {
		b := a
		c := 0
		for b < length {
			if arr[b-a] > arr[b] {
				arr[b-a], arr[b] = arr[b], arr[b-a]
			}
			c = (c + 1) % a
			b++
			if c == 0 {
				b += a
			}
		}
		a *= 2
	}

	a /= 4
	e := 1
	for a > 0 {
		d := e
		for d > 0 {
			b := (d + 1) * a
			c := 0
			for b < length {
				if arr[b-(d*a)] > arr[b] {
					arr[b-(d*a)], arr[b] = arr[b], arr[b-(d*a)]
				}
				c = (c + 1) % a
				b++
				if c == 0 {
					b += a
				}
			}
			d /= 2
		}
		a /= 2
		e = (e * 2) + 1
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
