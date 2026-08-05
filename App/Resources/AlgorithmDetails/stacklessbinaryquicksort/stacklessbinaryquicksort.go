package main

import (
	"fmt"
)

func mostSignificantBit(value int) int {
	if value == 0 {
		return -1
	}
	bit := 0
	for (value >> (bit + 1)) != 0 {
		bit++
	}
	return bit
}

func getBit(value, bit int) bool {
	return (value>>bit)&1 == 1
}

func partition(arr []int, lo, hi, bit int) int {
	i := lo - 1
	j := hi
	for {
		i++
		for i < j && !getBit(arr[i], bit) {
			i++
		}
		j--
		for j > i && getBit(arr[j], bit) {
			j--
		}
		if i < j {
			arr[i], arr[j] = arr[j], arr[i]
		} else {
			return i
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n <= 1 {
		return arr
	}

	maxValue := arr[0]
	for _, v := range arr {
		if v > maxValue {
			maxValue = v
		}
	}

	q := mostSignificantBit(maxValue)
	if q < 0 {
		return arr
	}

	m := 0
	i := 0
	b := n

	for i < n {
		p := i
		if b-i >= 1 {
			p = partition(arr, i, b, q)
		}

		if q == 0 {
			m += 2
			for !getBit(m, q+1) {
				q++
			}
			i = b
			for b < n && (arr[b]>>(q+1)) == (m>>(q+1)) {
				b++
			}
		} else {
			b = p
			q--
		}
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
