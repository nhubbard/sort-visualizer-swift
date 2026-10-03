// The WikiSorting source is released to the public domain under the Unlicense.

package main

import (
	"fmt"
	"math"
)

type WikiRange struct{ start, end int }

func (r WikiRange) length() int          { return r.end - r.start }
func (r *WikiRange) set(first, last int) { r.start = first; r.end = last }
func (r WikiRange) copy() WikiRange      { return r }

type WikiPull struct {
	from_, to, count int
	range_           WikiRange
}
type WikiIterator struct{ size, denominator, numeratorStep, decimalStep, numerator, decimal int }

func newWikiIterator(size int) WikiIterator {
	power := 1
	for power*2 <= size {
		power *= 2
	}
	d := power / 4
	return WikiIterator{size: size, denominator: d, numeratorStep: size % d, decimalStep: size / d}
}
func (it *WikiIterator) begin() { it.numerator = 0; it.decimal = 0 }
func (it *WikiIterator) nextRange() WikiRange {
	start := it.decimal
	it.decimal += it.decimalStep
	it.numerator += it.numeratorStep
	if it.numerator >= it.denominator {
		it.numerator -= it.denominator
		it.decimal++
	}
	return WikiRange{start, it.decimal}
}
func (it *WikiIterator) finished() bool { return it.decimal >= it.size }
func (it *WikiIterator) nextLevel() bool {
	it.decimalStep *= 2
	it.numeratorStep *= 2
	if it.numeratorStep >= it.denominator {
		it.numeratorStep -= it.denominator
		it.decimalStep++
	}
	return it.decimalStep < it.size
}
func (it *WikiIterator) length() int { return it.decimalStep }

type WikiSortExample struct{ values []int }

