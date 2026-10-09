package main

import "fmt"

type run struct{ base, length int }

func minRunLength(value int) int {
	n, remainder := value, 0
	for n >= 32 {
		remainder |= n & 1
		n >>= 1
	}
	return n + remainder
}

func countRun(values []int, start int) int {
	end := start + 1
	if end == len(values) {
		return 1
	}
	descending := values[end] < values[start]
	end++
	if descending {
		for end < len(values) && values[end] < values[end-1] {
			end++
		}
		for left, right := start, end-1; left < right; left, right = left+1, right-1 {
			values[left], values[right] = values[right], values[left]
		}
	} else {
		for end < len(values) && values[end] >= values[end-1] {
			end++
		}
	}
	return end - start
}

func binaryInsertion(values []int, start, end, sortedEnd int) {
	for index := sortedEnd; index < end; index++ {
		pivot := values[index]
		low, high := start, index
		for low < high {
			middle := (low + high) / 2
			if values[middle] <= pivot {
				low = middle + 1
			} else {
				high = middle
			}
		}
		for shift := index; shift > low; shift-- {
			values[shift] = values[shift-1]
		}
		values[low] = pivot
	}
}

func merge(values []int, runs []run, index int) []run {
	start, leftLength := runs[index].base, runs[index].length
	rightStart, rightLength := runs[index+1].base, runs[index+1].length
	left := append([]int(nil), values[start:rightStart]...)
	right := append([]int(nil), values[rightStart:rightStart+rightLength]...)
	i, j, destination := 0, 0, start
	for i < len(left) && j < len(right) {
		if left[i] <= right[j] {
			values[destination] = left[i]
			i++
		} else {
			values[destination] = right[j]
			j++
		}
		destination++
	}
	for i < len(left) {
		values[destination] = left[i]
		i++
		destination++
	}
	for j < len(right) {
		values[destination] = right[j]
		j++
		destination++
	}
	runs[index] = run{start, leftLength + rightLength}
	return append(runs[:index+1], runs[index+2:]...)
}

func sort(values []int) []int {
	n := len(values)
	if n < 2 {
		return values
	}
	minimum := minRunLength(n)
	runs := make([]run, 0)
	cursor := 0
	for cursor < n {
		length := countRun(values, cursor)
		forced := minimum
		if n-cursor < forced {
			forced = n - cursor
		}
		if length < forced {
			binaryInsertion(values, cursor, cursor+forced, cursor+length)
			length = forced
		}
		runs = append(runs, run{cursor, length})
		for len(runs) > 1 {
			index := len(runs) - 2
			if (index >= 1 && runs[index-1].length <= runs[index].length+runs[index+1].length) ||
				(index >= 2 && runs[index-2].length <= runs[index].length+runs[index-1].length) {
				if runs[index-1].length < runs[index+1].length {
					index--
				}
			} else if runs[index].length > runs[index+1].length {
				break
			}
			runs = merge(values, runs, index)
		}
		cursor += length
	}
	for len(runs) > 1 {
		index := len(runs) - 2
		if index > 0 && runs[index-1].length < runs[index+1].length {
			index--
		}
		runs = merge(values, runs, index)
	}
	return values
}

func main() {
	array := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	fmt.Println(sort(array))
}
