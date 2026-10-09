package main

import (
	"fmt"
	"math"
)

// Median merge uses the larger partition as an internal swap buffer.
func exchange(a []int, i, j int) { a[i], a[j] = a[j], a[i] }

func insertion(a []int, first, end int) {
	for i := first + 1; i < end; i++ {
		for j := i; j > first && a[j-1] > a[j]; j-- {
			exchange(a, j-1, j)
		}
	}
}

func binaryInsertion(a []int, first, end int) {
	for i := first + 1; i < end; i++ {
		value, low, high := a[i], first, i
		for low < high {
			middle := low + (high-low)/2
			if value < a[middle] {
				high = middle
			} else {
				low = middle + 1
			}
		}
		for j := i; j > low; j-- {
			a[j] = a[j-1]
		}
		a[low] = value
	}
}

func medianThree(a []int, first, end int) {
	middle := first + (end-1-first)/2
	if a[first] > a[middle] {
		exchange(a, first, middle)
	}
	if a[middle] > a[end-1] {
		exchange(a, middle, end-1)
		if a[first] > a[middle] {
			return
		}
	}
	exchange(a, first, middle)
}

func medianMedians(a []int, first, end int) {
	alternate := true
	for end-first > 1 {
		write, i := first, first
		for i+10 <= end {
			insertion(a, i, i+5)
			exchange(a, write, i+2)
			write++
			i += 5
		}
		if i < end {
			insertion(a, i, end)
			adjust := 0
			if alternate {
				adjust = 1
			}
			exchange(a, write, i+(end-adjust-i)/2)
			write++
			if (end-i)%2 == 0 {
				alternate = !alternate
			}
		}
		end = write
	}
}

func shiftBackward(a []int, first, middle, end int) {
	for middle > first {
		middle--
		end--
		exchange(a, middle, end)
	}
}
func multiSwap(a []int, first, second, length int) {
	for offset := 0; offset < length; offset++ {
		exchange(a, first+offset, second+offset)
	}
}
func rotate(a []int, first, middle, end int) {
	left, right := middle-first, end-middle
	for left > 0 && right > 0 {
		if right < left {
			multiSwap(a, middle-right, middle, right)
			end -= right
			middle -= right
			left -= right
		} else {
			multiSwap(a, first, middle, left)
			first += left
			middle += left
			right -= left
		}
	}
}
func inPlaceMerge(a []int, first, middle, end int) {
	left, right := first, middle
	for left < right && right < end {
		if a[left] > a[right] {
			upper := right + 1
			for upper < end && a[left] > a[upper] {
				upper++
			}
			rotate(a, left, right, upper)
			left += upper - right
			right = upper
		} else {
			left++
		}
	}
}
func partition(a []int, first, end int) int {
	left, right := first, end
	for {
		for {
			left++
			if !(left < right && a[left] > a[first]) {
				break
			}
		}
		for {
			right--
			if !(right >= left && a[right] < a[first]) {
				break
			}
		}
		if left >= right {
			return right
		}
		exchange(a, left, right)
	}
}
func quickSelect(a []int, lower, upper, target int) int {
	badSplit, usedMedians := false, false
	targetUpper := (target + upper + 1) / 2
	for {
		if badSplit {
			medianMedians(a, lower, upper)
			usedMedians = true
		} else {
			medianThree(a, lower, upper)
		}
		pivot := partition(a, lower, upper)
		exchange(a, lower, pivot)
		left, right := pivot-lower, upper-pivot-1
		if left < 1 {
			left = 1
		}
		if right < 1 {
			right = 1
		}
		badSplit = !usedMedians && (left/right >= 16 || right/left >= 16)
		if pivot >= target && pivot < targetUpper {
			return pivot
		}
		if pivot < target {
			lower = pivot + 1
		} else {
			upper = pivot
		}
	}
}
func merge(a []int, first, middle, end, destination int) {
	i, j := first, middle
	for i < middle && j < end {
		if a[i] <= a[j] {
			exchange(a, destination, i)
			i++
		} else {
			exchange(a, destination, j)
			j++
		}
		destination++
	}
	for i < middle {
		exchange(a, destination, i)
		destination++
		i++
	}
	for j < end {
		exchange(a, destination, j)
		destination++
		j++
	}
}

func mergeSort(a []int, first, end, buffer int) {
	length := end - first
	if length <= 1 {
		return
	}
	width := length
	for width >= 32 {
		width = (width + 3) / 4
	}
	i := first
	for i+width <= end {
		binaryInsertion(a, i, i+width)
		i += width
	}
	binaryInsertion(a, i, end)
	for width < length {
		destination := buffer
		i = first
		for i+2*width <= end {
			merge(a, i, i+width, i+2*width, destination)
			i += 2 * width
			destination += 2 * width
		}
		if i+width < end {
			merge(a, i, i+width, end, destination)
		} else {
			for i < end {
				exchange(a, i, destination)
				i++
				destination++
			}
		}
		width *= 2

		destination = first
		i = buffer
		for i+2*width <= buffer+length {
			merge(a, i, i+width, i+2*width, destination)
			i += 2 * width
			destination += 2 * width
		}
		if i+width < buffer+length {
			merge(a, i, i+width, buffer+length, destination)
		} else {
			for i < buffer+length {
				exchange(a, i, destination)
				i++
				destination++
			}
		}
		width *= 2
	}
}

func mergeForward(a []int, destination, first, middle, end int) int {
	left, right := first, middle
	for left < middle && right < end {
		if a[left] <= a[right] {
			exchange(a, destination, left)
			left++
		} else {
			exchange(a, destination, right)
			right++
		}
		destination++
	}
	if left < middle {
		return left
	}
	return right
}
func sort(a []int) {
	n := len(a)
	if n <= 1 {
		return
	}
	first, middle := 0, (n+1)/2
	minimum := int(math.Sqrt(float64(n)))
	mergeSort(a, middle, n, first)
	for middle-first > minimum {
		selected := quickSelect(a, first, middle, (first+middle+1)/2)
		mergeSort(a, selected, middle, first)
		bufferLength := selected - first
		mergeEnd := selected + bufferLength
		if mergeEnd > n {
			mergeEnd = n
		}
		selected = mergeForward(a, first, selected, middle, mergeEnd)
		for selected < middle {
			shiftBackward(a, selected, middle, mergeEnd)
			selected = mergeEnd - (middle - selected)
			first = selected - bufferLength
			middle = mergeEnd
			if middle == n {
				break
			}
			mergeEnd += bufferLength
			if mergeEnd > n {
				mergeEnd = n
			}
			selected = mergeForward(a, first, selected, middle, mergeEnd)
		}
		middle = selected
		first = selected - bufferLength
	}
	binaryInsertion(a, first, middle)
	inPlaceMerge(a, first, middle, n)
}
func main() {
	a := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	sort(a)
	fmt.Print("[")
	for i, value := range a {
		if i > 0 {
			fmt.Print(", ")
		}
		fmt.Print(value)
	}
	fmt.Println("]")
}
