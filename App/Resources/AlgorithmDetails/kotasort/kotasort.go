// MIT License
// Copyright (c) 2020 aphitorite
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

type KotaSortExample struct {
	a                                       []int
	n, buf_pos, block_len, buf_len, tag_len int
}

func swap(self *KotaSortExample, left int, right int) {
	_sim0_0 := self.a[right]
	_sim0_1 := self.a[left]
	self.a[left] = _sim0_0
	self.a[right] = _sim0_1
}
func rotate(self *KotaSortExample, start int, middle int, end int) {
	var left_len, offset, right_len int
	_sim1_0 := (middle - start)
	_sim1_1 := (end - middle)
	left_len = _sim1_0
	right_len = _sim1_1
	for left_len != 0 && right_len != 0 {
		if left_len <= right_len {
			for offset = 0; offset < left_len; offset++ {
				swap(self, (start + offset), ((start + left_len) + offset))
			}
			start += left_len
			right_len -= left_len
		} else {
			for offset = 0; offset < right_len; offset++ {
				swap(self, (((start + left_len) - right_len) + offset), ((start + left_len) + offset))
			}
			left_len -= right_len
		}
	}
}
func binary_search(self *KotaSortExample, start int, end int, value int, left int) int {
	var middle int
	for start < end {
		middle = (start + ((end - start) / 2))
		if (left != 0 && self.a[middle] >= value) || (left == 0 && self.a[middle] > value) {
			end = middle
		} else {
			start = (middle + 1)
		}
	}
	return start
}
func find_keys(self *KotaSortExample, start int, end int, target int) int {
	var count, increase, index, loc, pos, pos_end, value int
	_sim2_0 := 1
	_sim2_1 := start
	_sim2_2 := (start + 1)
	_sim2_3 := (start + 1)
	count = _sim2_0
	pos = _sim2_1
	pos_end = _sim2_2
	index = _sim2_3
	for (index < end) && (count < target) {
		value = self.a[index]
		loc = binary_search(self, pos, pos_end, value, 1)
		if (index == loc) || (value != self.a[loc]) {
			rotate(self, pos, pos_end, index)
			increase = (index - pos_end)
			loc += increase
			pos += increase
			pos_end += increase
			rotate(self, loc, pos_end, (pos_end + 1))
			count += 1
			pos_end += 1
		}
		index += 1
	}
	rotate(self, start, pos, pos_end)
	return count
}
func swap_to_tags(self *KotaSortExample, position int, tag int) {
	swap(self, (self.buf_pos + tag), position)
}
func shift(self *KotaSortExample, start int, middle int, end int, left int) {
	if left != 0 {
		for middle > start {
			end -= 1
			middle -= 1
			swap(self, end, middle)
		}
	} else {
		for middle < end {
			swap(self, start, middle)
			start += 1
			middle += 1
		}
	}
}
func multi_swap(self *KotaSortExample, first int, second int, length int) {
	var offset int
	for offset = 0; offset < length; offset++ {
		swap(self, (first + offset), (second + offset))
	}
}
func multi_swap_backward(self *KotaSortExample, first int, second int, length int) {
	var offset int
	for offset = 0; offset < length; offset++ {
		swap(self, (first - offset), (second - offset))
	}
}
func block_select(self *KotaSortExample, position int, count int) {
	var candidate, index, minimum, start, tag int
	for tag = 0; tag < count; tag++ {
		start = (position + (tag * self.block_len))
		minimum = start
		for index = (tag + 1); index < count; index++ {
			candidate = (position + (index * self.block_len))
			if self.a[candidate] < self.a[minimum] {
				minimum = candidate
			}
		}
		if start != minimum {
			multi_swap(self, start, minimum, self.block_len)
		}
		swap_to_tags(self, start, tag)
	}
}
func block_select_backward(self *KotaSortExample, position int, count int) {
	var candidate, index, minimum, start, tag int
	for tag = 0; tag < count; tag++ {
		start = (position - (tag * self.block_len))
		minimum = start
		for index = (tag + 1); index < count; index++ {
			candidate = (position - (index * self.block_len))
			if self.a[candidate] < self.a[minimum] {
				minimum = candidate
			}
		}
		if start != minimum {
			multi_swap_backward(self, start, minimum, self.block_len)
		}
		swap_to_tags(self, start, tag)
	}
}
func in_place_merge(self *KotaSortExample, start int, middle int, end int) {
	var i, j, k int
	_sim3_0 := start
	_sim3_1 := middle
	i = _sim3_0
	j = _sim3_1
	for (i < j) && (j < end) {
		if self.a[i] > self.a[j] {
			k = binary_search(self, j, end, self.a[i], 1)
			rotate(self, i, j, k)
			i += (k - j)
			j = k
		} else {
			i += 1
		}
	}
}
func in_place_merge_backward(self *KotaSortExample, start int, middle int, end int) {
	var i, j, k int
	_sim4_0 := (middle - 1)
	_sim4_1 := (end - 1)
	i = _sim4_0
	j = _sim4_1
	for (j > i) && (i >= start) {
		if self.a[i] >= self.a[j] {
			k = binary_search(self, start, (i + 1), self.a[j], 1)
			rotate(self, k, (i + 1), (j + 1))
			j -= ((i + 1) - k)
			i = (k - 1)
		} else {
			j -= 1
		}
	}
}
func in_place_merge2(self *KotaSortExample, start int, middle int, end int) {
	var i, k, m, q int
	_sim5_0 := start
	_sim5_1 := middle
	_sim5_2 := middle
	i = _sim5_0
	m = _sim5_1
	k = _sim5_2
	for m < end {
		if self.a[(m-1)] <= self.a[m] {
			return
		}
		for (i < (m - 1)) && (self.a[i] <= self.a[m]) {
			i += 1
		}
		swap(self, i, k)
		i += 1
		k += 1
		for i < m {
			for (i < m) && (k < end) && (self.a[m] > self.a[k]) {
				swap(self, i, k)
				i += 1
				k += 1
			}
			if i >= m {
				break
			}
			if k >= end {
				rotate(self, i, m, end)
				return
			}
			if (k - m) >= (m - i) {
				rotate(self, i, m, k)
				break
			}
			q = m
			for (i < m) && (q < k) && (self.a[q] <= self.a[k]) {
				swap(self, i, q)
				i += 1
				q += 1
			}
			rotate(self, m, q, k)
		}
		m = k
	}
}
func in_place_merge_sort2(self *KotaSortExample, start int, end int) {
	var position, width int
	width = 1
	for width < (end - start) {
		position = start
		for (position + (2 * width)) < end {
			in_place_merge2(self, position, (position + width), (position + (2 * width)))
			position += (2 * width)
		}
		if (position + width) < end {
			in_place_merge2(self, position, (position + width), end)
		}
		width *= 2
	}
}
func merge_with_buf(self *KotaSortExample, start int, middle int, end int, length int) {
	var i, j, k int
	_sim6_0 := start
	_sim6_1 := middle
	_sim6_2 := (start - length)
	i = _sim6_0
	j = _sim6_1
	k = _sim6_2
	for (i < middle) && (j < end) {
		if self.a[i] <= self.a[j] {
			swap(self, k, i)
			i += 1
		} else {
			swap(self, k, j)
			j += 1
		}
		k += 1
	}
	for j < end {
		swap(self, k, j)
		k += 1
		j += 1
	}
	shift(self, k, i, middle, 0)
}
func dual_merge(self *KotaSortExample, start int, middle int, end int, length int) {
	var i, i2, j, j2, k int
	if (end - middle) <= length {
		merge_with_buf(self, start, middle, end, length)
		return
	}
	_sim7_0 := start
	_sim7_1 := middle
	_sim7_2 := (start - length)
	i = _sim7_0
	j = _sim7_1
	k = _sim7_2
	for (k < i) && (i < middle) {
		if self.a[i] <= self.a[j] {
			swap(self, k, i)
			i += 1
		} else {
			swap(self, k, j)
			j += 1
		}
		k += 1
	}
	if k < i {
		shift(self, (j - length), j, end, 0)
	} else {
		_sim8_0 := (middle - 1)
		_sim8_1 := (end - 1)
		i2 = _sim8_0
		j2 = _sim8_1
		k = (((middle - 1) + end) - j)
		for (i2 >= i) && (j2 >= j) {
			if self.a[i2] > self.a[j2] {
				swap(self, k, i2)
				i2 -= 1
			} else {
				swap(self, k, j2)
				j2 -= 1
			}
			k -= 1
		}
		for j2 >= j {
			swap(self, k, j2)
			k -= 1
			j2 -= 1
		}
	}
}
func dual_merge_backward(self *KotaSortExample, start int, middle int, end int, length int) {
	var first_end, i, i2, j, j2, k, second_end int
	_sim9_0 := (middle - 1)
	_sim9_1 := (end - 1)
	_sim9_2 := ((end - 1) + length)
	i = _sim9_0
	j = _sim9_1
	k = _sim9_2
	for (k > j) && (j >= middle) {
		if self.a[i] > self.a[j] {
			swap(self, k, i)
			i -= 1
		} else {
			swap(self, k, j)
			j -= 1
		}
		k -= 1
	}
	if j < middle {
		shift(self, start, (i + 1), ((i + 1) + length), 1)
	} else {
		_sim10_0 := (i + 1)
		_sim10_1 := (j + 1)
		first_end = _sim10_0
		second_end = _sim10_1
		_sim11_0 := start
		_sim11_1 := middle
		i2 = _sim11_0
		j2 = _sim11_1
		k = (middle - (first_end - start))
		for (i2 < first_end) && (j2 < second_end) {
			if self.a[i2] <= self.a[j2] {
				swap(self, k, i2)
				i2 += 1
			} else {
				swap(self, k, j2)
				j2 += 1
			}
			k += 1
		}
		for i2 < first_end {
			swap(self, k, i2)
			k += 1
			i2 += 1
		}
	}
}
func merge_with_buf_static(self *KotaSortExample, start int, middle int, end int, position int, backward int) {
	var i, j, k, q int
	if ((middle - start) <= 0) || ((end - middle) <= 0) {
		return
	}
	if backward != 0 {
		_sim12_0 := ((end - middle) - 1)
		_sim12_1 := (middle - 1)
		_sim12_2 := (end - 1)
		i = _sim12_0
		j = _sim12_1
		k = _sim12_2
		for (i >= 0) && (j >= start) {
			if self.a[j] >= self.a[(position+i)] {
				q = binary_search(self, start, (j + 1), self.a[(position+i)], 1)
				for j >= q {
					swap(self, k, j)
					k -= 1
					j -= 1
				}
			}
			swap(self, k, (position + i))
			k -= 1
			i -= 1
		}
		for i >= 0 {
			swap(self, k, (position + i))
			k -= 1
			i -= 1
		}
	} else {
		_sim13_0 := 0
		_sim13_1 := middle
		_sim13_2 := start
		i = _sim13_0
		j = _sim13_1
		k = _sim13_2
		for (i < (middle - start)) && (j < end) {
			if self.a[j] < self.a[(position+i)] {
				q = binary_search(self, j, end, self.a[(position+i)], 1)
				for j < q {
					swap(self, k, j)
					k += 1
					j += 1
				}
			}
			swap(self, k, (position + i))
			k += 1
			i += 1
		}
		for i < (middle - start) {
			swap(self, k, (position + i))
			k += 1
			i += 1
		}
	}
}
func block_merge(self *KotaSortExample, start int, middle int, end int) {
	var count, first, i, j, left, left_available, right, right_available, selection_start, tag_count int
	if (end - middle) <= (2 * self.buf_len) {
		dual_merge(self, start, middle, end, self.buf_len)
		return
	}
	_sim14_0 := start
	_sim14_1 := middle
	i = _sim14_0
	j = _sim14_1
	_sim15_0 := self.buf_len
	_sim15_1 := 0
	left_available = _sim15_0
	right_available = _sim15_1
	_sim16_0 := (i - self.buf_len)
	_sim16_1 := j
	_sim16_2 := 0
	left = _sim16_0
	right = _sim16_1
	tag_count = _sim16_2
	for (i < middle) && (left_available >= right_available) {
		count = 0
		for (i < middle) && (count < self.block_len) {
			if self.a[i] <= self.a[j] {
				swap(self, left, i)
				i += 1
			} else {
				swap(self, left, j)
				j += 1
				right_available += 1
				left_available -= 1
			}
			left += 1
			count += 1
		}
	}
	selection_start = left
	for (i < middle) && (j < end) {
		for (i < middle) && (j < end) && (right_available > left_available) {
			first = right
			count = 0
			for (i < middle) && (j < end) && (count < self.block_len) {
				if self.a[i] <= self.a[j] {
					swap(self, right, i)
					i += 1
					right_available -= 1
					left_available += 1
				} else {
					swap(self, right, j)
					j += 1
				}
				right += 1
				count += 1
			}
			for (i < middle) && (count < self.block_len) {
				swap(self, right, i)
				right += 1
				i += 1
				right_available -= 1
				left_available += 1
				count += 1
			}
			for (j < end) && (count < self.block_len) {
				swap(self, right, j)
				right += 1
				j += 1
				count += 1
			}
			if count == self.block_len {
				swap_to_tags(self, first, tag_count)
				tag_count += 1
			} else {
				shift(self, first, (first + count), end, 1)
				j = (end - count)
				right = first
			}
		}
		for (i < middle) && (j < end) && (left_available >= right_available) {
			first = left
			count = 0
			for (i < middle) && (j < end) && (count < self.block_len) {
				if self.a[i] <= self.a[j] {
					swap(self, left, i)
					i += 1
				} else {
					swap(self, left, j)
					j += 1
					right_available += 1
					left_available -= 1
				}
				left += 1
				count += 1
			}
			for (i < middle) && (count < self.block_len) {
				swap(self, left, i)
				left += 1
				i += 1
				count += 1
			}
			for (j < end) && (count < self.block_len) {
				swap(self, left, j)
				left += 1
				j += 1
				right_available += 1
				left_available -= 1
				count += 1
			}
			if count == self.block_len {
				swap_to_tags(self, first, tag_count)
				tag_count += 1
			} else {
				rotate(self, first, middle, right)
				left += (right - middle)
				left_available = 0
			}
		}
	}
	if (i >= middle) && (left_available == self.block_len) && (tag_count > 0) {
		multi_swap(self, left, (right - self.block_len), self.block_len)
	} else {
		if i < middle {
			rotate(self, left, middle, right)
			left += (right - middle)
		}
		shift(self, left, (left + left_available), right, 0)
	}
	if j < end {
		shift(self, (j - self.buf_len), j, end, 0)
	}
	block_select(self, selection_start, tag_count)
}
func block_merge_backward(self *KotaSortExample, start int, middle int, end int) {
	var count, first, i, j, left, left_available, right, right_available, selection_start, tag_count int
	_sim17_0 := (middle - 1)
	_sim17_1 := (end - 1)
	i = _sim17_0
	j = _sim17_1
	_sim18_0 := 0
	_sim18_1 := self.buf_len
	left_available = _sim18_0
	right_available = _sim18_1
	_sim19_0 := i
	_sim19_1 := (j + self.buf_len)
	_sim19_2 := 0
	left = _sim19_0
	right = _sim19_1
	tag_count = _sim19_2
	for (j >= middle) && (right_available >= left_available) {
		count = 0
		for (j >= middle) && (count < self.block_len) {
			if self.a[i] > self.a[j] {
				swap(self, right, i)
				i -= 1
				left_available += 1
				right_available -= 1
			} else {
				swap(self, right, j)
				j -= 1
			}
			right -= 1
			count += 1
		}
	}
	selection_start = right
	for (j >= middle) && (i >= start) {
		for (j >= middle) && (i >= start) && (left_available > right_available) {
			_sim20_0 := left
			_sim20_1 := 0
			first = _sim20_0
			count = _sim20_1
			for (j >= middle) && (i >= start) && (count < self.block_len) {
				if self.a[i] > self.a[j] {
					swap(self, left, i)
					i -= 1
				} else {
					swap(self, left, j)
					j -= 1
					right_available += 1
					left_available -= 1
				}
				left -= 1
				count += 1
			}
			for (j >= middle) && (count < self.block_len) {
				swap(self, left, j)
				left -= 1
				j -= 1
				right_available += 1
				left_available -= 1
				count += 1
			}
			for (i >= start) && (count < self.block_len) {
				swap(self, left, i)
				left -= 1
				i -= 1
				count += 1
			}
			if count == self.block_len {
				swap_to_tags(self, first, tag_count)
				tag_count += 1
			} else {
				shift(self, start, ((first + 1) - count), (first + 1), 0)
				i = ((start - 1) + count)
				left = first
			}
		}
		for (j >= middle) && (i >= start) && (right_available >= left_available) {
			_sim21_0 := right
			_sim21_1 := 0
			first = _sim21_0
			count = _sim21_1
			for (j >= middle) && (i >= start) && (count < self.block_len) {
				if self.a[i] > self.a[j] {
					swap(self, right, i)
					i -= 1
					left_available += 1
					right_available -= 1
				} else {
					swap(self, right, j)
					j -= 1
				}
				right -= 1
				count += 1
			}
			for (j >= middle) && (count < self.block_len) {
				swap(self, right, j)
				right -= 1
				j -= 1
				count += 1
			}
			for (i >= start) && (count < self.block_len) {
				swap(self, right, i)
				right -= 1
				i -= 1
				left_available += 1
				right_available -= 1
				count += 1
			}
			if count == self.block_len {
				swap_to_tags(self, first, tag_count)
				tag_count += 1
			} else {
				rotate(self, (left + 1), middle, (first + 1))
				right -= (middle - (left + 1))
				right_available = 0
			}
		}
	}
	if (j < middle) && (right_available == self.block_len) && (tag_count > 0) {
		multi_swap_backward(self, right, (left + self.block_len), self.block_len)
	} else {
		if j >= middle {
			rotate(self, (left + 1), middle, (right + 1))
			right -= (middle - (left + 1))
		}
		shift(self, (left + 1), ((right + 1) - right_available), (right + 1), 1)
	}
	if i >= start {
		shift(self, start, (i + 1), ((i + 1) + self.buf_len), 1)
	}
	block_select_backward(self, selection_start, tag_count)
}
func kota_iterator(self *KotaSortExample, start int, end int) int {
	var effective_start, length, length_of_buffer, position, width int
	width = 1
	effective_start = (start + self.buf_len)
	length = (end - effective_start)
	for width < 16 {
		position = effective_start
		for (position + (2 * width)) < end {
			in_place_merge2(self, position, (position + width), (position + (2 * width)))
			position += (2 * width)
		}
		if (position + width) < end {
			in_place_merge2(self, position, (position + width), end)
		}
		width *= 2
	}
	for width <= self.buf_len {
		length_of_buffer = width
		position = effective_start
		for (position + (2 * width)) < end {
			merge_with_buf(self, position, (position + width), (position + (2 * width)), length_of_buffer)
			position += (2 * width)
		}
		if (position + width) < end {
			merge_with_buf(self, position, (position + width), end, length_of_buffer)
		} else {
			shift(self, (position - length_of_buffer), position, end, 0)
		}
		width *= 2
		position = (effective_start - length_of_buffer)
		for (position + (2 * width)) < (end - length_of_buffer) {
			position += (2 * width)
		}
		if (position + width) < (end - length_of_buffer) {
			dual_merge_backward(self, position, (position + width), (end - length_of_buffer), length_of_buffer)
		} else {
			shift(self, position, (end - length_of_buffer), end, 1)
		}
		position -= (2 * width)
		for position >= (effective_start - length_of_buffer) {
			dual_merge_backward(self, position, (position + width), (position + (2 * width)), length_of_buffer)
			position -= (2 * width)
		}
		width *= 2
	}
	for width < length {
		position = effective_start
		for (position + (2 * width)) < end {
			block_merge(self, position, (position + width), (position + (2 * width)))
			position += (2 * width)
		}
		if (position + width) < end {
			block_merge(self, position, (position + width), end)
		} else {
			shift(self, (position - self.buf_len), position, end, 0)
		}
		width *= 2
		if width >= length {
			return 1
		}
		position = start
		for (position + (2 * width)) < (end - self.buf_len) {
			position += (2 * width)
		}
		if (position + width) < (end - self.buf_len) {
			block_merge_backward(self, position, (position + width), (end - self.buf_len))
		} else {
			shift(self, position, (end - self.buf_len), end, 1)
		}
		position -= (2 * width)
		for position >= start {
			block_merge_backward(self, position, (position + width), (position + (2 * width)))
			position -= (2 * width)
		}
		width *= 2
	}
	return 0
}
func sort(self *KotaSortExample) {
	var backward, buffer_end, buffer_start, buffer_target, effective_start, end_start, length, middle, position, tag_target int
	length = self.n
	if length <= 128 {
		in_place_merge_sort2(self, 0, length)
		return
	}
	self.buf_pos = 0
	self.block_len = 1
	for (self.block_len * self.block_len) < length {
		self.block_len *= 2
	}
	buffer_target = (2 * self.block_len)
	self.buf_len = find_keys(self, 0, length, buffer_target)
	if self.buf_len < buffer_target {
		if self.buf_len > 1 {
			in_place_merge_sort2(self, 0, length)
		}
		return
	}
	tag_target = (length / self.block_len)
	self.tag_len = find_keys(self, self.buf_len, length, tag_target)
	if self.tag_len < tag_target {
		in_place_merge_sort2(self, 0, length)
		return
	}
	buffer_start = self.tag_len
	effective_start = (buffer_start + self.buf_len)
	buffer_end = self.buf_len
	shift(self, 0, buffer_end, effective_start, 0)
	backward = kota_iterator(self, buffer_start, length)
	if backward != 0 {
		end_start = (length - self.buf_len)
		multi_swap(self, 0, end_start, self.tag_len)
		merge_with_buf_static(self, 0, buffer_start, end_start, end_start, 0)
		in_place_merge_sort2(self, end_start, length)
		middle = (end_start + self.block_len)
		position = binary_search(self, 0, end_start, self.a[(middle-1)], 1)
		rotate(self, position, end_start, middle)
		position += self.block_len
		multi_swap_backward(self, (length - 1), (position - 1), self.block_len)
		merge_with_buf_static(self, 0, (position - self.block_len), position, middle, 1)
		in_place_merge_sort2(self, middle, length)
		in_place_merge_backward(self, position, middle, length)
		in_place_merge(self, 0, position, length)
	} else {
		merge_with_buf_static(self, buffer_end, effective_start, length, 0, 0)
		in_place_merge_sort2(self, 0, buffer_end)
		middle = self.block_len
		position = binary_search(self, buffer_end, length, self.a[middle], 1)
		rotate(self, middle, buffer_end, position)
		position -= self.block_len
		multi_swap(self, 0, position, self.block_len)
		merge_with_buf_static(self, position, (position + self.block_len), length, 0, 0)
		in_place_merge_sort2(self, 0, middle)
		in_place_merge(self, 0, middle, position)
		in_place_merge2(self, (length - (2 * self.block_len)), (length - self.block_len), length)
		in_place_merge(self, 0, (length - (2 * self.block_len)), length)
	}
}

func kotaSort(values []int) {
	state := KotaSortExample{a: values, n: len(values)}
	sort(&state)
}

func main() {
	values := []int{0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56}
	kotaSort(values)
	fmt.Println(values)
}
