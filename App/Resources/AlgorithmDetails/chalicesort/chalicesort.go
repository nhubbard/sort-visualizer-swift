// MIT License
// Copyright (c) 2021 aphitorite
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

package main

import "fmt"

type KeyGroup struct{ start, end int }
type ChaliceSortExample struct{ values, temp []int }

func relation(left, right int, op string) bool {
	switch op {
	case "<":
		return left < right
	case "<=":
		return left <= right
	case ">":
		return left > right
	case ">=":
		return left >= right
	default:
		return left == right
	}
}
func ternary[T any](condition bool, left, right T) T {
	if condition {
		return left
	}
	return right
}

// The first fifth is the only external buffer; the other four merge through
// its vacated positions before a central backward merge restores the prefix.
type fifth struct {
	a, buffer []int
}

func (s *fifth) binaryInsertion(first, end int) {
	for i := first + 1; i < end; i++ {
		value, low, high := s.a[i], first, i
		for low < high {
			middle := low + (high-low)/2
			if s.a[middle] > value {
				high = middle
			} else {
				low = middle + 1
			}
		}
		for j := i; j > low; j-- {
			s.a[j] = s.a[j-1]
		}
		s.a[low] = value
	}
}

func (s *fifth) source(index, offset int, fromBuffer bool) int {
	if fromBuffer {
		return s.buffer[index-offset]
	}
	return s.a[index]
}

func (s *fifth) merge(offset, first, middle, end int, fromBuffer bool) {
	left, right := first, middle
	destination := first - offset
	if fromBuffer {
		destination = first
	}
	write := func(value int) {
		if fromBuffer {
			s.a[destination] = value
		} else {
			s.buffer[destination] = value
		}
		destination++
	}
	for left < middle && right < end {
		if s.source(left, offset, fromBuffer) <= s.source(right, offset, fromBuffer) {
			write(s.source(left, offset, fromBuffer))
			left++
		} else {
			write(s.source(right, offset, fromBuffer))
			right++
		}
	}
	for left < middle {
		write(s.source(left, offset, fromBuffer))
		left++
	}
	for right < end {
		write(s.source(right, offset, fromBuffer))
		right++
	}
}

func (s *fifth) pingPong(first, end int) {
	i := first
	for i+8 < end {
		s.binaryInsertion(i, i+8)
		i += 8
	}
	if end-i > 1 {
		s.binaryInsertion(i, end)
	}
	length, fromBuffer := end-first, false
	for gap := 8; gap < length; gap *= 2 {
		full := gap * 2
		i = first
		for i+full < end {
			s.merge(first, i, i+gap, i+full, fromBuffer)
			i += full
		}
		if i+gap < end {
			s.merge(first, i, i+gap, end, fromBuffer)
		} else {
			for j := i; j < end; j++ {
				if fromBuffer {
					s.a[j] = s.buffer[j-first]
				} else {
					s.buffer[j-first] = s.a[j]
				}
			}
		}
		fromBuffer = !fromBuffer
	}
	if fromBuffer {
		for j := 0; j < length; j++ {
			s.a[first+j] = s.buffer[j]
		}
	}
}

func (s *fifth) mergeForward(destination, first, middle, end int) {
	left, right := first, middle
	for left < middle && right < end {
		if s.a[left] <= s.a[right] {
			s.a[destination] = s.a[left]
			left++
		} else {
			s.a[destination] = s.a[right]
			right++
		}
		destination++
	}
	for left < middle {
		s.a[destination] = s.a[left]
		destination++
		left++
	}
	for right < end {
		s.a[destination] = s.a[right]
		destination++
		right++
	}
}

func (s *fifth) mergeBackward(destination, middle, end int) (int, int) {
	left, right := middle-1, end-1
	for destination > right && right >= middle && left >= 0 {
		if s.a[left] > s.a[right] {
			s.a[destination] = s.a[left]
			left--
		} else {
			s.a[destination] = s.a[right]
			right--
		}
		destination--
	}
	if left < 0 {
		for right >= middle {
			s.a[destination] = s.a[right]
			destination--
			right--
		}
	} else if right == left {
		for right >= 0 {
			s.a[destination] = s.a[right]
			destination--
			right--
		}
	} else if right < middle {
		for left >= 0 {
			s.a[destination] = s.a[left]
			destination--
			left--
		}
	}
	return left + 1, right + 1
}

func (s *fifth) mergeMainPrefix(destination, leftEnd, middle, end int) {
	left, right := 0, middle
	for left < leftEnd && right < end {
		if s.a[left] <= s.a[right] {
			s.a[destination] = s.a[left]
			left++
		} else {
			s.a[destination] = s.a[right]
			right++
		}
		destination++
	}
	for left < leftEnd {
		s.a[destination] = s.a[left]
		destination++
		left++
	}
}

func (s *fifth) mergeExternal(destination, middle, end int) {
	left, right := 0, middle
	for left < len(s.buffer) && right < end {
		if s.buffer[left] <= s.a[right] {
			s.a[destination] = s.buffer[left]
			left++
		} else {
			s.a[destination] = s.a[right]
			right++
		}
		destination++
	}
	for left < len(s.buffer) {
		s.a[destination] = s.buffer[left]
		destination++
		left++
	}
}

func sort(a []int) {
	n := len(a)
	if n <= 1 {
		return
	}
	chunk := n / 5
	bufferLength := n - 4*chunk
	s := fifth{a: a, buffer: make([]int, bufferLength)}
	s.pingPong(0, bufferLength)
	first := bufferLength
	for i := 0; i < 4; i++ {
		s.pingPong(first, first+chunk)
		first += chunk
	}
	copy(s.buffer, a[:bufferLength])
	twoFifths := 2 * chunk
	first = bufferLength
	for i := 0; i < 2; i++ {
		s.mergeForward(first-bufferLength, first, first+chunk, first+twoFifths)
		first += twoFifths
	}
	left, right := s.mergeBackward(n-1, twoFifths, 2*twoFifths)
	if right > 0 {
		s.mergeMainPrefix(bufferLength, left, twoFifths, n)
	}
	s.mergeExternal(0, bufferLength, n)
}

