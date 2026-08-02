package main

import (
	"fmt"
)

func intPow(base, exponent int) int {
	result := 1
	for i := 0; i < exponent; i++ {
		result *= base
	}
	return result
}

func getDigit(value, power, radix int) int {
	return (value / intPow(radix, power)) % radix
}

func multiSwap(arr []int, pos, to int) {
	if to > pos {
		for k := pos; k < to; k++ {
			arr[k], arr[k+1] = arr[k+1], arr[k]
		}
	} else if to < pos {
		for k := pos; k > to; k-- {
			arr[k], arr[k-1] = arr[k-1], arr[k]
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n == 0 {
		return arr
	}
	radix := 4
	maxValue := arr[0]
	for _, v := range arr {
		if v > maxValue {
			maxValue = v
		}
	}

	maxPower := 0
	probe := radix
	for probe <= maxValue {
		maxPower++
		probe *= radix
	}

	vregs := make([]int, radix-1)

	for power := 0; power <= maxPower; power++ {
		for i := range vregs {
			vregs[i] = n - 1
		}

		pos := 0
		for step := 0; step < n; step++ {
			digit := getDigit(arr[pos], power, radix)
			if digit == 0 {
				pos++
			} else {
				to := vregs[digit-1]
				multiSwap(arr, pos, to)
				for j := digit - 1; j > 0; j-- {
					vregs[j-1]--
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
