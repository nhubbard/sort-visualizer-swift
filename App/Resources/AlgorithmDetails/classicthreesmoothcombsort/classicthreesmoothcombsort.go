package main

import (
	"fmt"
)

func is3Smooth(n int) bool {
	for n%6 == 0 {
		n /= 6
	}
	for n%3 == 0 {
		n /= 3
	}
	for n%2 == 0 {
		n /= 2
	}
	return n == 1
}

func sort(arr []int) []int {
	length := len(arr)
	for g := length - 1; g > 0; g-- {
		if is3Smooth(g) {
			for i := g; i < length; i++ {
				if arr[i-g] > arr[i] {
					arr[i-g], arr[i] = arr[i], arr[i-g]
				}
			}
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