func (self *ChaliceSortExample) read(index int) int {
	return self.values[index]
}
func (self *ChaliceSortExample) write(index int, value int) {
	self.values[index] = value
}
func (self *ChaliceSortExample) swap(first int, second int) {
	self.values[first], self.values[second] = self.values[second], self.values[first]
}
func (self *ChaliceSortExample) compare(first int, second int, predicate string) bool {
	return relation(self.values[first], self.values[second], predicate)
}
func (self *ChaliceSortExample) compareValues(first int, second int, predicate string) bool {
	return relation(first, second, predicate)
}
func (self *ChaliceSortExample) save(index int, value int) {
	self.temp[index] = value
}
func (self *ChaliceSortExample) load(index int) int {
	return self.temp[index]
}
func (self *ChaliceSortExample) shiftForwardExternal(destination int, source int, end int) {
	var input int
	var output int
	output = destination
	for input = source; input < end; input++ {
		self.write(output, self.read(input))
		output += 1
	}
}
func (self *ChaliceSortExample) shiftBackwardExternal(start int, sourceEnd int, destinationEnd int) {
	var input int
	var output int
	input = sourceEnd
	output = destinationEnd
	for input > start {
		input -= 1
		output -= 1
		self.write(output, self.read(input))
	}
}
func (self *ChaliceSortExample) rightBinarySearch(start int, end int, value int) int {
	var lower int
	var middle int
	var upper int
	lower = start
	upper = end
	for lower < upper {
		middle = (lower + ((upper - lower) / 2))
		if self.read(middle) <= value {
			lower = (middle + 1)
		} else {
			upper = middle
		}
	}
	return lower
}
func (self *ChaliceSortExample) multiSwap(first int, second int, length int) {
	var offset int
	if !(length > 0) {
		return
	}
	for offset = 0; offset < length; offset++ {
		self.swap((first + offset), (second + offset))
	}
}
func (self *ChaliceSortExample) binaryInsertion(start int, end int) {
	var high int
	var index int
	var low int
	var middle int
	var value int
	if !((end - start) > 1) {
		return
	}
	for index = (start + 1); index < end; index++ {
		value = self.read(index)
		low = start
		high = index
		for low < high {
			middle = (low + ((high - low) / 2))
			if self.read(middle) > value {
				high = middle
			} else {
				low = (middle + 1)
			}
		}
		self.insertTo(index, low)
	}
}
func (self *ChaliceSortExample) ceilCbrt(value int) int {
	var high int
	var low int
	var middle int
	low = 0
	high = 11
	for low < high {
		middle = ((low + high) / 2)
		if (1 << (3 * middle)) >= value {
			high = middle
		} else {
			low = (middle + 1)
		}
	}
	return (1 << low)
}
func (self *ChaliceSortExample) calcKeys(blockLength int, count int) int {
	var high int
	var low int
	var middle int
	low = 1
	high = (count / 4)
	for low < high {
		middle = ((low + high) / 2)
		if ((((count - (4 * middle)) - 1) / blockLength) - 2) < middle {
			high = middle
		} else {
			low = (middle + 1)
		}
	}
	return low
}
func (self *ChaliceSortExample) leftBinSearch(startIn int, endIn int, value int) int {
	var end int
	var middle int
	var start int
	start = startIn
	end = endIn
	for start < end {
		middle = (start + ((end - start) / 2))
		if self.values[middle] >= value {
			end = middle
		} else {
			start = (middle + 1)
		}
	}
	return start
}
func (self *ChaliceSortExample) rotate(start int, middle int, end int) {
	var leftLength int
	var offset int
	var position int
	var rightLength int
	if !((start < middle) && (middle < end)) {
		return
	}
	position = start
	leftLength = (middle - start)
	rightLength = (end - middle)
	for (leftLength != 0) && (rightLength != 0) {
		if leftLength <= rightLength {
			for offset = 0; offset < leftLength; offset++ {
				self.swap((position + offset), ((position + leftLength) + offset))
			}
			position += leftLength
			rightLength -= leftLength
		} else {
			for offset = 0; offset < rightLength; offset++ {
				self.swap((((position + leftLength) - rightLength) + offset), ((position + leftLength) + offset))
			}
			leftLength -= rightLength
		}
	}
}
func (self *ChaliceSortExample) insertTo(source int, destination int) {
	var cursor int
	var value int
	value = self.read(source)
	cursor = source
	for cursor > destination {
		self.write(cursor, self.read((cursor - 1)))
		cursor -= 1
	}
	self.write(destination, value)
}
func (self *ChaliceSortExample) shiftForward(destination int, source int, end int) {
	var offset int
	if !(source < end) {
		return
	}
	for offset = 0; offset < (end - source); offset++ {
		self.swap((destination + offset), (source + offset))
	}
}
func (self *ChaliceSortExample) shiftBackward(start int, sourceEnd int, destinationEnd int) {
	var destination int
	var source int
	source = sourceEnd
	destination = destinationEnd
	for source > start {
		source -= 1
		destination -= 1
		self.swap(destination, source)
	}
}
func (self *ChaliceSortExample) mergeForwardExternal(startIn int, middle int, end int) {
	var left int
	var leftLength int
	var offset int
	var right int
	var start int
	leftLength = (middle - startIn)
	if !(leftLength > 0) {
		return
	}
	for offset = 0; offset < leftLength; offset++ {
		self.save(offset, self.read((startIn + offset)))
	}
	start = startIn
	left = 0
	right = middle
	for (left < leftLength) && (right < end) {
		if self.compareValues(self.load(left), self.read(right), "<=") {
			self.write(start, self.load(left))
			left += 1
		} else {
			self.write(start, self.read(right))
			right += 1
		}
		start += 1
	}
	for left < leftLength {
		self.write(start, self.load(left))
		left += 1
		start += 1
	}
}
func (self *ChaliceSortExample) mergeBackwardExternal(start int, middle int, endIn int) {
	var end int
	var left int
	var offset int
	var right int
	var rightLength int
	rightLength = (endIn - middle)
	if !(rightLength > 0) {
		return
	}
	for offset = 0; offset < rightLength; offset++ {
		self.save(offset, self.read((middle + offset)))
	}
	end = endIn
	right = (rightLength - 1)
	left = (middle - 1)
	for (right >= 0) && (left >= start) {
		end -= 1
		if self.compareValues(self.load(right), self.read(left), ">=") {
			self.write(end, self.load(right))
			right -= 1
		} else {
			self.write(end, self.read(left))
			left -= 1
		}
	}
	for right >= 0 {
		end -= 1
		self.write(end, self.load(right))
		right -= 1
	}
}
func (self *ChaliceSortExample) mergeWithBufferForward(startIn int, middle int, end int, destinationIn int, external bool) {
	var chooseLeft bool
	var destination int
	var right int
	var source int
	var start int
	start = startIn
	right = middle
	destination = destinationIn
	for (start < middle) && (right < end) {
		chooseLeft = self.compare(start, right, "<=")
		source = ternary(chooseLeft, start, right)
		if external {
			self.write(destination, self.read(source))
		} else {
			self.swap(destination, source)
		}
		if chooseLeft {
			start += 1
		} else {
			right += 1
		}
		destination += 1
	}
	if start > destination {
		if external {
			self.shiftForwardExternal(destination, start, middle)
		} else {
			self.shiftForward(destination, start, middle)
		}
	}
	if external {
		self.shiftForwardExternal(destination, right, end)
	} else {
		self.shiftForward(destination, right, end)
	}
}
func (self *ChaliceSortExample) mergeWithBufferBackward(start int, middle int, endIn int, destinationEndIn int, external bool) {
	var destinationEnd int
	var left int
	var right int
	left = (middle - 1)
	right = (endIn - 1)
	destinationEnd = destinationEndIn
	for (right >= middle) && (left >= start) {
		destinationEnd -= 1
		if self.compare(right, left, ">=") {
			if external {
				self.write(destinationEnd, self.read(right))
			} else {
				self.swap(destinationEnd, right)
			}
			right -= 1
		} else {
			if external {
				self.write(destinationEnd, self.read(left))
			} else {
				self.swap(destinationEnd, left)
			}
			left -= 1
		}
	}
	if destinationEnd > right {
		if external {
			self.shiftBackwardExternal(middle, (right + 1), destinationEnd)
		} else {
			self.shiftBackward(middle, (right + 1), destinationEnd)
		}
	}
	if external {
		self.shiftBackwardExternal(start, (left + 1), destinationEnd)
	} else {
		self.shiftBackward(start, (left + 1), destinationEnd)
	}
}
func (self *ChaliceSortExample) inPlaceMerge(startIn int, middleIn int, end int) {
	var insertion int
	var middle int
	var moved int
	var start int
	start = startIn
	middle = middleIn
	for (start < middle) && (middle < end) {
		start = self.rightBinarySearch(start, middle, self.read(middle))
		if start == middle {
			return
		}
		insertion = self.leftBinSearch(middle, end, self.read(start))
		self.rotate(start, middle, insertion)
		moved = (insertion - middle)
		middle = insertion
		start += (moved + 1)
	}
}
func (self *ChaliceSortExample) laziestSortExternal(start int, end int) {
	var cursor int
	var next int
	cursor = start
	for cursor < end {
		next = min(end, (cursor + len(self.temp)))
		self.binaryInsertion(cursor, next)
		if cursor > start {
			self.mergeBackwardExternal(start, cursor, next)
		}
		cursor = next
	}
}
func (self *ChaliceSortExample) findKeysSmall(start int, end int, otherStart int, otherEnd int, full bool, needed int) KeyGroup {
	var displaced int
	var first int
	var index int
	var last int
	var location int
	var otherLocation int
	first = start
	last = 0
	if full {
		last = 0
		for first < end {
			location = self.leftBinSearch(otherStart, otherEnd, self.read(first))
			if (location == otherEnd) || !(self.compare(first, location, "==")) {
				last = (first + 1)
				break
			}
			first += 1
		}
		if last != 0 {
			index = last
			for (index < end) && ((last - first) < needed) {
				otherLocation = self.leftBinSearch(otherStart, otherEnd, self.read(index))
				if (otherLocation == otherEnd) || !(self.compare(index, otherLocation, "==")) {
					location = self.leftBinSearch(first, last, self.read(index))
					if (location == last) || !(self.compare(index, location, "==")) {
						self.rotate(first, last, index)
						displaced = (index - last)
						first += displaced
						location += displaced
						last = (index + 1)
						self.insertTo(index, location)
					}
				}
				index += 1
			}
		} else {
			last = first
		}
	} else {
		last = (first + 1)
		index = last
		for (index < end) && ((last - first) < needed) {
			location = self.leftBinSearch(first, last, self.read(index))
			if (location == last) || !(self.compare(index, location, "==")) {
				self.rotate(first, last, index)
				displaced = (index - last)
				first += displaced
				location += displaced
				last = (index + 1)
				self.insertTo(index, location)
			}
			index += 1
		}
	}
	return KeyGroup{first, last}
}
func (self *ChaliceSortExample) findKeys(start int, end int, desired int, stride int) int {
	var first int
	var found int
	var group KeyGroup
	var last int
	var remaining int
	var secondStart int
	group = self.findKeysSmall(start, end, 0, 0, false, min(desired, stride))
	first = group.start
	last = group.end
	if (stride < desired) && ((last - first) == stride) {
		remaining = (desired - stride)
		for true {
			group = self.findKeysSmall(last, end, first, last, true, min(stride, remaining))
			found = (group.end - group.start)
			if found == 0 {
				break
			}
			if (found < stride) || (remaining == stride) {
				self.rotate(last, group.start, group.end)
				secondStart = last
				last += found
				self.mergeBackwardExternal(first, secondStart, last)
				break
			}
			self.rotate(first, last, group.start)
			first += (group.start - last)
			last = group.end
			self.mergeBackwardExternal(first, group.start, last)
			remaining -= stride
		}
	}
	self.rotate(start, first, last)
	return (last - first)
}
func (self *ChaliceSortExample) findBitsSmall(start int, end int, referenceIn int, backward bool, needed int) KeyGroup {
	var first int
	var index int
	var last int
	var reference int
	first = start
	reference = referenceIn
	for (first < end) && !(self.compare(first, reference, ternary(backward, "<", ">"))) {
		first += 1
	}
	reference += 1
	last = 0
	if first < end {
		last = (first + 1)
		index = last
		for (index < end) && ((last - first) < needed) {
			if self.compare(index, reference, ternary(backward, "<", ">")) {
				self.rotate(first, last, index)
				first += (index - last)
				last = (index + 1)
				reference += 1
			}
			index += 1
		}
	} else {
		last = first
	}
	return KeyGroup{first, last}
}
func (self *ChaliceSortExample) findBits(start int, end int, needed int, stride int) int {
	var count int
	var first int
	var firstCount int
	var found int
	var group KeyGroup
	var last int
	var phase int
	var reference int
	var referenceStart int
	self.laziestSortExternal(start, (start + needed))
	referenceStart = start
	reference = (start + needed)
	count = 0
	firstCount = 0
	for phase = 0; phase < 2; phase++ {
		if count >= needed {
			continue
		}
		first = reference
		last = first
		for true {
			group = self.findBitsSmall(last, end, (referenceStart + count), (phase == 1), min(stride, (needed-count)))
			found = (group.end - group.start)
			if found == 0 {
				break
			}
			count += found
			if (found < stride) || (count == needed) {
				self.rotate(last, group.start, group.end)
				last += found
				break
			}
			self.rotate(first, last, group.start)
			first += (group.start - last)
			last = group.end
		}
		self.rotate(reference, first, last)
		reference += (last - first)
		if phase == 0 {
			firstCount = count
		}
	}
	if count < needed {
		return -(1)
	}
	self.multiSwap((start + firstCount), ((start + needed) + firstCount), (needed - firstCount))
	return firstCount
}
func (self *ChaliceSortExample) bitReversal(start int, end int) {
	var current int
	var decrement int
	var half int
	var index int
	var jump int
	var length int
	var offset int
	var threeQuarters int
	length = (end - start)
	offset = 0
	half = (length / 2)
	threeQuarters = (half + (half / 2))
	if length < 3 {
		return
	}
	for index = 1; index < (length - 1); index++ {
		jump = half
		current = index
		decrement = threeQuarters
		for (current & 1) == 0 {
			jump -= decrement
			current >>= 1
			decrement >>= 1
		}
		offset += jump
		if offset > index {
			self.swap((start + index), (start + offset))
		}
	}
}
func (self *ChaliceSortExample) unshuffle(start int, end int) {
	var consumed int
	var position int
	var remaining int
	var width int
	remaining = ((end - start) / 2)
	consumed = 0
	width = 2
	for remaining > 0 {
		if (remaining & 1) == 1 {
			position = (start + consumed)
			self.bitReversal(position, (position + width))
			self.bitReversal(position, (position + (width / 2)))
			self.bitReversal((position + (width / 2)), (position + width))
			self.rotate((start + (consumed / 2)), position, (position + (width / 2)))
			consumed += width
		}
		remaining >>= 1
		width *= 2
	}
}
func (self *ChaliceSortExample) redistributeBuffer(startIn int, middleIn int, end int) {
	var insertion int
	var middle int
	var moved int
	var size int
	var start int
	start = startIn
	middle = middleIn
	size = len(self.temp)
	for ((middle - start) > size) && (middle < end) {
		insertion = self.leftBinSearch(middle, end, self.read((start + size)))
		self.rotate((start + size), middle, insertion)
		moved = (insertion - middle)
		middle = insertion
		self.mergeForwardExternal(start, (start + size), middle)
		start += (moved + size)
	}
	if middle < end {
		self.mergeForwardExternal(start, middle, end)
	}
}
func (self *ChaliceSortExample) copyMain(source int, destination int, length int) {
	var offset int
	if !((length > 0) && (source != destination)) {
		return
	}
	if destination > source {
		for offset = (length - 1); offset > (0 - 1); offset += -(1) {
			self.write((destination + offset), self.read((source + offset)))
		}
	} else {
		for offset = 0; offset < length; offset++ {
			self.write((destination + offset), self.read((source + offset)))
		}
	}
}
func (self *ChaliceSortExample) dualMergeBackward(startIn int, middleIn int, endIn int, destinationEndIn int, external bool) {
	var chooseLeft bool
	var destinationEnd int
	var end int
	var left int
	var middle int
	var right int
	var source int
	var start int
	start = startIn
	middle = middleIn
	end = (endIn - 1)
	destinationEnd = destinationEndIn
	left = (middle - 1)
	for (destinationEnd > (end + 1)) && (end >= middle) {
		destinationEnd -= 1
		if self.compare(end, left, ">=") {
			if external {
				self.write(destinationEnd, self.read(end))
			} else {
				self.swap(destinationEnd, end)
			}
			end -= 1
		} else {
			if external {
				self.write(destinationEnd, self.read(left))
			} else {
				self.swap(destinationEnd, left)
			}
			left -= 1
		}
	}
	if end < middle {
		if external {
			self.shiftBackwardExternal(start, (left + 1), destinationEnd)
		} else {
			self.shiftBackward(start, (left + 1), destinationEnd)
		}
	} else {
		left += 1
		end += 1
		destinationEnd = (middle - (left - start))
		right = middle
		for (start < left) && (right < end) {
			chooseLeft = self.compare(start, right, "<=")
			source = ternary(chooseLeft, start, right)
			if external {
				self.write(destinationEnd, self.read(source))
			} else {
				self.swap(destinationEnd, source)
			}
			if chooseLeft {
				start += 1
			} else {
				right += 1
			}
			destinationEnd += 1
		}
		for start < left {
			if external {
				self.write(destinationEnd, self.read(start))
			} else {
				self.swap(destinationEnd, start)
			}
			start += 1
			destinationEnd += 1
		}
	}
}
func (self *ChaliceSortExample) smartMerge(destinationIn int, startIn int, middle int, reversed bool) int {
	var chooseLeft bool
	var destination int
	var right int
	var start int
	destination = destinationIn
	start = startIn
	right = middle
	for start < middle {
		chooseLeft = ternary(reversed, self.compare(start, right, "<"), self.compare(start, right, "<="))
		if chooseLeft {
			self.write(destination, self.read(start))
			start += 1
		} else {
			self.write(destination, self.read(right))
			right += 1
		}
		destination += 1
	}
	return right
}
func (self *ChaliceSortExample) smartTailMerge(destinationIn int, startIn int, middle int, end int) {
	var blockLength int
	var bufferIndex int
	var destination int
	var offset int
	var right int
	var start int
	destination = destinationIn
	start = startIn
	right = middle
	blockLength = len(self.temp)
	for (start < middle) && (right < end) {
		if self.compare(start, right, "<=") {
			self.write(destination, self.read(start))
			start += 1
		} else {
			self.write(destination, self.read(right))
			right += 1
		}
		destination += 1
	}
	if start < middle {
		if start > destination {
			self.shiftForwardExternal(destination, start, middle)
		}
		for offset = 0; offset < blockLength; offset++ {
			self.write(((end - blockLength) + offset), self.load(offset))
		}
	} else {
		bufferIndex = 0
		for (bufferIndex < blockLength) && (right < end) {
			if self.compareValues(self.load(bufferIndex), self.read(right), "<=") {
				self.write(destination, self.load(bufferIndex))
				bufferIndex += 1
			} else {
				self.write(destination, self.read(right))
				right += 1
			}
			destination += 1
		}
		for bufferIndex < blockLength {
			self.write(destination, self.load(bufferIndex))
			bufferIndex += 1
			destination += 1
		}
	}
}
func (self *ChaliceSortExample) blockCycle(start int, tagStart int, sortedTags int, tagCount int, blockLength int) {
	var index int
	var next int
	var position int
	if !(tagCount > 1) {
		return
	}
	for index = 0; index < (tagCount - 1); index++ {
		if self.compare((tagStart+index), (sortedTags+index), ">") || ((index > 0) && self.compare((tagStart+index), ((sortedTags+index)-1), "<")) {
			self.copyMain((start + (index * blockLength)), (start - blockLength), blockLength)
			position = index
			next = (self.leftBinSearch(sortedTags, (sortedTags+tagCount), self.read((tagStart+index))) - sortedTags)
			for true {
				self.copyMain((start + (next * blockLength)), (start + (position * blockLength)), blockLength)
				self.swap((tagStart + index), (tagStart + next))
				position = next
				next = (self.leftBinSearch(sortedTags, (sortedTags+tagCount), self.read((tagStart+index))) - sortedTags)
				if !(next != index) {
					break
				}
			}
			self.copyMain((start - blockLength), (start + (position * blockLength)), blockLength)
		}
	}
}
func (self *ChaliceSortExample) blockCycleEasy(start int, tagStart int, sortedTags int, tagCount int, blockLength int) {
	var index int
	var next int
	if !(tagCount > 1) {
		return
	}
	for index = 0; index < (tagCount - 1); index++ {
		if self.compare((tagStart+index), (sortedTags+index), ">") || ((index > 0) && self.compare((tagStart+index), ((sortedTags+index)-1), "<")) {
			next = (self.leftBinSearch(sortedTags, (sortedTags+tagCount), self.read((tagStart+index))) - sortedTags)
			for true {
				self.multiSwap((start + (index * blockLength)), (start + (next * blockLength)), blockLength)
				self.swap((tagStart + index), (tagStart + next))
				next = (self.leftBinSearch(sortedTags, (sortedTags+tagCount), self.read((tagStart+index))) - sortedTags)
				if !(next != index) {
					break
				}
			}
		}
	}
}
func (self *ChaliceSortExample) inPlaceMergeBackward(start int, middleIn int, endIn int, reversed bool) int {
	var end int
	var finalEnd int
	var insertion int
	var middle int
	var moved int
	middle = middleIn
	end = endIn
	finalEnd = ternary(reversed, self.rightBinarySearch(middle, end, self.read((middle-1))), self.leftBinSearch(middle, end, self.read((middle-1))))
	end = finalEnd
	for (end > middle) && (middle > start) {
		insertion = ternary(reversed, self.leftBinSearch(start, middle, self.read((end-1))), self.rightBinarySearch(start, middle, self.read((end-1))))
		self.rotate(insertion, middle, end)
		moved = (middle - insertion)
		middle = insertion
		end -= (moved + 1)
		if middle == start {
			break
		}
		end = ternary(reversed, self.rightBinarySearch(middle, end, self.read((middle-1))), self.leftBinSearch(middle, end, self.read((middle-1))))
	}
	return finalEnd
}
func (self *ChaliceSortExample) blockMerge(start int, middle int, end int, leftTagCount int, tagCount int, tagStartIn int, sortedTagsIn int, firstBitsIn int, secondBitsIn int, blockLength int) {
	var bitsEnd int
	var firstBits int
	var fragment int
	var leftBlock int
	var leftTag int
	var nextBlock int
	var offset int
	var outputTag int
	var reversed bool
	var rightBlock int
	var rightTag int
	var secondBits int
	var sortedTags int
	var tagStart int
	if (end - middle) <= blockLength {
		self.mergeBackwardExternal(start, middle, end)
		return
	}
	self.insertTo(((tagStartIn + leftTagCount) - 1), tagStartIn)
	leftBlock = ((start + blockLength) - 1)
	rightBlock = ((middle + blockLength) - 1)
	leftTag = tagStartIn
	rightTag = (tagStartIn + leftTagCount)
	outputTag = sortedTagsIn
	firstBits = firstBitsIn
	secondBits = secondBitsIn
	for (leftTag < (tagStartIn + leftTagCount)) && (rightTag < (tagStartIn + tagCount)) {
		if self.compare(leftBlock, rightBlock, "<=") {
			self.swap(outputTag, leftTag)
			outputTag += 1
			leftTag += 1
			leftBlock += blockLength
		} else {
			self.swap(outputTag, rightTag)
			outputTag += 1
			rightTag += 1
			self.swap(firstBits, secondBits)
			rightBlock += blockLength
		}
		firstBits += 1
		secondBits += 1
	}
	for leftTag < (tagStartIn + leftTagCount) {
		self.swap(outputTag, leftTag)
		outputTag += 1
		leftTag += 1
		firstBits += 1
		secondBits += 1
	}
	for rightTag < (tagStartIn + tagCount) {
		self.swap(outputTag, rightTag)
		outputTag += 1
		rightTag += 1
		self.swap(firstBits, secondBits)
		firstBits += 1
		secondBits += 1
	}
	tagStart = sortedTagsIn
	sortedTags = tagStartIn
	self.heapSort(sortedTags, (sortedTags + tagCount))
	for offset = 0; offset < blockLength; offset++ {
		self.save(offset, self.read(((middle - blockLength) + offset)))
	}
	self.copyMain(start, (middle - blockLength), blockLength)
	self.blockCycle((start + blockLength), tagStart, sortedTags, tagCount, blockLength)
	self.multiSwap(tagStart, sortedTags, tagCount)
	firstBits -= tagCount
	secondBits -= tagCount
	fragment = (start + blockLength)
	nextBlock = fragment
	bitsEnd = (secondBits + tagCount)
	reversed = self.compare(firstBits, secondBits, ">")
	for true {
		for true {
			if reversed {
				self.swap(firstBits, secondBits)
			}
			firstBits += 1
			secondBits += 1
			nextBlock += blockLength
			if !((secondBits < bitsEnd) && self.compare(firstBits, secondBits, ternary(reversed, ">", "<"))) {
				break
			}
		}
		if secondBits == bitsEnd {
			self.smartTailMerge((fragment - blockLength), fragment, ternary(reversed, fragment, nextBlock), end)
			return
		}
		fragment = self.smartMerge((fragment - blockLength), fragment, nextBlock, reversed)
		reversed = !(reversed)
	}
}
func (self *ChaliceSortExample) blockMergeEasy(start int, middle int, end int, leftTail int, rightTail int, leftTagCount int, tagCount int, tagStartIn int, sortedTagsIn int, firstBitsIn int, secondBitsIn int, blockLength int) {

	var bitsEnd int
	var dataEnd int
	var dataStart int
	var firstBits int
	var fragment int
	var leftBlock int
	var leftTag int
	var nextBlock int
	var outputTag int
	var reversed bool
	var rightBlock int
	var rightTag int
	var secondBits int
	var sortedTags int
	var tagStart int
	if (end - middle) <= blockLength {
		_ = self.inPlaceMergeBackward(start, middle, end, false)
		return
	}
	dataStart = (start + leftTail)
	dataEnd = (end - rightTail)
	leftBlock = ((dataStart + blockLength) - 1)
	rightBlock = ((middle + blockLength) - 1)
	leftTag = sortedTagsIn
	rightTag = (sortedTagsIn + leftTagCount)
	outputTag = tagStartIn
	firstBits = firstBitsIn
	secondBits = secondBitsIn
	for (leftTag < (sortedTagsIn + leftTagCount)) && (rightTag < (sortedTagsIn + tagCount)) {
		if self.compare(leftBlock, rightBlock, "<=") {
			self.swap(leftTag, outputTag)
			leftTag += 1
			outputTag += 1
			leftBlock += blockLength
		} else {
			self.swap(rightTag, outputTag)
			rightTag += 1
			outputTag += 1
			self.swap(firstBits, secondBits)
			rightBlock += blockLength
		}
		firstBits += 1
		secondBits += 1
	}
	for leftTag < (sortedTagsIn + leftTagCount) {
		self.swap(leftTag, outputTag)
		leftTag += 1
		outputTag += 1
		firstBits += 1
		secondBits += 1
	}
	for rightTag < (sortedTagsIn + tagCount) {
		self.swap(rightTag, outputTag)
		rightTag += 1
		outputTag += 1
		self.swap(firstBits, secondBits)
		firstBits += 1
		secondBits += 1
	}
	tagStart = sortedTagsIn
	sortedTags = tagStartIn
	self.heapSort(sortedTags, (sortedTags + tagCount))
	self.blockCycleEasy(dataStart, tagStart, sortedTags, tagCount, blockLength)
	self.multiSwap(tagStart, sortedTags, tagCount)
	firstBits -= tagCount
	secondBits -= tagCount
	fragment = dataStart
	nextBlock = fragment
	bitsEnd = (secondBits + tagCount)
	reversed = self.compare(firstBits, secondBits, ">")
	for true {
		for true {
			if reversed {
				self.swap(firstBits, secondBits)
			}
			firstBits += 1
			secondBits += 1
			nextBlock += blockLength
			if !((secondBits < bitsEnd) && self.compare(firstBits, secondBits, ternary(reversed, ">", "<"))) {
				break
			}
		}
		if secondBits == bitsEnd {
			if !(reversed) {
				_ = self.inPlaceMergeBackward(dataStart, dataEnd, end, false)
			}
			self.inPlaceMerge(start, dataStart, end)
			return
		}
		fragment = self.inPlaceMergeBackward(fragment, nextBlock, (nextBlock + blockLength), reversed)
		reversed = !(reversed)
	}
}
func (self *ChaliceSortExample) sift(start int, rootIn int, limit int) {
	var child int
	var root int
	root = rootIn
	for ((root * 2) + 1) < limit {
		child = ((root * 2) + 1)
		if ((child + 1) < limit) && self.compare((start+child), ((start+child)+1), "<") {
			child += 1
		}
		if !(self.compare((start + root), (start + child), "<")) {
			return
		}
		self.swap((start + root), (start + child))
		root = child
	}
}
func (self *ChaliceSortExample) heapSort(start int, end int) {
	var count int
	var limit int
	var root int
	count = (end - start)
	if !(count > 1) {
		return
	}
	for root = ((count - 2) / 2); root > (0 - 1); root += -(1) {
		self.sift(start, root, count)
	}
	for limit = (count - 1); limit > (1 - 1); limit += -(1) {
		self.swap(start, (start + limit))
		self.sift(start, 0, limit)
	}
}
func (self *ChaliceSortExample) sort() {

	var bitEnd int
	var bitSeparation int
	var blockLength int
	var count int
	var cubeRoot int
	var dataLength int
	var dataStart int
	var end int
	var index int
	var keyEnd int
	var keyLength int
	var keys int
	var leftTail int
	var limit int
	var middle int
	var minimumLevel int
	var offset int
	var runLength int
	var start int
	var tagCount int
	var vacant int
	count = len(self.values)
	start = 0
	end = count
	cubeRoot = (2 * self.ceilCbrt((count / 4)))
	blockLength = (2 * cubeRoot)
	keyLength = self.calcKeys(blockLength, count)
	self.temp = make([]int, blockLength)
	keys = self.findKeys(start, end, (2 * keyLength), cubeRoot)
	if keys < 8 {
		runLength = 1
		for runLength < count {
			middle = (start + runLength)
			for middle < end {
				_ = self.inPlaceMergeBackward((middle - runLength), middle, min((middle+runLength), end), false)
				middle += (2 * runLength)
			}
			runLength *= 2
		}
		return
	}
	if keys < (2 * keyLength) {
		keys -= (keys % 4)
		keyLength = (keys / 2)
	}
	keyEnd = (start + keys)
	bitEnd = (keyEnd + keys)
	bitSeparation = self.findBits(keyEnd, end, keyLength, cubeRoot)
	if bitSeparation == -(1) {
		self.laziestSortExternal(start, bitEnd)
		self.inPlaceMerge(start, bitEnd, end)
		return
	}
	dataStart = (bitEnd + blockLength)
	dataLength = (end - dataStart)
	self.binaryInsertion(bitEnd, dataStart)
	for offset = 0; offset < blockLength; offset++ {
		self.save(offset, self.read((bitEnd + offset)))
	}
	runLength = 1
	for runLength < cubeRoot {
		vacant = max(2, runLength)
		index = dataStart
		for (index + (2 * runLength)) < end {
			self.mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - vacant), true)
			index += (2 * runLength)
		}
		if (index + runLength) < end {
			self.mergeWithBufferForward(index, (index + runLength), end, (index - vacant), true)
		} else {
			self.shiftForwardExternal((index - vacant), index, end)
		}
		dataStart -= vacant
		end -= vacant
		runLength *= 2
	}
	index = (end - (dataLength % (2 * runLength)))
	if (index + runLength) < end {
		self.mergeWithBufferBackward(index, (index + runLength), end, (end + runLength), true)
	} else {
		self.shiftBackwardExternal(index, end, (end + runLength))
	}
	index -= (2 * runLength)
	for index >= dataStart {
		self.mergeWithBufferBackward(index, (index + runLength), (index + (2 * runLength)), (index + (3 * runLength)), true)
		index -= (2 * runLength)
	}
	dataStart += runLength
	end += runLength
	runLength *= 2
	index = dataStart
	for (index + (2 * runLength)) < end {
		self.mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - runLength), true)
		index += (2 * runLength)
	}
	if (index + runLength) < end {
		self.mergeWithBufferForward(index, (index + runLength), end, (index - runLength), true)
	} else {
		self.shiftForwardExternal((index - runLength), index, end)
	}
	dataStart -= runLength
	end -= runLength
	runLength *= 2
	index = (end - (dataLength % (2 * runLength)))
	if (index + runLength) < end {
		self.dualMergeBackward(index, (index + runLength), end, (end + (runLength / 2)), true)
	} else {
		self.shiftBackwardExternal(index, end, (end + (runLength / 2)))
	}
	index -= (2 * runLength)
	for index >= dataStart {
		self.dualMergeBackward(index, (index + runLength), (index + (2 * runLength)), ((index + (2 * runLength)) + (runLength / 2)), true)
		index -= (2 * runLength)
	}
	dataStart += (runLength / 2)
	end += (runLength / 2)
	runLength *= 2
	if keys >= runLength {
		self.rotate(start, keyEnd, dataStart)
		bitEnd = (keyEnd + blockLength)
		if keyLength >= runLength {
			minimumLevel = (2 * runLength)
			for runLength < keyLength {
				vacant = max(minimumLevel, runLength)
				index = dataStart
				for (index + (2 * runLength)) < end {
					self.mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - vacant), false)
					index += (2 * runLength)
				}
				if (index + runLength) < end {
					self.mergeWithBufferForward(index, (index + runLength), end, (index - vacant), false)
				} else {
					self.shiftForward((index - vacant), index, end)
				}
				dataStart -= vacant
				end -= vacant
				runLength *= 2
			}
			index = (end - (dataLength % (2 * runLength)))
			if (index + runLength) < end {
				self.mergeWithBufferBackward(index, (index + runLength), end, (end + runLength), false)
			} else {
				self.shiftBackward(index, end, (end + runLength))
			}
			index -= (2 * runLength)
			for index >= dataStart {
				self.mergeWithBufferBackward(index, (index + runLength), (index + (2 * runLength)), (index + (3 * runLength)), false)
				index -= (2 * runLength)
			}
			dataStart += runLength
			end += runLength
			runLength *= 2
		}
		if keys >= runLength {
			index = dataStart
			for (index + (2 * runLength)) < end {
				self.mergeWithBufferForward(index, (index + runLength), (index + (2 * runLength)), (index - runLength), false)
				index += (2 * runLength)
			}
			if (index + runLength) < end {
				self.mergeWithBufferForward(index, (index + runLength), end, (index - runLength), false)
			} else {
				self.shiftForward((index - runLength), index, end)
			}
			dataStart -= runLength
			end -= runLength
			runLength *= 2
			index = (end - (dataLength % (2 * runLength)))
			if (index + runLength) < end {
				self.dualMergeBackward(index, (index + runLength), end, (end + (runLength / 2)), false)
			} else {
				self.shiftBackward(index, end, (end + (runLength / 2)))
			}
			index -= (2 * runLength)
			for index >= dataStart {
				self.dualMergeBackward(index, (index + runLength), (index + (2 * runLength)), ((index + (2 * runLength)) + (runLength / 2)), false)
				index -= (2 * runLength)
			}
			dataStart += (runLength / 2)
			end += (runLength / 2)
			runLength *= 2
		}
		self.rotate(start, bitEnd, dataStart)
		bitEnd = (keyEnd + keys)
		self.heapSort(start, keyEnd)
	}
	for offset = 0; offset < blockLength; offset++ {
		self.write((bitEnd + offset), self.load(offset))
	}
	self.unshuffle(start, keyEnd)
	limit = (blockLength * (keyLength + 2))
	tagCount = ((runLength / blockLength) - 1)
	for (runLength < dataLength) && (min((2*runLength), dataLength) <= limit) {
		index = dataStart
		for (index + (2 * runLength)) <= end {
			self.blockMerge(index, (index + runLength), (index + (2 * runLength)), tagCount, (2 * tagCount), start, (start + keyLength), keyEnd, (keyEnd + keyLength), blockLength)
			index += (2 * runLength)
		}
		if (index + runLength) < end {
			self.blockMerge(index, (index + runLength), end, tagCount, ((((end - index) - 1) / blockLength) - 1), start, (start + keyLength), keyEnd, (keyEnd + keyLength), blockLength)
		}
		runLength *= 2
		tagCount = ((2 * tagCount) + 1)
	}
	for runLength < dataLength {
		blockLength = ((2 * runLength) / keyLength)
		leftTail = (runLength % blockLength)
		index = dataStart
		for (index + (2 * runLength)) <= end {
			self.blockMergeEasy(index, (index + runLength), (index + (2 * runLength)), leftTail, leftTail, (keyLength / 2), keyLength, start, (start + keyLength), keyEnd, (keyEnd + keyLength), blockLength)
			index += (2 * runLength)
		}
		if (index + runLength) < end {
			self.blockMergeEasy(index, (index + runLength), end, leftTail, (((end - index) - runLength) % blockLength), (keyLength / 2), ((keyLength / 2) + (((end - index) - runLength) / blockLength)), start, (start + keyLength), keyEnd, (keyEnd + keyLength), blockLength)
		}
		runLength *= 2
	}
	self.multiSwap((keyEnd + bitSeparation), ((keyEnd + keyLength) + bitSeparation), (keyLength - bitSeparation))
	self.laziestSortExternal(start, dataStart)
	self.redistributeBuffer(start, dataStart, end)
}
func chaliceSort(values []int) {
	if len(values) >= 32 && len(values) < 128 {
		sort(values)
	} else {
		self := &ChaliceSortExample{values: values}
		if len(values) < 32 {
			self.binaryInsertion(0, len(values))
		} else {
			self.sort()
		}
	}
}
func main() {
	values := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	chaliceSort(values)
	fmt.Println(values)
}
