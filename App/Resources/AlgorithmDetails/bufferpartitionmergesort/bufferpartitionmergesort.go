package main

import "fmt"

func sort(arr []int) []int {
	const run = 8
	for start := 0; start < len(arr); start += run {
		end := min(start+run, len(arr))
		for i := start + 1; i < end; i++ {
			value := arr[i]
			j := i
			for j > start && arr[j-1] > value {
				arr[j] = arr[j-1]
				j--
			}
			arr[j] = value
		}
	}

	scratch := append([]int(nil), arr...)
	for width := run; width < len(arr); width *= 2 {
		for start := 0; start < len(arr); start += 2 * width {
			middle := min(start+width, len(arr))
			end := min(start+2*width, len(arr))
			left, right := start, middle
			for out := start; out < end; out++ {
				if left < middle && (right >= end || arr[left] < arr[right]) {
					scratch[out] = arr[left]
					left++
				} else {
					scratch[out] = arr[right]
					right++
				}
			}
		}
		copy(arr, scratch)
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
