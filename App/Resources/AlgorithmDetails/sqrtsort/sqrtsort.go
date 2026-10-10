// MIT License
// Copyright (c) 2014 Andrey Astrelin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
package main

import "fmt"

type sqrtSorter struct{ a, buffer, tags []int }

func (s *sqrtSorter) read(storage, index int) int {
	if storage == 0 {
		return s.a[index]
	}
	return s.buffer[index]
}
func (s *sqrtSorter) write(storage, index, value int) {
	if storage == 0 {
		s.a[index] = value
	} else {
		s.buffer[index] = value
	}
}
func (s *sqrtSorter) compare(firstStorage, first, secondStorage, second int) int {
	a, b := s.read(firstStorage, first), s.read(secondStorage, second)
	if a < b {
		return -1
	}
	if a > b {
		return 1
	}
	return 0
}
func (s *sqrtSorter) copyValues(sourceStorage, source, targetStorage, target, count int) {
	if sourceStorage == targetStorage && source < target && target < source+count {
		for i := count - 1; i >= 0; i-- {
			s.write(targetStorage, target+i, s.read(sourceStorage, source+i))
		}
	} else {
		for i := 0; i < count; i++ {
			s.write(targetStorage, target+i, s.read(sourceStorage, source+i))
		}
	}
}
func (s *sqrtSorter) swap(storage, a, b int) {
	if a == b {
		return
	}
	first := s.read(storage, a)
	s.write(storage, a, s.read(storage, b))
	s.write(storage, b, first)
}
func (s *sqrtSorter) insertion(storage, position, length int) {
	for index := position + 1; index < position+length; index++ {
		value, cursor := s.read(storage, index), index
		for cursor > position && s.read(storage, cursor-1) > value {
			s.write(storage, cursor, s.read(storage, cursor-1))
			cursor--
		}
		s.write(storage, cursor, value)
	}
}
func (s *sqrtSorter) mergeRight(storage, position, leftLength, rightLength, distance int) {
	destination := position + leftLength + rightLength + distance - 1
	right, left := position+leftLength+rightLength-1, position+leftLength-1
	for left >= position {
		if right < position+leftLength || s.compare(storage, left, storage, right) > 0 {
			s.write(storage, destination, s.read(storage, left))
			left--
		} else {
			s.write(storage, destination, s.read(storage, right))
			right--
		}
		destination--
	}
	if right != destination {
		for right >= position+leftLength {
			s.write(storage, destination, s.read(storage, right))
			right--
			destination--
		}
	}
}
func (s *sqrtSorter) mergeLeft(storage, position, leftLength, rightLength, distance int) {
	left, right, destination := position, position+leftLength, position+distance
	leftEnd, rightEnd := right, right+rightLength
	for right < rightEnd {
		if left == leftEnd || s.compare(storage, left, storage, right) > 0 {
			s.write(storage, destination, s.read(storage, right))
			right++
		} else {
			s.write(storage, destination, s.read(storage, left))
			left++
		}
		destination++
	}
	if destination != left {
		for left < leftEnd {
			s.write(storage, destination, s.read(storage, left))
			left++
			destination++
		}
	}
}
func (s *sqrtSorter) mergeDown(storage, position, prefix, prefixPosition, leftLength, prefixLength int) {
	left, right, destination := 0, 0, position-prefixLength
	for right < prefixLength {
		if left == leftLength || s.compare(storage, position+left, prefix, prefixPosition+right) >= 0 {
			s.write(storage, destination, s.read(prefix, prefixPosition+right))
			right++
		} else {
			s.write(storage, destination, s.read(storage, position+left))
			left++
		}
		destination++
	}
	if destination != position+left {
		for left < leftLength {
			s.write(storage, destination, s.read(storage, position+left))
			left++
			destination++
		}
	}
}
func (s *sqrtSorter) smartMerge(storage, position, priorLength, priorFragment, blockLength int) (int, int) {
	left, right, destination := position, position+priorLength, position-blockLength
	leftEnd, rightEnd, opposite := right, right+blockLength, 1-priorFragment
	for left < leftEnd && right < rightEnd {
		order := s.compare(storage, left, storage, right)
		if order < 0 || (order == 0 && opposite == 1) {
			s.write(storage, destination, s.read(storage, left))
			left++
		} else {
			s.write(storage, destination, s.read(storage, right))
			right++
		}
		destination++
	}
	if left < leftEnd {
		remaining := leftEnd - left
		for left < leftEnd {
			leftEnd--
			rightEnd--
			s.write(storage, rightEnd, s.read(storage, leftEnd))
		}
		return remaining, priorFragment
	}
	return rightEnd - right, opposite
}
func (s *sqrtSorter) mergeBuffers(storage, position, middleTag, blockCount, blockLength, trailingABlocks, tailLength int) {
	if blockCount == 0 {
		s.mergeLeft(storage, position, trailingABlocks*blockLength, tailLength, -blockLength)
		return
	}
	priorLength, priorFragment := blockLength, 1
	if s.tags[0] < middleTag {
		priorFragment = 0
	}
	process := blockLength
	for tagIndex := 1; tagIndex < blockCount; tagIndex++ {
		rest := process - priorLength
		nextFragment := 1
		if s.tags[tagIndex] < middleTag {
			nextFragment = 0
		}
		if nextFragment == priorFragment {
			s.copyValues(storage, position+rest, storage, position+rest-blockLength, priorLength)
			rest = process
			priorLength = blockLength
		} else {
			priorLength, priorFragment = s.smartMerge(storage, position+rest, priorLength, priorFragment, blockLength)
		}
		process += blockLength
	}
	rest := process - priorLength
	if tailLength != 0 {
		if priorFragment != 0 {
			s.copyValues(storage, position+rest, storage, position+rest-blockLength, priorLength)
			rest = process
			priorLength = blockLength * trailingABlocks
		} else {
			priorLength += blockLength * trailingABlocks
		}
		s.mergeLeft(storage, position+rest, priorLength, tailLength, -blockLength)
	} else {
		s.copyValues(storage, position+rest, storage, position+rest-blockLength, priorLength)
	}
}
func (s *sqrtSorter) buildBlocks(storage, position, length, blockLength int) {
	pair := 1
	for pair < length {
		lower := 0
		if s.compare(storage, position+pair-1, storage, position+pair) > 0 {
			lower = 1
		}
		s.write(storage, position+pair-3, s.read(storage, position+pair-1+lower))
		s.write(storage, position+pair-2, s.read(storage, position+pair-lower))
		pair += 2
	}
	if length%2 != 0 {
		s.write(storage, position+length-3, s.read(storage, position+length-1))
	}
	position -= 2
	part := 2
	for part < blockLength {
		left, right := 0, length-2*part
		for left <= right {
			s.mergeLeft(storage, position+left, part, part, -part)
			left += 2 * part
		}
		rest := length - left
		if rest > part {
			s.mergeLeft(storage, position+left, part, rest-part, -part)
		} else {
			for left < length {
				s.write(storage, position+left-part, s.read(storage, position+left))
				left++
			}
		}
		position -= part
		part *= 2
	}
	remainder := length % (2 * blockLength)
	leftover := length - remainder
	if remainder <= blockLength {
		s.copyValues(storage, position+leftover, storage, position+leftover+blockLength, remainder)
	} else {
		s.mergeRight(storage, position+leftover, blockLength, remainder-blockLength, blockLength)
	}
	for leftover > 0 {
		leftover -= 2 * blockLength
		s.mergeRight(storage, position+leftover, blockLength, blockLength, blockLength)
	}
}
func (s *sqrtSorter) combineBlocks(storage, position, length, runLength, blockLength int) {
	combineCount, remainder := length/(2*runLength), length%(2*runLength)
	if remainder <= runLength {
		length -= remainder
		remainder = 0
	}
	for group := 0; group <= combineCount; group++ {
		if group == combineCount && remainder == 0 {
			break
		}
		groupPosition := position + group*2*runLength
		count := 2 * runLength / blockLength
		tagEnd := count
		if group == combineCount {
			count = remainder / blockLength
			tagEnd = count + 1
		}
		for tag := 0; tag <= tagEnd; tag++ {
			s.tags[tag] = tag
		}
		middle := runLength / blockLength
		for tagIndex := 1; tagIndex < count; tagIndex++ {
			selected := tagIndex - 1
			for candidate := tagIndex; candidate < count; candidate++ {
				order := s.compare(storage, groupPosition+selected*blockLength, storage, groupPosition+candidate*blockLength)
				if order > 0 || (order == 0 && s.tags[selected] > s.tags[candidate]) {
					selected = candidate
				}
			}
			if selected != tagIndex-1 {
				for offset := 0; offset < blockLength; offset++ {
					s.swap(storage, groupPosition+(tagIndex-1)*blockLength+offset, groupPosition+selected*blockLength+offset)
				}
				s.tags[tagIndex-1], s.tags[selected] = s.tags[selected], s.tags[tagIndex-1]
			}
		}
		trailingA, tail := 0, 0
		if group == combineCount {
			tail = remainder % blockLength
		}
		if tail != 0 {
			for trailingA < count && s.compare(storage, groupPosition+count*blockLength, storage, groupPosition+(count-trailingA-1)*blockLength) < 0 {
				trailingA++
			}
		}
		s.mergeBuffers(storage, groupPosition, middle, count-trailingA, blockLength, trailingA, tail)
	}
	if length > 0 {
		for index := length - 1; index >= 0; index-- {
			s.write(storage, position+index, s.read(storage, position+index-blockLength))
		}
	}
}
func (s *sqrtSorter) commonSort(storage, position, length, prefix, prefixPosition int) {
	if length <= 16 {
		s.insertion(storage, position, length)
		return
	}
	blockLength := 1
	for blockLength*blockLength < length {
		blockLength *= 2
	}
	s.copyValues(storage, position, prefix, prefixPosition, blockLength)
	s.commonSort(prefix, prefixPosition, blockLength, storage, position)
	s.buildBlocks(storage, position+blockLength, length-blockLength, blockLength)
	runLength := blockLength
	for {
		runLength *= 2
		if length <= runLength {
			break
		}
		s.combineBlocks(storage, position+blockLength, length-blockLength, runLength, blockLength)
	}
	s.mergeDown(storage, position+blockLength, prefix, prefixPosition, length-blockLength, blockLength)
}
func sort(a []int) {
	n := len(a)
	if n < 2 {
		return
	}
	bufferLength := 1
	for bufferLength*bufferLength < n {
		bufferLength *= 2
	}
	s := sqrtSorter{a: a, buffer: make([]int, bufferLength), tags: make([]int, (n-1)/bufferLength+2)}
	s.commonSort(0, 0, n, 1, 0)
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
