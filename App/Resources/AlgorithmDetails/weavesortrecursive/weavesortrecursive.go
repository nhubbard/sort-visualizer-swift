package main

import (
	"fmt"
)

func compSwap(arr []int, a, b, end int) {
	if b < end && arr[a] > arr[b] {
		arr[a], arr[b] = arr[b], arr[a]
	}
}

func circle(arr []int, pos, ln, gap, end int) {
	if ln < 2 {
		return
	}
	i := 0
	for 2*i < (ln-1)*gap {
		compSwap(arr, pos+i, pos+(ln-1)*gap-i, end)
		i += gap
	}
	circle(arr, pos, ln/2, gap, end)
	if pos+ln*gap/2 < end {
		circle(arr, pos+ln*gap/2, ln/2, gap, end)
	}
}

func weaveCircle(arr []int, pos, ln, gap, end int) {
	if ln < 2 {
		return
	}
	weaveCircle(arr, pos, ln/2, 2*gap, end)
	weaveCircle(arr, pos+gap, ln/2, 2*gap, end)
	circle(arr, pos, ln, gap, end)
}

func sort(arr []int) []int {
	end := len(arr)
	padded := 1
	for padded < end {
		padded *= 2
	}
	weaveCircle(arr, 0, padded, 1, end)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
