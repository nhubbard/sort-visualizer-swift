package main

import "fmt"

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

func partition(a []int, first, end, pivot int) int {
	i, j := first-1, end
	for {
		for {
			i++
			if !(i < j && a[i] < a[pivot]) {
				break
			}
		}
		for {
			j--
			if !(j >= i && a[j] > a[pivot]) {
				break
			}
		}
		if i >= j {
			return j
		}
		exchange(a, i, j)
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

func sort(a []int) {
	first, end := 0, len(a)
	badSplit, usedMedians := false, false
	for end-first > 16 {
		if badSplit {
			medianMedians(a, first, end)
			usedMedians = true
		} else {
			medianThree(a, first, end)
		}
		pivot := partition(a, first+1, end, first)
		exchange(a, first, pivot)
		left, right := pivot-first, end-pivot-1
		badSplit = !usedMedians &&
			(left == 0 || right == 0 ||
				(left > 0 && right > 0 && (left/right >= 16 || right/left >= 16)))
		if left <= right {
			mergeSort(a, first, pivot, pivot+1)
			first = pivot + 1
		} else {
			mergeSort(a, pivot+1, end, 2*pivot+1-end)
			end = pivot
		}
	}
	binaryInsertion(a, first, end)
}

func main() {
	a := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
		68, 83, 32, 56, 10, 2, 95, 46, 21, 74, 6, 38}
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
