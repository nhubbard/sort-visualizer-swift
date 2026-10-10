// MIT License
// Copyright (c) 2021 The Holy Grail Sort Project, implemented by aphitorite
// Copyright (c) 2020-2021 aphitorite
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

package main

import "fmt"

// Synchronous square-root block merge, by aphitorite. The MIT notice from
// SynchronousSqrtSort.swift and BlockMergeSortingTemplate.swift applies.
type syncSqrt struct {
	a, prefix, tags []int
}

func (s *syncSqrt) binaryInsertion(first, end int) {
	for i := first + 1; i < end; i++ {
		value, low, high := s.a[i], first, i
		for low < high {
			middle := low + (high-low)/2
			if s.a[middle] <= value {
				low = middle + 1
			} else {
				high = middle
			}
		}
		for j := i; j > low; j-- {
			s.a[j] = s.a[j-1]
		}
		if low != i {
			s.a[low] = value
		}
	}
}
func (s *syncSqrt) shiftForward(destination, source, end int) {
	for source < end {
		s.a[destination] = s.a[source]
		destination++
		source++
	}
}
func (s *syncSqrt) shiftBackward(first, sourceEnd, destinationEnd int) {
	for sourceEnd > first {
		sourceEnd--
		destinationEnd--
		s.a[destinationEnd] = s.a[sourceEnd]
	}
}
func (s *syncSqrt) mergeForward(first, middle, end, output int) {
	left, right := first, middle
	for left < middle && right < end {
		if s.a[left] <= s.a[right] {
			s.a[output] = s.a[left]
			left++
		} else {
			s.a[output] = s.a[right]
			right++
		}
		output++
	}
	if left > output {
		s.shiftForward(output, left, middle)
	}
	s.shiftForward(output, right, end)
}
func (s *syncSqrt) mergeBackward(first, middle, end, output int) {
	left, right := middle-1, end-1
	for right >= middle && left >= first {
		output--
		if s.a[right] >= s.a[left] {
			s.a[output] = s.a[right]
			right--
		} else {
			s.a[output] = s.a[left]
			left--
		}
	}
	if output > right {
		s.shiftBackward(middle, right+1, output)
	}
	s.shiftBackward(first, left+1, output)
}
func (s *syncSqrt) smartMergeBackward(first, middle, end, output int, reversed bool) int {
	left, right := middle-1, end-1
	for left >= first && right >= middle {
		takeLeft := s.a[left] > s.a[right]
		if reversed {
			takeLeft = s.a[left] >= s.a[right]
		}
		output--
		if takeLeft {
			s.a[output] = s.a[left]
			left--
		} else {
			s.a[output] = s.a[right]
			right--
		}
	}
	return left + 1
}
func (s *syncSqrt) blockSelection(first, end, block, tagStart, tagCount int) {
	available := tagCount + 1
	if available > len(s.tags)-tagStart {
		available = len(s.tags) - tagStart
	}
	for i := 0; i < available; i++ {
		s.tags[tagStart+i] = i
		if i > tagCount/2 {
			s.tags[tagStart+i] += len(s.tags)
		}
	}
	vacant, current := first, first
	for current < end-block {
		minimum := current
		if vacant == current {
			minimum += block
		}
		for candidate := minimum + block; candidate < end; candidate += block {
			if candidate != vacant && (s.a[candidate] < s.a[minimum] ||
				(s.a[candidate] == s.a[minimum] &&
					s.tags[tagStart+(candidate-first)/block] < s.tags[tagStart+(minimum-first)/block])) {
				minimum = candidate
			}
		}
		if minimum > current {
			if vacant == current {
				copy(s.a[current:current+block], s.a[minimum:minimum+block])
				s.tags[tagStart+(current-first)/block] = s.tags[tagStart+(minimum-first)/block]
				vacant = minimum
			} else {
				for i := 0; i < block; i++ {
					s.a[current+i], s.a[minimum+i] = s.a[minimum+i], s.a[current+i]
				}
				i, j := tagStart+(current-first)/block, tagStart+(minimum-first)/block
				s.tags[i], s.tags[j] = s.tags[j], s.tags[i]
			}
		}
		current += block
	}
}
func (s *syncSqrt) mergeBlocksBackward(first, end, firstTag, pastLastTag, block int) {
	tag := pastLastTag - 1
	frontier, blockStart := end, end-block
	reversed := s.tags[tag] < len(s.tags)
	for {
		for {
			tag--
			blockStart -= block
			if !(tag >= firstTag && (s.tags[tag] < len(s.tags)) == reversed) {
				break
			}
		}
		if tag < firstTag {
			s.shiftBackward(first, frontier, frontier+block)
			break
		}
		frontier = s.smartMergeBackward(blockStart, blockStart+block, frontier, frontier+block, reversed)
		reversed = !reversed
	}
}
func sort(a []int) {
	n := len(a)
	if n <= 1 {
		return
	}
	s := syncSqrt{a: a}
	if n <= 16 {
		s.binaryInsertion(0, n)
		return
	}
	block := 1
	for block*block < n {
		block *= 2
	}
	first, end := block+n%block, n
	workLength, run := end-first, 1
	s.prefix = make([]int, first)
	s.tags = make([]int, (n-1)/block+1)
	s.binaryInsertion(0, first)
	copy(s.prefix, a[:first])
	for run < block {
		distance := run
		if distance < 2 {
			distance = 2
		}
		index := first
		for index+2*run < end {
			s.mergeForward(index, index+run, index+2*run, index-distance)
			index += 2 * run
		}
		if index+run < end {
			s.mergeForward(index, index+run, end, index-distance)
		} else {
			s.shiftForward(index-distance, index, end)
		}
		first -= distance
		end -= distance
		run *= 2
	}
	fragment := workLength % (2 * run)
	index := end - fragment
	if index+run < end {
		s.mergeBackward(index, index+run, end, end+run)
	} else {
		s.shiftBackward(index, end, end+run)
	}
	index -= 2 * run
	for index >= first {
		s.mergeBackward(index, index+run, index+2*run, index+3*run)
		index -= 2 * run
	}
	first += run
	end += run
	run *= 2
	tagCount := 4
	for run < workLength {
		index = first
		tagIndex := 0
		for index+2*run < end {
			s.blockSelection(index-block, index+2*run, block, tagIndex, tagCount)
			index += 2 * run
			tagIndex += tagCount
		}
		hasFragment := index+run < end
		fragment = (end - index) / block
		if hasFragment {
			s.blockSelection(index-block, end, block, tagIndex, tagCount)
		}
		first -= block
		end -= block
		index -= block
		if hasFragment {
			s.mergeBlocksBackward(index, end, tagIndex, tagIndex+fragment, block)
		}
		index -= 2 * run
		tagIndex -= tagCount
		for index >= first {
			s.mergeBlocksBackward(index, index+2*run, tagIndex, tagIndex+tagCount, block)
			index -= 2 * run
			tagIndex -= tagCount
		}
		first += block
		end += block
		run *= 2
		tagCount *= 2
	}
	left, right, output := 0, first, 0
	for left < first && right < end {
		if s.prefix[left] <= a[right] {
			a[output] = s.prefix[left]
			left++
		} else {
			a[output] = a[right]
			right++
		}
		output++
	}
	for left < first {
		a[output] = s.prefix[left]
		left++
		output++
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
