package main

import (
	"fmt"
)

func digitAt(value, divisor, radix int) int {
	return (value / divisor) % radix
}

func flagSort(arr []int, low, high, divisor, radix int) {
	if high-low <= 1 {
		return
	}

	count := make([]int, radix)
	offset := make([]int, radix)

	for i := low; i < high; i++ {
		count[digitAt(arr[i], divisor, radix)]++
	}

	offset[0] = low
	for d := 1; d < radix; d++ {
		offset[d] = offset[d-1] + count[d-1]
	}
	bucketStart := make([]int, radix)
	copy(bucketStart, offset)

	for d := 0; d < radix; d++ {
		for count[d] > 0 {
			origin := offset[d]
			from := origin
			value := arr[from]

			for {
				digit := digitAt(value, divisor, radix)
				dest := offset[digit]
				offset[digit]++
				count[digit]--
				displaced := arr[dest]
				arr[dest] = value
				value = displaced
				from = dest
				if from == origin {
					break
				}
			}
		}
	}

	if divisor > 1 {
		for d := 0; d < radix; d++ {
			begin := bucketStart[d]
			end := offset[d]
			if end-begin > 1 {
				flagSort(arr, begin, end, divisor/radix, radix)
			}
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}

	radix := 10
	maxValue := arr[0]
	for _, v := range arr {
		if v > maxValue {
			maxValue = v
		}
	}

	divisor := 1
	for maxValue/divisor >= radix {
		divisor *= radix
	}

	flagSort(arr, 0, n, divisor, radix)
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
