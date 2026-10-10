// Copyright (C) 2008 The Android Open Source Project
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//     http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// /
//

package main

import "fmt"

// Copyright (C) 2008 The Android Open Source Project.
// Licensed under the Apache License, Version 2.0; see the complete
// notice in the native TimSort.swift source.
type tim struct {
	a, base, length, temp []int
	stackSize, minGallop  int
}

func minimum(a, b int) int {
	if a < b {
		return a
	}
	return b
}
func maximum(a, b int) int {
	if a > b {
		return a
	}
	return b
}
func (s *tim) ensureCapacity(needed int) {
	if len(s.temp) >= needed {
		return
	}
	capacity := maximum(1, len(s.temp))
	for capacity < needed {
		capacity *= 2
	}
	capacity = minimum(capacity, maximum(1, len(s.a)/2))
	s.temp = make([]int, capacity)
}
func minRunLength(value int) int {
	remainder := 0
	for value >= 32 {
		remainder |= value & 1
		value >>= 1
	}
	return value + remainder
}
func (s *tim) countRun(first, end int) int {
	if first+1 >= end {
		return 1
	}
	cursor := first + 2
	if s.a[first+1] < s.a[first] {
		for cursor < end && s.a[cursor] < s.a[cursor-1] {
			cursor++
		}
		for left, right := first, cursor-1; left < right; left, right = left+1, right-1 {
			s.a[left], s.a[right] = s.a[right], s.a[left]
		}
	} else {
		for cursor < end && s.a[cursor] >= s.a[cursor-1] {
			cursor++
		}
	}
	return cursor - first
}
func (s *tim) binaryInsertion(first, end, sortedEnd int) {
	for cursor := maximum(first+1, sortedEnd); cursor < end; cursor++ {
		pivot, low, high := s.a[cursor], first, cursor
		for low < high {
			middle := low + (high-low)/2
			if s.a[middle] <= pivot {
				low = middle + 1
			} else {
				high = middle
			}
		}
		for shift := cursor; shift > low; shift-- {
			s.a[shift] = s.a[shift-1]
		}
		s.a[low] = pivot
	}
}
func (s *tim) gallop(first, end, key int, upper, fromEnd, useTemp bool) int {
	if first >= end {
		return first
	}
	source := s.a
	if useTemp {
		source = s.temp
	}
	before := func(i int) bool {
		if upper {
			return source[i] <= key
		}
		return source[i] < key
	}
	var low, high int
	if fromEnd {
		high = end
		low = end - 1
		step := 1
		for !before(low) {
			high = low
			if low == first {
				break
			}
			step = minimum(end-first, step*2)
			low = maximum(first, end-step)
		}
	} else {
		low = first
		high = first + 1
		for before(high-1) && high < end {
			low = high
			high = minimum(end, first+(high-first)*2)
		}
	}
	for low < high {
		middle := low + (high-low)/2
		if before(middle) {
			low = middle + 1
		} else {
			high = middle
		}
	}
	return low
}
func (s *tim) mergeLow(first, leftLength, rightStart, rightLength int) {
	s.ensureCapacity(leftLength)
	copy(s.temp, s.a[first:first+leftLength])
	left, right, destination := 0, rightStart, first
	rightEnd := rightStart + rightLength
	leftWins, rightWins := 0, 0
	galloped := false
	for left < leftLength && right < rightEnd {
		if s.a[right] < s.temp[left] {
			s.a[destination] = s.a[right]
			right++
			rightWins++
			leftWins = 0
		} else {
			s.a[destination] = s.temp[left]
			left++
			leftWins++
			rightWins = 0
		}
		destination++
		if left >= leftLength || right >= rightEnd {
			break
		}
		if maximum(leftWins, rightWins) < s.minGallop {
			continue
		}
		galloped = true
		leftStop := s.gallop(left, leftLength, s.a[right], true, false, true)
		for left < leftStop {
			s.a[destination] = s.temp[left]
			left++
			destination++
		}
		if left == leftLength {
			break
		}
		s.a[destination] = s.a[right]
		right++
		destination++
		if right == rightEnd {
			break
		}
		rightStop := s.gallop(right, rightEnd, s.temp[left], false, false, false)
		for right < rightStop {
			s.a[destination] = s.a[right]
			right++
			destination++
		}
		if right == rightEnd {
			break
		}
		s.a[destination] = s.temp[left]
		left++
		destination++
		s.minGallop = maximum(1, s.minGallop-1)
		leftWins, rightWins = 0, 0
	}
	for left < leftLength {
		s.a[destination] = s.temp[left]
		left++
		destination++
	}
	if galloped {
		s.minGallop += 2
	}
}
func (s *tim) mergeHigh(first, leftLength, rightStart, rightLength int) {
	_ = leftLength
	s.ensureCapacity(rightLength)
	copy(s.temp, s.a[rightStart:rightStart+rightLength])
	left, right := rightStart-1, rightLength-1
	destination := rightStart + rightLength - 1
	leftWins, rightWins := 0, 0
	galloped := false
	for left >= first && right >= 0 {
		if s.temp[right] < s.a[left] {
			s.a[destination] = s.a[left]
			left--
			leftWins++
			rightWins = 0
		} else {
			s.a[destination] = s.temp[right]
			right--
			rightWins++
			leftWins = 0
		}
		destination--
		if left < first || right < 0 {
			break
		}
		if maximum(leftWins, rightWins) < s.minGallop {
			continue
		}
		galloped = true
		leftStop := s.gallop(first, left+1, s.temp[right], true, true, false)
		for left >= leftStop {
			s.a[destination] = s.a[left]
			left--
			destination--
		}
		if left < first {
			break
		}
		s.a[destination] = s.temp[right]
		right--
		destination--
		if right < 0 {
			break
		}
		rightStop := s.gallop(0, right+1, s.a[left], false, true, true)
		for right >= rightStop {
			s.a[destination] = s.temp[right]
			right--
			destination--
		}
		if right < 0 {
			break
		}
		s.a[destination] = s.a[left]
		left--
		destination--
		s.minGallop = maximum(1, s.minGallop-1)
		leftWins, rightWins = 0, 0
	}
	for right >= 0 {
		s.a[destination] = s.temp[right]
		right--
		destination--
	}
	if galloped {
		s.minGallop += 2
	}
}
func (s *tim) mergeAt(index int) {
	leftStart, leftLength := s.base[index], s.length[index]
	rightStart, rightLength := s.base[index+1], s.length[index+1]
	s.length[index] = leftLength + rightLength
	if index == s.stackSize-3 {
		s.base[index+1] = s.base[index+2]
		s.length[index+1] = s.length[index+2]
	}
	s.stackSize--
	skipped := s.gallop(leftStart, rightStart, s.a[rightStart], true, false, false)
	leftLength -= skipped - leftStart
	leftStart = skipped
	if leftLength == 0 {
		return
	}
	rightLength = s.gallop(rightStart, rightStart+rightLength, s.a[rightStart-1], false, false, false) - rightStart
	if rightLength == 0 {
		return
	}
	if leftLength <= rightLength {
		s.mergeLow(leftStart, leftLength, rightStart, rightLength)
	} else {
		s.mergeHigh(leftStart, leftLength, rightStart, rightLength)
	}
}
func (s *tim) collapse() {
	for s.stackSize > 1 {
		index := s.stackSize - 2
		if (index >= 1 && s.length[index-1] <= s.length[index]+s.length[index+1]) ||
			(index >= 2 && s.length[index-2] <= s.length[index]+s.length[index-1]) {
			if s.length[index-1] < s.length[index+1] {
				index--
			}
		} else if s.length[index] > s.length[index+1] {
			break
		}
		s.mergeAt(index)
	}
}
func (s *tim) forceCollapse() {
	for s.stackSize > 1 {
		index := s.stackSize - 2
		if index > 0 && s.length[index-1] < s.length[index+1] {
			index--
		}
		s.mergeAt(index)
	}
}
func sort(a []int) {
	n := len(a)
	if n <= 1 {
		return
	}
	capacity := 5
	if n >= 120 {
		capacity = 10
	}
	if n >= 1542 {
		capacity = 19
	}
	if n >= 119151 {
		capacity = 40
	}
	s := tim{a: a, base: make([]int, capacity), length: make([]int, capacity), minGallop: 7}
	if n < 32 {
		run := s.countRun(0, n)
		s.binaryInsertion(0, n, run)
		return
	}
	minRun, cursor := minRunLength(n), 0
	for cursor < n {
		run := s.countRun(cursor, n)
		if run < minRun {
			forced := minimum(minRun, n-cursor)
			s.binaryInsertion(cursor, cursor+forced, cursor+run)
			run = forced
		}
		s.base[s.stackSize] = cursor
		s.length[s.stackSize] = run
		s.stackSize++
		s.collapse()
		cursor += run
	}
	s.forceCollapse()
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