func (self *WikiSortExample) read(index int) int {
	return self.values[index]
}
func (self *WikiSortExample) less(left int, right int) bool {
	return (self.values[left] < self.values[right])
}
func (self *WikiSortExample) lessValues(left int, right int) bool {
	return (left < right)
}
func (self *WikiSortExample) greaterValues(left int, right int) bool {
	return (left > right)
}
func (self *WikiSortExample) swap(left int, right int) {
	self.values[left], self.values[right] = self.values[right], self.values[left]
}
func (self *WikiSortExample) binaryFirst(value int, segment WikiRange) int {
	var end int
	var middle int
	var start int
	start = segment.start
	end = segment.end
	for start < end {
		middle = (start + ((end - start) / 2))
		if self.values[middle] < value {
			start = (middle + 1)
		} else {
			end = middle
		}
	}
	return start
}
func (self *WikiSortExample) binaryLast(value int, segment WikiRange) int {
	var end int
	var middle int
	var start int
	start = segment.start
	end = segment.end
	for start < end {
		middle = (start + ((end - start) / 2))
		if self.values[middle] <= value {
			start = (middle + 1)
		} else {
			end = middle
		}
	}
	return start
}
func (self *WikiSortExample) findFirstForward(value int, segment WikiRange, unique int) int {
	var index int
	var skip int
	if !(segment.length() > 0) {
		return segment.start
	}
	skip = max((segment.length() / max(unique, 1)), 1)
	index = (segment.start + skip)
	for self.values[(index-1)] < value {
		if index >= (segment.end - skip) {
			return self.binaryFirst(value, WikiRange{index, segment.end})
		}
		index += skip
	}
	return self.binaryFirst(value, WikiRange{(index - skip), index})
}
func (self *WikiSortExample) findLastForward(value int, segment WikiRange, unique int) int {
	var index int
	var skip int
	if !(segment.length() > 0) {
		return segment.start
	}
	skip = max((segment.length() / max(unique, 1)), 1)
	index = (segment.start + skip)
	for self.values[(index-1)] <= value {
		if index >= (segment.end - skip) {
			return self.binaryLast(value, WikiRange{index, segment.end})
		}
		index += skip
	}
	return self.binaryLast(value, WikiRange{(index - skip), index})
}
func (self *WikiSortExample) findFirstBackward(value int, segment WikiRange, unique int) int {
	var index int
	var skip int
	if !(segment.length() > 0) {
		return segment.start
	}
	skip = max((segment.length() / max(unique, 1)), 1)
	index = (segment.end - skip)
	for (index > segment.start) && (self.values[(index-1)] >= value) {
		if index < (segment.start + skip) {
			return self.binaryFirst(value, WikiRange{segment.start, index})
		}
		index -= skip
	}
	return self.binaryFirst(value, WikiRange{index, (index + skip)})
}
func (self *WikiSortExample) findLastBackward(value int, segment WikiRange, unique int) int {
	var index int
	var skip int
	if !(segment.length() > 0) {
		return segment.start
	}
	skip = max((segment.length() / max(unique, 1)), 1)
	index = (segment.end - skip)
	for (index > segment.start) && (self.values[(index-1)] > value) {
		if index < (segment.start + skip) {
			return self.binaryLast(value, WikiRange{segment.start, index})
		}
		index -= skip
	}
	return self.binaryLast(value, WikiRange{index, (index + skip)})
}
func (self *WikiSortExample) insertionSort(segment WikiRange) {
	var cursor int
	var destination int
	var index int
	var value int
	if !(segment.length() > 1) {
		return
	}
	for index = (segment.start + 1); index < segment.end; index++ {
		value = self.read(index)
		destination = self.binaryLast(value, WikiRange{segment.start, index})
		cursor = index
		for cursor > destination {
			self.values[cursor] = self.read((cursor - 1))
			cursor -= 1
		}
		self.values[destination] = value
	}
}
func (self *WikiSortExample) blockSwap(first int, second int, length int) {
	var offset int
	if !(length > 0) {
		return
	}
	for offset = 0; offset < length; offset++ {
		self.swap((first + offset), (second + offset))
	}
}
func (self *WikiSortExample) rotate(amount int, segment WikiRange) {
	var leftLength int
	var position int
	var rightLength int
	var split int
	if !(segment.length() > 0) {
		return
	}
	if amount >= 0 {
		split = segment.start + amount
	} else {
		split = segment.end + amount
	}
	if !((segment.start < split) && (split < segment.end)) {
		return
	}
	position = segment.start
	leftLength = (split - segment.start)
	rightLength = (segment.end - split)
	for (leftLength != 0) && (rightLength != 0) {
		if leftLength <= rightLength {
			self.blockSwap(position, (position + leftLength), leftLength)
			position += leftLength
			rightLength -= leftLength
		} else {
			self.blockSwap(((position + leftLength) - rightLength), (position + leftLength), rightLength)
			leftLength -= rightLength
		}
	}
}
func (self *WikiSortExample) mergeInternal(left WikiRange, right WikiRange, buffer WikiRange) {
	var aCount int
	var bCount int
	var insert int
	aCount = 0
	bCount = 0
	insert = 0
	if (right.length() > 0) && (left.length() > 0) {
		for true {
			if !(self.less((right.start + bCount), (buffer.start + aCount))) {
				self.swap((left.start + insert), (buffer.start + aCount))
				aCount += 1
				insert += 1
				if aCount >= left.length() {
					break
				}
			} else {
				self.swap((left.start + insert), (right.start + bCount))
				bCount += 1
				insert += 1
				if bCount >= right.length() {
					break
				}
			}
		}
	}
	self.blockSwap((buffer.start + aCount), (left.start + insert), (left.length() - aCount))
}
func (self *WikiSortExample) mergeInPlace(originalLeft WikiRange, originalRight WikiRange) {
	var amount int
	var left WikiRange
	var middle int
	var right WikiRange
	if !((originalLeft.length() > 0) && (originalRight.length() > 0)) {
		return
	}
	left = originalLeft
	right = originalRight
	for true {
		middle = self.binaryFirst(self.read(left.start), right)
		amount = (middle - left.end)
		self.rotate(-(amount), WikiRange{left.start, middle})
		if right.end == middle {
			break
		}
		right.start = middle
		left.set((left.start + amount), right.start)
		left.start = self.binaryLast(self.read(left.start), left)
		if left.length() == 0 {
			break
		}
	}
}
func (self *WikiSortExample) netSwap(segment WikiRange, order *[8]int, x int, y int) {
	var a int
	var b int
	var first int
	var isEqual bool
	var isGreater bool
	var second int
	first = (segment.start + x)
	second = (segment.start + y)
	a = self.read(first)
	b = self.read(second)
	isGreater = self.greaterValues(a, b)
	isEqual = (!(isGreater) && !(self.lessValues(a, b)))
	if isGreater || (isEqual && (order[x] > order[y])) {
		self.swap(first, second)
		order[x], order[y] = order[y], order[x]
	}
}
func (self *WikiSortExample) sortSmallRuns(iterator *WikiIterator) {
	var order [8]int
	var pairs [][2]int
	var segment WikiRange
	for !(iterator.finished()) {
		order = [8]int{0, 1, 2, 3, 4, 5, 6, 7}
		segment = iterator.nextRange()
		pairs = [][2]int{}
		if segment.length() == 8 {
			pairs = [][2]int{{0, 1}, {2, 3}, {4, 5}, {6, 7}, {0, 2}, {1, 3}, {4, 6}, {5, 7}, {1, 2}, {5, 6}, {0, 4}, {3, 7}, {1, 5}, {2, 6}, {1, 4}, {3, 6}, {2, 4}, {3, 5}, {3, 4}}
		} else {
			if segment.length() == 7 {
				pairs = [][2]int{{1, 2}, {3, 4}, {5, 6}, {0, 2}, {3, 5}, {4, 6}, {0, 1}, {4, 5}, {2, 6}, {0, 4}, {1, 5}, {0, 3}, {2, 5}, {1, 3}, {2, 4}, {2, 3}}
			} else {
				if segment.length() == 6 {
					pairs = [][2]int{{1, 2}, {4, 5}, {0, 2}, {3, 5}, {0, 1}, {3, 4}, {2, 5}, {0, 3}, {1, 4}, {2, 4}, {1, 3}, {2, 3}}
				} else {
					if segment.length() == 5 {
						pairs = [][2]int{{0, 1}, {3, 4}, {2, 4}, {2, 3}, {1, 4}, {0, 3}, {0, 2}, {1, 3}, {1, 2}}
					} else {
						if segment.length() == 4 {
							pairs = [][2]int{{0, 1}, {2, 3}, {0, 2}, {1, 3}, {1, 2}}
						} else {
							pairs = [][2]int{}
						}
					}
				}
			}
		}
		for _, pair := range pairs {
			x, y := pair[0], pair[1]
			self.netSwap(segment, &order, x, y)
		}
	}
}
func (self *WikiSortExample) sort() {
	var pull int
	var amount int
	var blockA WikiRange
	var blockB WikiRange
	var blockSize int
	var buffer WikiRange
	var buffer1 WikiRange
	var buffer2 WikiRange
	var bufferSize int
	var count int
	var find int
	var findA int
	var findSeparately bool
	var firstA WikiRange
	var index int
	var indexA int
	var iterator WikiIterator
	var last int
	var lastA WikiRange
	var lastB WikiRange
	var left WikiRange
	var length int
	var minimum int
	var nominalBlock int
	var pullIndex int
	var pulls [2]WikiPull
	var segment WikiRange
	var remaining int
	var right WikiRange
	var size int
	var split int
	var start int
	var targetBufferSize int
	var unique int
	size = len(self.values)
	if size < 4 {
		self.insertionSort(WikiRange{0, size})
		return
	}
	iterator = newWikiIterator(size)
	self.sortSmallRuns(&iterator)
	if size < 8 {
		return
	}
	for true {
		nominalBlock = max(1, int(math.Sqrt(float64(iterator.length()))))
		blockSize = nominalBlock
		targetBufferSize = ((iterator.length() / blockSize) + 1)
		buffer1 = WikiRange{}
		buffer2 = WikiRange{}
		pulls = [2]WikiPull{{}, {}}
		pullIndex = 0
		find = (targetBufferSize * 2)
		findSeparately = false
		if find > iterator.length() {
			find = targetBufferSize
			findSeparately = true
		}
		iterator.begin()
		for !(iterator.finished()) {
			left = iterator.nextRange()
			right = iterator.nextRange()
			last = left.start
			count = 1
			index = last
			for count < find {
				index = self.findLastForward(self.read(last), WikiRange{(last + 1), left.end}, (find - count))
				if index == left.end {
					break
				}
				last = index
				count += 1
			}
			index = last
			if count >= targetBufferSize {
				pulls[pullIndex] = WikiPull{index, left.start, count, WikiRange{left.start, right.end}}
				pullIndex = 1
				if count == (targetBufferSize * 2) {
					buffer1 = WikiRange{left.start, (left.start + targetBufferSize)}
					buffer2 = WikiRange{(left.start + targetBufferSize), (left.start + count)}
					break
				} else {
					if find == (targetBufferSize * 2) {
						buffer1 = WikiRange{left.start, (left.start + count)}
						find = targetBufferSize
					} else {
						if findSeparately {
							buffer1 = WikiRange{left.start, (left.start + count)}
							findSeparately = false
						} else {
							buffer2 = WikiRange{left.start, (left.start + count)}
							break
						}
					}
				}
			} else {
				if (pullIndex == 0) && (count > buffer1.length()) {
					buffer1 = WikiRange{left.start, (left.start + count)}
					pulls[pullIndex] = WikiPull{index, left.start, count, WikiRange{left.start, right.end}}
				}
			}
			last = (right.end - 1)
			count = 1
			for count < find {
				index = self.findFirstBackward(self.read(last), WikiRange{right.start, last}, (find - count))
				if index == right.start {
					break
				}
				last = (index - 1)
				count += 1
			}
			index = last
			if count >= targetBufferSize {
				pulls[pullIndex] = WikiPull{index, right.end, count, WikiRange{left.start, right.end}}
				pullIndex = 1
				if count == (targetBufferSize * 2) {
					buffer1 = WikiRange{(right.end - count), (right.end - targetBufferSize)}
					buffer2 = WikiRange{(right.end - targetBufferSize), right.end}
					break
				} else {
					if find == (targetBufferSize * 2) {
						buffer1 = WikiRange{(right.end - count), right.end}
						find = targetBufferSize
					} else {
						if findSeparately {
							buffer1 = WikiRange{(right.end - count), right.end}
							findSeparately = false
						} else {
							if pulls[0].range_.start == left.start {
								pulls[0].range_.end -= pulls[1].count
							}
							buffer2 = WikiRange{(right.end - count), right.end}
							break
						}
					}
				}
			} else {
				if (pullIndex == 0) && (count > buffer1.length()) {
					buffer1 = WikiRange{(right.end - count), right.end}
					pulls[pullIndex] = WikiPull{index, right.end, count, WikiRange{left.start, right.end}}
				}
			}
		}
		for pull = 0; pull < 2; pull++ {
			length = pulls[pull].count
			if pulls[pull].to < pulls[pull].from_ {
				index = pulls[pull].from_
				if length > 1 {
					for count = 1; count < length; count++ {
						index = self.findFirstBackward(self.read((index - 1)), WikiRange{pulls[pull].to, (pulls[pull].from_ - (count - 1))}, (length - count))
						segment = WikiRange{(index + 1), (pulls[pull].from_ + 1)}
						self.rotate((segment.length() - count), segment)
						pulls[pull].from_ = (index + count)
					}
				}
			} else {
				if pulls[pull].to > pulls[pull].from_ {
					index = (pulls[pull].from_ + 1)
					if length > 1 {
						for count = 1; count < length; count++ {
							index = self.findLastForward(self.read(index), WikiRange{index, pulls[pull].to}, (length - count))
							segment = WikiRange{pulls[pull].from_, (index - 1)}
							self.rotate(count, segment)
							pulls[pull].from_ = ((index - 1) - count)
						}
					}
				}
			}
		}
		bufferSize = buffer1.length()
		blockSize = ((iterator.length() / bufferSize) + 1)
		iterator.begin()
		for !(iterator.finished()) {
			left = iterator.nextRange()
			right = iterator.nextRange()
			start = left.start
			for _, pull := range pulls {
				if start != pull.range_.start {
					continue
				}
				if pull.from_ > pull.to {
					left.start += pull.count
				} else {
					if pull.from_ < pull.to {
						right.end -= pull.count
					}
				}
			}
			if (left.length() == 0) || (right.length() == 0) {
				continue
			}
			if self.less((right.end - 1), left.start) {
				self.rotate(left.length(), WikiRange{left.start, right.end})
			} else {
				if self.less(left.end, (left.end - 1)) {
					blockA = left.copy()
					firstA = WikiRange{left.start, (left.start + (blockA.length() % blockSize))}
					indexA = buffer1.start
					index = firstA.end
					for index < blockA.end {
						self.swap(indexA, index)
						indexA += 1
						index += blockSize
					}
					lastA = firstA.copy()
					lastB = WikiRange{}
					blockB = WikiRange{right.start, (right.start + min(blockSize, right.length()))}
					blockA.start += firstA.length()
					indexA = buffer1.start
					if buffer2.length() > 0 {
						self.blockSwap(lastA.start, buffer2.start, lastA.length())
					}
					if blockA.length() > 0 {
						for true {
							if ((lastB.length() > 0) && !(self.less((lastB.end - 1), indexA))) || (blockB.length() == 0) {
								split = self.binaryFirst(self.read(indexA), lastB)
								remaining = (lastB.end - split)
								minimum = blockA.start
								findA = (minimum + blockSize)
								for findA < blockA.end {
									if self.less(findA, minimum) {
										minimum = findA
									}
									findA += blockSize
								}
								self.blockSwap(blockA.start, minimum, blockSize)
								self.swap(blockA.start, indexA)
								indexA += 1
								if buffer2.length() > 0 {
									self.mergeInternal(lastA, WikiRange{lastA.end, split}, buffer2)
								} else {
									self.mergeInPlace(lastA, WikiRange{lastA.end, split})
								}
								if buffer2.length() > 0 {
									self.blockSwap(blockA.start, buffer2.start, blockSize)
									self.blockSwap(split, ((blockA.start + blockSize) - remaining), remaining)
								} else {
									self.rotate((blockA.start - split), WikiRange{split, (blockA.start + blockSize)})
								}
								lastA = WikiRange{(blockA.start - remaining), ((blockA.start - remaining) + blockSize)}
								lastB = WikiRange{lastA.end, (lastA.end + remaining)}
								blockA.start += blockSize
								if blockA.length() == 0 {
									break
								}
							} else {
								if blockB.length() < blockSize {
									self.rotate(-(blockB.length()), WikiRange{blockA.start, blockB.end})
									lastB = WikiRange{blockA.start, (blockA.start + blockB.length())}
									blockA.start += blockB.length()
									blockA.end += blockB.length()
									blockB.end = blockB.start
								} else {
									self.blockSwap(blockA.start, blockB.start, blockSize)
									lastB = WikiRange{blockA.start, (blockA.start + blockSize)}
									blockA.start += blockSize
									blockA.end += blockSize
									blockB.start += blockSize
									blockB.end = min((blockB.end + blockSize), right.end)
								}
							}
						}
					}
					if buffer2.length() > 0 {
						self.mergeInternal(lastA, WikiRange{lastA.end, right.end}, buffer2)
					} else {
						self.mergeInPlace(lastA, WikiRange{lastA.end, right.end})
					}
				}
			}
		}
		self.insertionSort(buffer2)
		for _, pull := range pulls {
			unique = (pull.count * 2)
			if pull.from_ > pull.to {
				buffer = WikiRange{pull.range_.start, (pull.range_.start + pull.count)}
				for buffer.length() > 0 {
					index = self.findFirstForward(self.read(buffer.start), WikiRange{buffer.end, pull.range_.end}, unique)
					amount = (index - buffer.end)
					self.rotate(buffer.length(), WikiRange{buffer.start, index})
					buffer.start += (amount + 1)
					buffer.end += amount
					unique -= 2
				}
			} else {
				if pull.from_ < pull.to {
					buffer = WikiRange{(pull.range_.end - pull.count), pull.range_.end}
					for buffer.length() > 0 {
						index = self.findLastBackward(self.read((buffer.end - 1)), WikiRange{pull.range_.start, buffer.start}, unique)
						amount = (buffer.start - index)
						self.rotate(amount, WikiRange{index, buffer.end})
						buffer.start -= amount
						buffer.end -= (amount + 1)
						unique -= 2
					}
				}
			}
		}
		if !(iterator.nextLevel()) {
			break
		}
	}
}
func wikiSort(values []int) { (&WikiSortExample{values: values}).sort() }
func main() {
	values := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	wikiSort(values)
	fmt.Println(values)
}
