package main

import (
	"fmt"
)

const radix = 4

func getDigit(value int, place int) int {
	for p := 0; p < place; p++ {
		value /= radix
	}
	return value % radix
}

func shift(value int, places int) int {
	for p := 0; p < places; p++ {
		value /= radix
	}
	return value
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}

	q := 0
	probe := radix
	maxValue := arr[0]
	for _, v := range arr {
		if v > maxValue {
			maxValue = v
		}
	}
	for probe <= maxValue {
		q++
		probe *= radix
	}

	counts := make([]int, radix)
	offsets := make([]int, radix)

	bump := func(digit int) {
		counts[digit]++
	}

	// Turns the raw per-bucket counts already accumulated in `counts` into
	// starting offsets, then places every element in [start, end) by
	// following displacement cycles, one bucket at a time.
	distribute := func(start int, end int, place int) int {
		for i := 1; i < radix; i++ {
			counts[i] += counts[i-1]
			offsets[i] = counts[i-1]
		}

		for bucket := 0; bucket < radix-1; bucket++ {
			position := start + offsets[bucket]
			if counts[bucket] > offsets[bucket] {
				held := arr[position]
				for {
					digit := getDigit(held, place)
					counts[digit]--
					displaced := arr[start+counts[digit]]
					arr[start+counts[digit]] = held
					held = displaced
					if counts[bucket] <= offsets[bucket] {
						break
					}
				}
			}
		}

		split := start + offsets[1]
		for i := 0; i < radix; i++ {
			counts[i] = 0
			offsets[i] = 0
		}
		return split
	}

	// i/b track the bounds of whichever range is currently active, q the
	// digit place being distributed on, and m a counter that mirrors how
	// many bucket boundaries have already been walked at the current
	// depth, standing in for the call stack a recursive walk would need.
	m := 0
	i := 0
	b := n

	for j := i; j < b; j++ {
		bump(getDigit(arr[j], q))
	}

	for i < n {
		var p int
		if b-i < 1 {
			p = i
		} else {
			p = distribute(i, b, q)
		}

		if q == 0 {
			m += radix
			t := m / radix
			for t%radix == 0 {
				t /= radix
				q++
			}

			i = b
			for b < n && shift(arr[b], q+1) == shift(m, q+1) {
				bump(getDigit(arr[b], q))
				b++
			}
		} else {
			b = p
			q--
			for j := i; j < b; j++ {
				bump(getDigit(arr[j], q))
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
