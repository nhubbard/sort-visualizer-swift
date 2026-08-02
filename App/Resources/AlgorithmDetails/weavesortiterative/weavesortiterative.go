package main

import (
	"fmt"
)

func sort(arr []int) []int {
	end := len(arr)
	padded := 1
	for padded < end {
		padded *= 2
	}

	i := 1
	for i < padded {
		j := 1
		for j <= i {
			k := 0
			for k < padded {
				d := padded / i / 2
				m := 0
				l := padded/j - d
				for l >= padded/j/2 {
					p := 0
					for p < d {
						a := k + m
						b := k + l + p
						if b < end && arr[a] > arr[b] {
							arr[a], arr[b] = arr[b], arr[a]
						}
						p++
						m++
					}
					l -= d
				}
				k += padded / j
			}
			j *= 2
		}
		i *= 2
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
