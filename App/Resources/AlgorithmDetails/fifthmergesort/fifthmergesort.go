package main

import "fmt"

func sortRange(arr []int, start int, end int) {
	length := end - start
	if length < 2 {
		return
	}

	bounds := make([]int, 6)
	for part := 0; part <= 5; part++ {
		bounds[part] = start + length*part/5
	}
	for part := 0; part < 5; part++ {
		sortRange(arr, bounds[part], bounds[part+1])
	}

	positions := append([]int(nil), bounds[:5]...)
	merged := make([]int, 0, length)
	for len(merged) < length {
		best := -1
		for part := 0; part < 5; part++ {
			if positions[part] < bounds[part+1] &&
				(best < 0 || arr[positions[part]] < arr[positions[best]]) {
				best = part
			}
		}
		merged = append(merged, arr[positions[best]])
		positions[best]++
	}
	copy(arr[start:end], merged)
}

func sort(arr []int) []int {
	sortRange(arr, 0, len(arr))
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
