// MIT License
// Copyright (c) 2013 Andrey Astrelin
// Copyright (c) 2020 The Holy Grail Sort Project
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

type AdaptiveGrailExample struct {
	values    []int
	n, minRun int
}

func min_int(a, b int) int {
	if a < b {
		return a
	}
	return b
}
func max_int(a, b int) int {
	if a > b {
		return a
	}
	return b
}
func read(self *AdaptiveGrailExample, index int) int {
	return self.values[index]
}
func write(self *AdaptiveGrailExample, index int, value int) {
	self.values[index] = value
}
func swap(self *AdaptiveGrailExample, first int, second int) {
	_sim0_0 := self.values[second]
	_sim0_1 := self.values[first]
	self.values[first] = _sim0_0
	self.values[second] = _sim0_1
}
func compare(self *AdaptiveGrailExample, first int, second int) int {
	if self.values[first] < self.values[second] {
		return -(1)
	}
	if self.values[first] > self.values[second] {
		return 1
	}
	return 0
}
func compareValue(self *AdaptiveGrailExample, index int, value int) int {
	if self.values[index] < value {
		return -(1)
	}
	if self.values[index] > value {
		return 1
	}
	return 0
}
func reverse(self *AdaptiveGrailExample, start int, end int) {
	var left, right int
	left = start
	right = (end - 1)
	for left < right {
		_sim1_0 := self.values[right]
		_sim1_1 := self.values[left]
		self.values[left] = _sim1_0
		self.values[right] = _sim1_1
		left += 1
		right -= 1
	}
}
func multiSwap(self *AdaptiveGrailExample, first int, second int, count int) {
	var offset int
	if !(count > 0) {
		return
	}
	for offset = 0; offset < count; offset++ {
		swap(self, (first + offset), (second + offset))
	}
}
func multiTriSwap(self *AdaptiveGrailExample, first int, second int, third int, count int) {
	var offset, value int
	if !(count > 0) {
		return
	}
	for offset = 0; offset < count; offset++ {
		value = read(self, (first + offset))
		write(self, (first + offset), read(self, (second+offset)))
		write(self, (second + offset), read(self, (third+offset)))
		write(self, (third + offset), value)
	}
}
func insertTo(self *AdaptiveGrailExample, source int, destination int) {
	var cursor, value int
	value = read(self, source)
	cursor = source
	for cursor > destination {
		write(self, cursor, read(self, (cursor-1)))
		cursor -= 1
	}
	write(self, destination, value)
}
func insertToBackward(self *AdaptiveGrailExample, source int, destination int) {
	var cursor, value int
	value = read(self, source)
	cursor = source
	for cursor < destination {
		write(self, cursor, read(self, (cursor+1)))
		cursor += 1
	}
	write(self, cursor, value)
}
func shift(self *AdaptiveGrailExample, destination int, source int, end int) {
	var offset int
	if !(source < end) {
		return
	}
	for offset = 0; offset < (end - source); offset++ {
		swap(self, (destination + offset), (source + offset))
	}
}
func rotate(self *AdaptiveGrailExample, startIn int, middleIn int, endIn int) {
	var end, left, middle, right, start int
	start = startIn
	middle = middleIn
	end = endIn
	left = (middle - start)
	right = (end - middle)
	for (left > 1) && (right > 1) {
		if right < left {
			multiSwap(self, (middle - right), middle, right)
			end -= right
			middle -= right
			left -= right
		} else {
			multiSwap(self, start, middle, left)
			start += left
			middle += left
			right -= left
		}
	}
	if right == 1 {
		insertTo(self, middle, start)
	} else {
		if left == 1 {
			insertToBackward(self, start, (end - 1))
		}
	}
}
func leftBinarySearch(self *AdaptiveGrailExample, start int, end int, value int) int {
	var lower, middle, upper int
	lower = start
	upper = end
	for lower < upper {
		middle = (lower + ((upper - lower) / 2))
		if self.values[middle] >= value {
			upper = middle
		} else {
			lower = (middle + 1)
		}
	}
	return lower
}
func rightBinarySearch(self *AdaptiveGrailExample, start int, end int, value int) int {
	var lower, middle, upper int
	lower = start
	upper = end
	for lower < upper {
		middle = (lower + ((upper - lower) / 2))
		if self.values[middle] > value {
			upper = middle
		} else {
			lower = (middle + 1)
		}
	}
	return lower
}
func buildUniqueRun(self *AdaptiveGrailExample, start int, limit int) int {
	var count, index, order int
	count = 1
	index = (start + 1)
	order = compare(self, (index - 1), index)
	if order < 0 {
		index += 1
		count += 1
		for (count < limit) && (compare(self, (index-1), index) < 0) {
			index += 1
			count += 1
		}
	} else {
		if order > 0 {
			index += 1
			count += 1
			for (count < limit) && (compare(self, (index-1), index) > 0) {
				index += 1
				count += 1
			}
			reverse(self, start, index)
		}
	}
	return count
}
func buildUniqueRunBackward(self *AdaptiveGrailExample, end int, limit int) int {
	var count, index, order int
	count = 1
	index = (end - 1)
	order = compare(self, (index - 1), index)
	if order < 0 {
		index -= 1
		count += 1
		for (count < limit) && (compare(self, (index-1), index) < 0) {
			index -= 1
			count += 1
		}
	} else {
		if order > 0 {
			index -= 1
			count += 1
			for (count < limit) && (compare(self, (index-1), index) > 0) {
				index -= 1
				count += 1
			}
			reverse(self, index, end)
		}
	}
	return count
}
func findKeys(self *AdaptiveGrailExample, start int, end int, initial int, needed int) int {
	var candidate, count, distance, index, keyEnd, keyStart, location int
	count = initial
	keyStart = start
	keyEnd = (start + count)
	index = keyEnd
	for (index < end) && (count < needed) {
		candidate = read(self, index)
		location = leftBinarySearch(self, keyStart, keyEnd, candidate)
		if (location == keyEnd) || (compareValue(self, location, candidate) != 0) {
			rotate(self, keyStart, keyEnd, index)
			distance = (index - keyEnd)
			location += distance
			keyStart += distance
			keyEnd += distance
			insertTo(self, keyEnd, location)
			count += 1
			keyEnd += 1
		}
		index += 1
	}
	rotate(self, start, keyStart, keyEnd)
	return count
}
func findKeysBackward(self *AdaptiveGrailExample, start int, end int, initial int, needed int) int {
	var candidate, count, distance, index, keyEnd, keyStart, location int
	count = initial
	keyStart = (end - count)
	keyEnd = end
	index = (keyStart - 1)
	for (index >= start) && (count < needed) {
		candidate = read(self, index)
		location = leftBinarySearch(self, keyStart, keyEnd, candidate)
		if (location == keyEnd) || (compareValue(self, location, candidate) != 0) {
			rotate(self, (index + 1), keyStart, keyEnd)
			distance = (keyStart - (index + 1))
			location -= distance
			keyEnd -= distance
			keyStart -= (distance + 1)
			count += 1
			insertToBackward(self, index, (location - 1))
		}
		index -= 1
	}
	rotate(self, keyStart, keyEnd, end)
	return count
}
func buildRuns(self *AdaptiveGrailExample, start int, end int) {
	var index, runStart int
	index = (start + 1)
	runStart = start
	for index < end {
		if compare(self, (index-1), index) > 0 {
			index += 1
			for (index < end) && (compare(self, (index-1), index) > 0) {
				index += 1
			}
			reverse(self, runStart, index)
		} else {
			index += 1
			for (index < end) && (compare(self, (index-1), index) <= 0) {
				index += 1
			}
		}
		if index < end {
			runStart = ((index - (((index - runStart) - 1) % self.minRun)) - 1)
		}
		for ((index - runStart) < self.minRun) && (index < end) {
			insertTo(self, index, rightBinarySearch(self, runStart, index, read(self, index)))
			index += 1
		}
		runStart = index
		index += 1
	}
}
func binaryInsertion(self *AdaptiveGrailExample, start int, end int) {
	var index int
	if !((end - start) > 1) {
		return
	}
	for index = (start + 1); index < end; index++ {
		insertTo(self, index, rightBinarySearch(self, start, index, read(self, index)))
	}
}
func mergeWithBufferRest(self *AdaptiveGrailExample, start int, middle int, end int, buffer int, length int) {
	var left, output, right int
	left = 0
	right = middle
	output = start
	for (left < length) && (right < end) {
		if compare(self, (buffer+left), right) <= 0 {
			swap(self, output, (buffer + left))
			left += 1
		} else {
			swap(self, output, right)
			right += 1
		}
		output += 1
	}
	for left < length {
		swap(self, output, (buffer + left))
		output += 1
		left += 1
	}
}
func mergeWithBuffer(self *AdaptiveGrailExample, start int, middle int, end int, buffer int) {
	var length int
	length = (middle - start)
	multiSwap(self, buffer, start, length)
	mergeWithBufferRest(self, start, middle, end, buffer, length)
}
func mergeWithBufferBackward(self *AdaptiveGrailExample, start int, middle int, end int, buffer int) {
	var left, length, output, right int
	length = (end - middle)
	multiSwap(self, middle, buffer, length)
	left = (length - 1)
	right = (middle - 1)
	output = (end - 1)
	for (left >= 0) && (right >= start) {
		if compare(self, (buffer+left), right) >= 0 {
			swap(self, output, (buffer + left))
			left -= 1
		} else {
			swap(self, output, right)
			right -= 1
		}
		output -= 1
	}
	for left >= 0 {
		swap(self, output, (buffer + left))
		output -= 1
		left -= 1
	}
}
func inPlaceMerge(self *AdaptiveGrailExample, start int, middle int, end int) {
	var left, next, right int
	left = start
	right = middle
	for (left < right) && (right < end) {
		if compare(self, left, right) > 0 {
			next = leftBinarySearch(self, (right + 1), end, read(self, left))
			rotate(self, left, right, next)
			left += (next - right)
			right = next
		} else {
			left += 1
		}
	}
}
func inPlaceMergeBackward(self *AdaptiveGrailExample, start int, middle int, end int) {
	var left, next, right int
	left = (middle - 1)
	right = (end - 1)
	for (right > left) && (left >= start) {
		if compare(self, left, right) > 0 {
			next = rightBinarySearch(self, start, left, read(self, right))
			rotate(self, next, (left + 1), (right + 1))
			right -= ((left + 1) - next)
			left = (next - 1)
		} else {
			right -= 1
		}
	}
}
func mergeWithoutBuffer(self *AdaptiveGrailExample, start int, middle int, end int) {
	if (middle - start) > (end - middle) {
		inPlaceMergeBackward(self, start, middle, end)
	} else {
		inPlaceMerge(self, start, middle, end)
	}
}
func checkSorted(self *AdaptiveGrailExample, middle int) bool {
	return (compare(self, (middle-1), middle) > 0)
}
func checkReverseBounds(self *AdaptiveGrailExample, start int, middle int, end int) bool {
	if compare(self, start, (end-1)) > 0 {
		rotate(self, start, middle, end)
		return false
	}
	return true
}
func checkBounds(self *AdaptiveGrailExample, start int, middle int, end int) bool {
	return (checkSorted(self, middle) && checkReverseBounds(self, start, middle, end))
}
func subarray(self *AdaptiveGrailExample, tag int, middleKey int) int {
	if compare(self, tag, middleKey) < 0 {
		return 0
	}
	return 1
}
func blockSelectSort(self *AdaptiveGrailExample, position int, tags int, offset int, distance int, leftCount int, blockCount int, blockLength int) int {
	var candidate, index, limit, middleKey, minimum, order int
	middleKey = leftCount
	index = 0
	limit = (leftCount + 1)
	for index < (limit - 1) {
		minimum = index
		candidate = max_int((leftCount - offset), (index + 1))
		for candidate < limit {
			order = compare(self, ((position + distance) + (candidate * blockLength)), ((position + distance) + (minimum * blockLength)))
			if (order < 0) || ((order == 0) && (compare(self, (tags+candidate), (tags+minimum)) < 0)) {
				minimum = candidate
			}
			candidate += 1
		}
		if minimum != index {
			multiSwap(self, (position + (index * blockLength)), (position + (minimum * blockLength)), blockLength)
			swap(self, (tags + index), (tags + minimum))
			if (limit < blockCount) && (minimum == (limit - 1)) {
				limit += 1
			}
		}
		if minimum == middleKey {
			middleKey = index
		}
		index += 1
	}
	return (tags + middleKey)
}
func sortKeys(self *AdaptiveGrailExample, end int, buffer int, middleKey int) {
	var index, left, right int
	swap(self, buffer, middleKey)
	left = middleKey
	index = (left + 1)
	right = (buffer + 1)
	for index < end {
		if compare(self, index, buffer) < 0 {
			swap(self, left, index)
			left += 1
		} else {
			swap(self, right, index)
			right += 1
		}
		index += 1
	}
	multiSwap(self, left, buffer, (end - left))
}
func sortKeysWithoutBuffer(self *AdaptiveGrailExample, end int, middleKey int) {
	var index, left int
	left = middleKey
	index = (left + 1)
	for index < end {
		if compare(self, index, left) < 0 {
			insertTo(self, index, left)
			left += 1
		}
		index += 1
	}
}
func mergeBlocks(self *AdaptiveGrailExample, start int, middle int, end int, destination int, reverseEqual bool) int {
	var left, order, output, right int
	left = start
	right = middle
	output = destination
	for (left < middle) && (right < end) {
		order = compare(self, left, right)
		if (order < 0) || ((order == 0) && !(reverseEqual)) {
			swap(self, output, left)
			left += 1
		} else {
			swap(self, output, right)
			right += 1
		}
		output += 1
	}
	if left > output {
		for left < middle {
			swap(self, output, left)
			output += 1
			left += 1
		}
	}
	return right
}
func blockMerge(self *AdaptiveGrailExample, start int, middle int, end int, tags int, buffer int, blockLength int) {
	var blockCount, fragment, group, key, lastFull, left, leftBlocks, leftCount, middleKey, rightBlocks int
	lastFull = ((end - (((end - middle) - 1) % blockLength)) - 1)
	left = (start + blockLength)
	group = start
	key = (tags - 1)
	leftCount = ((middle - left) / blockLength)
	blockCount = ((lastFull - left) / blockLength)
	leftBlocks = -(1)
	rightBlocks = (leftCount - 1)
	multiTriSwap(self, buffer, (middle - blockLength), start, blockLength)
	insertToBackward(self, tags, ((tags + leftCount) - 1))
	middleKey = blockSelectSort(self, left, tags, 1, (blockLength - 1), leftCount, blockCount, blockLength)
	fragment = 0
	for (leftBlocks < leftCount) && (rightBlocks < blockCount) {
		if fragment == 0 {
			for true {
				group += blockLength
				leftBlocks += 1
				key += 1
				if !((leftBlocks < leftCount) && (subarray(self, key, middleKey) == 0)) {
					break
				}
			}
			if leftBlocks == leftCount {
				left = mergeBlocks(self, left, group, end, (left - blockLength), false)
				mergeWithBufferRest(self, (left - blockLength), left, end, buffer, blockLength)
			} else {
				left = mergeBlocks(self, left, group, ((group + blockLength) - 1), (left - blockLength), false)
			}
			fragment = 1
		} else {
			for true {
				group += blockLength
				rightBlocks += 1
				key += 1
				if !((rightBlocks < blockCount) && (subarray(self, key, middleKey) == 1)) {
					break
				}
			}
			if rightBlocks == blockCount {
				shift(self, (left - blockLength), left, end)
				multiSwap(self, buffer, (end - blockLength), blockLength)
			} else {
				left = mergeBlocks(self, left, group, ((group + blockLength) - 1), (left - blockLength), true)
			}
			fragment = 0
		}
	}
	sortKeys(self, (tags + blockCount), buffer, middleKey)
}
func blockMergeWithoutBuffer(self *AdaptiveGrailExample, start int, middle int, end int, tags int, blockLength int) {
	var blockCount, end2, firstFull, fragment, group, key, lastFull, left, leftBlocks, leftCount, middle2, middleKey, next, nextPosition, rightBlocks int
	firstFull = (start + ((middle - start) % blockLength))
	lastFull = (end - ((end - middle) % blockLength))
	left = start
	group = firstFull
	key = tags
	leftCount = (((middle - group) / blockLength) + 1)
	blockCount = (((lastFull - group) / blockLength) + 1)
	leftBlocks = 0
	rightBlocks = leftCount
	middleKey = blockSelectSort(self, group, tags, 0, 0, (leftCount - 1), (blockCount - 1), blockLength)
	fragment = 0
	for (leftBlocks < leftCount) && (rightBlocks < blockCount) {
		next = subarray(self, key, middleKey)
		key += 1
		if next == fragment {
			if fragment == 0 {
				leftBlocks += 1
			} else {
				rightBlocks += 1
			}
			left = group
		} else {
			middle2 = group
			end2 = (group + blockLength)
			if fragment == 0 {
				for (left < middle2) && (middle2 < end2) {
					if compare(self, left, middle2) > 0 {
						nextPosition = leftBinarySearch(self, (middle2 + 1), end2, read(self, left))
						rotate(self, left, middle2, nextPosition)
						left += (nextPosition - middle2)
						middle2 = nextPosition
					} else {
						left += 1
					}
				}
			} else {
				for (left < middle2) && (middle2 < end2) {
					if compare(self, left, middle2) >= 0 {
						nextPosition = rightBinarySearch(self, (middle2 + 1), end2, read(self, left))
						rotate(self, left, middle2, nextPosition)
						left += (nextPosition - middle2)
						middle2 = nextPosition
					} else {
						left += 1
					}
				}
			}
			if left < middle2 {
				if next == 0 {
					leftBlocks += 1
				} else {
					rightBlocks += 1
				}
			} else {
				if fragment == 0 {
					leftBlocks += 1
				} else {
					rightBlocks += 1
				}
				fragment = next
			}
		}
		group += blockLength
	}
	if leftBlocks < leftCount {
		inPlaceMergeBackward(self, start, lastFull, end)
	}
	sortKeysWithoutBuffer(self, ((tags + blockCount) - 1), middleKey)
}
func smartMerge(self *AdaptiveGrailExample, start int, middle int, end int, buffer int) {
	var trimmed int
	if checkBounds(self, start, middle, end) {
		trimmed = rightBinarySearch(self, start, (middle - 1), read(self, middle))
		mergeWithBuffer(self, trimmed, middle, end, buffer)
	}
}
func smartMergeBackward(self *AdaptiveGrailExample, start int, middle int, end int, buffer int) {
	var trimmed int
	if checkBounds(self, start, middle, end) {
		trimmed = leftBinarySearch(self, (middle + 1), end, read(self, (middle-1)))
		mergeWithBufferBackward(self, start, middle, trimmed, buffer)
	}
}
func smartBlockMerge(self *AdaptiveGrailExample, start int, middle int, end int, tags int, buffer int, blockLength int) {
	var trimmedEnd, trimmedStart int
	if checkBounds(self, start, middle, end) {
		trimmedStart = rightBinarySearch(self, start, (middle - 1), read(self, middle))
		trimmedEnd = leftBinarySearch(self, (middle + 1), end, read(self, (middle-1)))
		if checkReverseBounds(self, trimmedStart, middle, trimmedEnd) {
			if ((middle - trimmedStart) <= blockLength) || ((trimmedEnd - middle) <= blockLength) {
				if (trimmedEnd - middle) < (middle - trimmedStart) {
					mergeWithBufferBackward(self, trimmedStart, middle, trimmedEnd, buffer)
				} else {
					mergeWithBuffer(self, trimmedStart, middle, trimmedEnd, buffer)
				}
			} else {
				trimmedStart -= ((trimmedStart - start) % blockLength)
				blockMerge(self, trimmedStart, middle, trimmedEnd, tags, buffer, blockLength)
			}
		}
	}
}
func smartBlockMergeWithoutBuffer(self *AdaptiveGrailExample, start int, middle int, end int, tags int, blockLength int) {
	var trimmedStart int
	if checkBounds(self, start, middle, end) {
		trimmedStart = rightBinarySearch(self, start, (middle - 1), read(self, middle))
		if (middle - trimmedStart) <= blockLength {
			inPlaceMerge(self, trimmedStart, middle, end)
		} else {
			blockMergeWithoutBuffer(self, trimmedStart, middle, end, tags, blockLength)
		}
	}
}
func smartInPlaceMerge(self *AdaptiveGrailExample, start int, middle int, end int) {
	if checkSorted(self, middle) {
		inPlaceMergeBackward(self, start, middle, end)
	}
}
func redistributeBuffer(self *AdaptiveGrailExample, startIn int, middleIn int, end int) {
	var distance, leftMiddle, middle, right, start int
	start = startIn
	middle = middleIn
	right = leftBinarySearch(self, middle, end, read(self, start))
	rotate(self, start, middle, right)
	distance = (right - middle)
	start += distance
	middle += distance
	leftMiddle = (start + ((middle - start) / 2))
	right = leftBinarySearch(self, middle, end, read(self, leftMiddle))
	rotate(self, leftMiddle, middle, right)
	distance = (right - middle)
	leftMiddle += distance
	middle += distance
	mergeWithoutBuffer(self, start, (leftMiddle - distance), leftMiddle)
	mergeWithoutBuffer(self, leftMiddle, middle, end)
}
func redistributeBufferBackward(self *AdaptiveGrailExample, start int, middleIn int, endIn int) {
	var distance, end, middle, right, rightMiddle int
	middle = middleIn
	end = endIn
	right = rightBinarySearch(self, start, middle, read(self, (end-1)))
	rotate(self, right, middle, end)
	distance = (middle - right)
	end -= distance
	middle -= distance
	rightMiddle = (middle + ((end - middle) / 2))
	right = rightBinarySearch(self, start, middle, read(self, (rightMiddle-1)))
	rotate(self, right, middle, rightMiddle)
	distance = (middle - right)
	rightMiddle -= distance
	middle -= distance
	mergeWithoutBuffer(self, rightMiddle, (rightMiddle + distance), end)
	mergeWithoutBuffer(self, start, middle, rightMiddle)
}
func inPlaceMergeSort(self *AdaptiveGrailExample, start int, end int) {
	var index, run int
	buildRuns(self, start, end)
	run = self.minRun
	for run < (end - start) {
		index = start
		for (index + (2 * run)) <= end {
			smartInPlaceMerge(self, index, (index + run), (index + (2 * run)))
			index += (2 * run)
		}
		if (index + run) < end {
			smartInPlaceMerge(self, index, (index + run), end)
		}
		run *= 2
	}
}
func adaptiveSortWithoutBuffer(self *AdaptiveGrailExample, startIn int, endIn int, keys int, ideal int, backwardBuffer bool) {
	var blockLength, buffer, dataEnd, dataStart, end, index, length, runLength, start, tagLength, tags int
	start = startIn
	end = endIn
	length = (end - start)
	blockLength = min_int(keys, self.minRun)
	for (2 * blockLength) <= keys {
		blockLength *= 2
	}
	tagLength = (keys - blockLength)
	runLength = self.minRun
	tags = 0
	buffer = 0
	dataStart = 0
	dataEnd = 0
	if backwardBuffer {
		buffer = (end - blockLength)
		dataStart = start
		dataEnd = (buffer - tagLength)
		tags = dataEnd
	} else {
		buffer = (start + tagLength)
		dataStart = (buffer + blockLength)
		dataEnd = end
		tags = start
	}
	buildRuns(self, dataStart, dataEnd)
	for (runLength <= blockLength) && (runLength < length) {
		index = dataStart
		for (index + (2 * runLength)) <= dataEnd {
			smartMerge(self, index, (index + runLength), (index + (2 * runLength)), buffer)
			index += (2 * runLength)
		}
		if (index + runLength) < dataEnd {
			smartMergeBackward(self, index, (index + runLength), dataEnd, buffer)
		}
		runLength *= 2
	}
	if ((blockLength / 2) >= self.minRun) && ((blockLength / 2) >= ((keys + 1) / 2)) {
		binaryInsertion(self, buffer, (buffer + blockLength))
		blockLength = (blockLength / 2)
		tagLength = (keys - blockLength)
		buffer += blockLength
	}
	for (tagLength >= (((2 * runLength) / blockLength) - 1)) && (runLength < length) {
		index = dataStart
		for (index + (2 * runLength)) <= dataEnd {
			smartBlockMerge(self, index, (index + runLength), (index + (2 * runLength)), tags, buffer, blockLength)
			index += (2 * runLength)
		}
		if (index + runLength) < dataEnd {
			if (dataEnd - (index + runLength)) > blockLength {
				smartBlockMerge(self, index, (index + runLength), dataEnd, tags, buffer, blockLength)
			} else {
				smartMergeBackward(self, index, (index + runLength), dataEnd, buffer)
			}
		}
		runLength *= 2
	}
	binaryInsertion(self, buffer, (buffer + blockLength))
	tagLength = (keys - (keys % 2))
	for runLength < length {
		blockLength = ((2 * runLength) / tagLength)
		index = dataStart
		for (index + (2 * runLength)) <= dataEnd {
			smartBlockMergeWithoutBuffer(self, index, (index + runLength), (index + (2 * runLength)), tags, blockLength)
			index += (2 * runLength)
		}
		if (index + runLength) < dataEnd {
			if (dataEnd - (index + runLength)) > blockLength {
				smartBlockMergeWithoutBuffer(self, index, (index + runLength), dataEnd, tags, blockLength)
			} else {
				smartInPlaceMerge(self, index, (index + runLength), dataEnd)
			}
		}
		runLength *= 2
	}
	if backwardBuffer {
		start = rightBinarySearch(self, start, dataEnd, read(self, dataEnd))
		if keys >= (ideal / 2) {
			redistributeBufferBackward(self, start, dataEnd, end)
		} else {
			mergeWithoutBuffer(self, start, dataEnd, end)
		}
	} else {
		end = leftBinarySearch(self, dataStart, end, read(self, (dataStart-1)))
		if keys >= (ideal / 2) {
			redistributeBuffer(self, start, dataStart, end)
		} else {
			mergeWithoutBuffer(self, start, dataStart, end)
		}
	}
}
func sort(self *AdaptiveGrailExample, startIn int, endIn int) {
	var backwardBuffer bool
	var blockLength, buffer, dataEnd, dataStart, end, ideal, index, keys, leftRun, length, middle, rightRun, runLength, start, tagLength, tags int
	start = startIn
	end = endIn
	length = (end - start)
	if length < 31 {
		binaryInsertion(self, start, end)
		return
	}
	if length < 63 {
		self.minRun = ((length + 1) / 2)
		buildRuns(self, start, end)
		middle = (start + self.minRun)
		if checkBounds(self, start, middle, end) {
			redistributeBufferBackward(self, start, middle, end)
		}
		return
	}
	self.minRun = length
	for self.minRun >= 32 {
		self.minRun = ((self.minRun + 1) / 2)
	}
	blockLength = self.minRun
	for (blockLength * blockLength) < length {
		blockLength *= 2
	}
	tagLength = ((length / blockLength) - 2)
	ideal = (tagLength + blockLength)
	rightRun = buildUniqueRunBackward(self, end, ideal)
	leftRun = 0
	backwardBuffer = false
	if rightRun == ideal {
		backwardBuffer = true
	} else {
		leftRun = buildUniqueRun(self, start, ideal)
		if leftRun == ideal {
			backwardBuffer = false
		} else {
			backwardBuffer = (((rightRun < 16) && (leftRun < 16)) || (rightRun >= leftRun))
		}
	}
	if backwardBuffer {
		keys = findKeysBackward(self, start, end, rightRun, ideal)
	} else {
		keys = findKeys(self, start, end, leftRun, ideal)
	}
	if keys < ideal {
		if keys == 1 {
			return
		}
		if keys <= 4 {
			inPlaceMergeSort(self, start, end)
		} else {
			adaptiveSortWithoutBuffer(self, start, end, keys, ideal, backwardBuffer)
		}
		return
	}
	buffer = 0
	dataStart = 0
	dataEnd = 0
	tags = 0
	if backwardBuffer {
		buffer = (end - blockLength)
		dataStart = start
		dataEnd = (buffer - tagLength)
		tags = dataEnd
	} else {
		buffer = (start + tagLength)
		dataStart = (buffer + blockLength)
		dataEnd = end
		tags = start
	}
	buildRuns(self, dataStart, dataEnd)
	runLength = self.minRun
	for (runLength <= blockLength) && (runLength < length) {
		index = dataStart
		for (index + (2 * runLength)) <= dataEnd {
			smartMerge(self, index, (index + runLength), (index + (2 * runLength)), buffer)
			index += (2 * runLength)
		}
		if (index + runLength) < dataEnd {
			smartMergeBackward(self, index, (index + runLength), dataEnd, buffer)
		}
		runLength *= 2
	}
	for runLength < length {
		index = dataStart
		for (index + (2 * runLength)) <= dataEnd {
			smartBlockMerge(self, index, (index + runLength), (index + (2 * runLength)), tags, buffer, blockLength)
			index += (2 * runLength)
		}
		if (index + runLength) < dataEnd {
			if (dataEnd - (index + runLength)) > blockLength {
				smartBlockMerge(self, index, (index + runLength), dataEnd, tags, buffer, blockLength)
			} else {
				smartMergeBackward(self, index, (index + runLength), dataEnd, buffer)
			}
		}
		runLength *= 2
	}
	binaryInsertion(self, buffer, (buffer + blockLength))
	if backwardBuffer {
		start = rightBinarySearch(self, start, dataEnd, read(self, dataEnd))
		redistributeBufferBackward(self, start, dataEnd, end)
	} else {
		end = leftBinarySearch(self, dataStart, end, read(self, (dataStart-1)))
		redistributeBuffer(self, start, dataStart, end)
	}
}

func adaptiveGrailSort(values []int) {
	state := AdaptiveGrailExample{values: values, n: len(values), minRun: 16}
	sort(&state, 0, len(values))
}

func main() {
	values := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	adaptiveGrailSort(values)
	fmt.Println(values)
}
