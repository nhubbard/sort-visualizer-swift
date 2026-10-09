package main

import "fmt"

type rotateSorter struct {
	values []int
	buffer [64]int
}

func (s *rotateSorter) lowerBound(start, end, value int) int {
	for start < end {
		middle := start + (end-start)/2
		if s.values[middle] < value {
			start = middle + 1
		} else {
			end = middle
		}
	}
	return start
}
func (s *rotateSorter) upperBound(start, end, value int) int {
	for start < end {
		middle := start + (end-start)/2
		if s.values[middle] <= value {
			start = middle + 1
		} else {
			end = middle
		}
	}
	return start
}
func (s *rotateSorter) reverse(start, end int) {
	end--
	for start < end {
		s.values[start], s.values[end] = s.values[end], s.values[start]
		start++
		end--
	}
}
func (s *rotateSorter) rotate(start, middle, end int) {
	if start >= middle || middle >= end {
		return
	}
	left, right := middle-start, end-middle
	if left <= 64 {
		for i := 0; i < left; i++ {
			s.buffer[i] = s.values[start+i]
		}
		for i := middle; i < end; i++ {
			s.values[i-left] = s.values[i]
		}
		for i := 0; i < left; i++ {
			s.values[end-left+i] = s.buffer[i]
		}
	} else if right <= 64 {
		for i := 0; i < right; i++ {
			s.buffer[i] = s.values[middle+i]
		}
		for i := middle - 1; i >= start; i-- {
			s.values[i+right] = s.values[i]
		}
		for i := 0; i < right; i++ {
			s.values[start+i] = s.buffer[i]
		}
	} else {
		s.reverse(start, middle)
		s.reverse(middle, end)
		s.reverse(start, end)
	}
}
func (s *rotateSorter) bufferedMerge(start, middle, end int) {
	leftLength, rightLength := middle-start, end-middle
	if leftLength <= rightLength {
		for i := 0; i < leftLength; i++ {
			s.buffer[i] = s.values[start+i]
		}
		left, right, destination := 0, middle, start
		for left < leftLength && right < end {
			if s.values[right] < s.buffer[left] {
				s.values[destination] = s.values[right]
				right++
			} else {
				s.values[destination] = s.buffer[left]
				left++
			}
			destination++
		}
		for left < leftLength {
			s.values[destination] = s.buffer[left]
			left++
			destination++
		}
	} else {
		for i := 0; i < rightLength; i++ {
			s.buffer[i] = s.values[middle+i]
		}
		left, right, destination := middle-1, rightLength-1, end-1
		for left >= start && right >= 0 {
			if s.values[left] > s.buffer[right] {
				s.values[destination] = s.values[left]
				left--
			} else {
				s.values[destination] = s.buffer[right]
				right--
			}
			destination--
		}
		for right >= 0 {
			s.values[destination] = s.buffer[right]
			right--
			destination--
		}
	}
}
func (s *rotateSorter) merge(start, middle, end int) {
	if start >= middle || middle >= end || s.values[middle-1] <= s.values[middle] {
		return
	}
	leftLength, rightLength := middle-start, end-middle
	if leftLength <= 64 || rightLength <= 64 {
		s.bufferedMerge(start, middle, end)
		return
	}
	var leftSplit, rightSplit int
	if leftLength >= rightLength {
		leftSplit = start + leftLength/2
		rightSplit = s.lowerBound(middle, end, s.values[leftSplit])
	} else {
		rightSplit = middle + rightLength/2
		leftSplit = s.upperBound(start, middle, s.values[rightSplit])
	}
	s.rotate(leftSplit, middle, rightSplit)
	newMiddle := leftSplit + rightSplit - middle
	s.merge(start, leftSplit, newMiddle)
	s.merge(newMiddle, rightSplit, end)
}
func (s *rotateSorter) insertion(start, end int) {
	for index := start + 1; index < end; index++ {
		value := s.values[index]
		destination := s.upperBound(start, index, value)
		for cursor := index; cursor > destination; cursor-- {
			s.values[cursor] = s.values[cursor-1]
		}
		s.values[destination] = value
	}
}
func sort(values []int) {
	count := len(values)
	if count < 2 {
		return
	}
	s := rotateSorter{values: values}
	for start := 0; start < count; start += 32 {
		end := start + 32
		if end > count {
			end = count
		}
		s.insertion(start, end)
	}
	for run := 32; run < count; run *= 2 {
		for start := 0; start+run < count; start += 2 * run {
			end := start + 2*run
			if end > count {
				end = count
			}
			s.merge(start, start+run, end)
		}
	}
}
func main() {
	a := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	sort(a)
	fmt.Print("[")
	for i, v := range a {
		if i > 0 {
			fmt.Print(", ")
		}
		fmt.Print(v)
	}
	fmt.Println("]")
}
