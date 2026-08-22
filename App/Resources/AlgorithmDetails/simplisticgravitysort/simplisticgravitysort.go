package main

import (
	"fmt"
)

func transferTo(arr []int, aux []int, minValue int, index int) {
	pointer := 0
	for arr[index] > minValue {
		arr[index]--
		aux[pointer]++
		pointer++
	}
}

func transferFrom(arr []int, aux []int, auxLength int, index int) {
	pointer := 0
	for pointer < auxLength && aux[pointer] != 0 {
		arr[index]++
		aux[pointer]--
		pointer++
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n == 0 {
		return arr
	}

	minValue := arr[0]
	maxValue := arr[0]
	for _, v := range arr {
		if v < minValue {
			minValue = v
		}
		if v > maxValue {
			maxValue = v
		}
	}
	auxLength := maxValue - minValue
	aux := make([]int, auxLength)

	for i := 0; i < n; i++ {
		transferTo(arr, aux, minValue, i)
	}
	for i := n - 1; i >= 0; i-- {
		transferFrom(arr, aux, auxLength, i)
	}

	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
