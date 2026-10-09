package main

import "fmt"

func minRun(n int) int {
	for n >= 32 {
		n = (n + 1) / 2
	}
	return n
}

func insertion(arr []int, start, end int) {
	for i := start + 1; i < end; i++ {
		value, low, high := arr[i], start, i
		for low < high {
			middle := low + (high-low)/2
			if arr[middle] > value {
				high = middle
			} else {
				low = middle + 1
			}
		}
		for j := i; j > low; j-- {
			arr[j] = arr[j-1]
		}
		arr[low] = value
	}
}

func mergeBackward(arr []int, start, middle, end, workspace int) {
	count := end - middle
	copy(arr[workspace:workspace+count], arr[middle:end])
	left, right, output := middle-1, workspace+count-1, end-1
	for left >= start && right >= workspace {
		if arr[left] > arr[right] {
			arr[output] = arr[left]
			left--
		} else {
			arr[output] = arr[right]
			right--
		}
		output--
	}
	for right >= workspace {
		arr[output] = arr[right]
		right--
		output--
	}
}

func sortSegment(arr []int, start, end, workspace, run int) {
	for lower := start; lower < end; lower += run {
		upper := lower + run
		if upper > end {
			upper = end
		}
		insertion(arr, lower, upper)
	}
	for width := run; width < end-start; width *= 2 {
		for lower := start; lower < end; lower += 2 * width {
			middle, upper := lower+width, lower+2*width
			if middle > end {
				middle = end
			}
			if upper > end {
				upper = end
			}
			if middle < upper {
				mergeBackward(arr, lower, middle, upper, workspace)
			}
		}
	}
}

func sort(arr []int) []int {
	n := len(arr)
	if n < 2 {
		return arr
	}
	run := minRun(n)
	if n <= 32 {
		insertion(arr, 0, n)
		return arr
	}
	half := n / 2
	buffer := append([]int(nil), arr[half:2*half]...)
	sortSegment(arr, 0, half, half, run)
	copy(arr[half:2*half], buffer)
	copy(buffer, arr[:half])
	sortSegment(arr, half, n, 0, run)
	left, right, output := 0, half, 0
	for left < half && right < n {
		if buffer[left] <= arr[right] {
			arr[output] = buffer[left]
			left++
		} else {
			arr[output] = arr[right]
			right++
		}
		output++
	}
	for left < half {
		arr[output] = buffer[left]
		left++
		output++
	}
	return arr
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23,
		90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
