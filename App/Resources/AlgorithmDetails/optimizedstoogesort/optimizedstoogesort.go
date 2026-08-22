package main

import (
	"fmt"
)

func forward(arr []int, left, right int) {
	for left < right {
		index := right
		for left < index {
			if arr[left] > arr[index] {
				arr[left], arr[index] = arr[index], arr[left]
			}
			left++
			index--
		}
		left = 0
		right--
	}
}

func backward(arr []int, left, right int) {
	length := right
	for left < right {
		index := left
		for index < right {
			if arr[index] > arr[right] {
				arr[index], arr[right] = arr[right], arr[index]
			}
			index++
			right--
		}
		left++
		right = length
	}
}

func exchange(arr []int, length int) {
	left := 0
	right := length - 1
	for left < right {
		if arr[left] > arr[right] {
			arr[left], arr[right] = arr[right], arr[left]
		}
		left++
		right--
	}

	forward(arr, 0, length-2)
	backward(arr, 1, length-1)
}

func sort(arr []int) []int {
	exchange(arr, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
