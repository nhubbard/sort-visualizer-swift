# MIT License
# Copyright (c) 2020 aphitorite
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


class KotaSortExample:
    def __init__(self, values):
        self.a = values
        self.buf_pos = 0
        self.block_len = 0
        self.buf_len = 0
        self.tag_len = 0

    def swap(self, left, right):
        self.a[left], self.a[right] = self.a[right], self.a[left]

    def rotate(self, start, middle, end):
        left_len, right_len = middle - start, end - middle
        while left_len and right_len:
            if left_len <= right_len:
                for offset in range(left_len):
                    self.swap(start + offset, start + left_len + offset)
                start += left_len
                right_len -= left_len
            else:
                for offset in range(right_len):
                    self.swap(start + left_len - right_len + offset,
                              start + left_len + offset)
                left_len -= right_len

    def binary_search(self, start, end, value, left):
        while start < end:
            middle = start + (end - start) // 2
            if (self.a[middle] >= value) if left else (self.a[middle] > value):
                end = middle
            else:
                start = middle + 1
        return start

    def find_keys(self, start, end, target):
        count, pos, pos_end, index = 1, start, start + 1, start + 1
        while index < end and count < target:
            value = self.a[index]
            loc = self.binary_search(pos, pos_end, value, True)
            if index == loc or value != self.a[loc]:
                self.rotate(pos, pos_end, index)
                increase = index - pos_end
                loc += increase
                pos += increase
                pos_end += increase
                self.rotate(loc, pos_end, pos_end + 1)
                count += 1
                pos_end += 1
            index += 1
        self.rotate(start, pos, pos_end)
        return count

    def swap_to_tags(self, position, tag):
        self.swap(self.buf_pos + tag, position)

    def shift(self, start, middle, end, left):
        if left:
            while middle > start:
                end -= 1
                middle -= 1
                self.swap(end, middle)
        else:
            while middle < end:
                self.swap(start, middle)
                start += 1
                middle += 1

    def multi_swap(self, first, second, length):
        for offset in range(length):
            self.swap(first + offset, second + offset)

    def multi_swap_backward(self, first, second, length):
        for offset in range(length):
            self.swap(first - offset, second - offset)

    def block_select(self, position, count):
        for tag in range(count):
            start = position + tag * self.block_len
            minimum = start
            for index in range(tag + 1, count):
                candidate = position + index * self.block_len
                if self.a[candidate] < self.a[minimum]:
                    minimum = candidate
            if start != minimum:
                self.multi_swap(start, minimum, self.block_len)
            self.swap_to_tags(start, tag)

    def block_select_backward(self, position, count):
        for tag in range(count):
            start = position - tag * self.block_len
            minimum = start
            for index in range(tag + 1, count):
                candidate = position - index * self.block_len
                if self.a[candidate] < self.a[minimum]:
                    minimum = candidate
            if start != minimum:
                self.multi_swap_backward(start, minimum, self.block_len)
            self.swap_to_tags(start, tag)

    def in_place_merge(self, start, middle, end):
        i, j = start, middle
        while i < j and j < end:
            if self.a[i] > self.a[j]:
                k = self.binary_search(j, end, self.a[i], True)
                self.rotate(i, j, k)
                i += k - j
                j = k
            else:
                i += 1

    def in_place_merge_backward(self, start, middle, end):
        i, j = middle - 1, end - 1
        while j > i and i >= start:
            if self.a[i] >= self.a[j]:
                k = self.binary_search(start, i + 1, self.a[j], True)
                self.rotate(k, i + 1, j + 1)
                j -= i + 1 - k
                i = k - 1
            else:
                j -= 1

    def in_place_merge2(self, start, middle, end):
        i, m, k = start, middle, middle
        while m < end:
            if self.a[m - 1] <= self.a[m]:
                return
            while i < m - 1 and self.a[i] <= self.a[m]:
                i += 1
            self.swap(i, k)
            i += 1
            k += 1
            while i < m:
                while i < m and k < end and self.a[m] > self.a[k]:
                    self.swap(i, k)
                    i += 1
                    k += 1
                if i >= m:
                    break
                if k >= end:
                    self.rotate(i, m, end)
                    return
                if k - m >= m - i:
                    self.rotate(i, m, k)
                    break
                q = m
                while i < m and q < k and self.a[q] <= self.a[k]:
                    self.swap(i, q)
                    i += 1
                    q += 1
                self.rotate(m, q, k)
            m = k

    def in_place_merge_sort2(self, start, end):
        width = 1
        while width < end - start:
            position = start
            while position + 2 * width < end:
                self.in_place_merge2(position, position + width, position + 2 * width)
                position += 2 * width
            if position + width < end:
                self.in_place_merge2(position, position + width, end)
            width *= 2

    def merge_with_buf(self, start, middle, end, length):
        i, j, k = start, middle, start - length
        while i < middle and j < end:
            if self.a[i] <= self.a[j]:
                self.swap(k, i)
                i += 1
            else:
                self.swap(k, j)
                j += 1
            k += 1
        while j < end:
            self.swap(k, j)
            k += 1
            j += 1
        self.shift(k, i, middle, False)

    def dual_merge(self, start, middle, end, length):
        if end - middle <= length:
            self.merge_with_buf(start, middle, end, length)
            return
        i, j, k = start, middle, start - length
        while k < i and i < middle:
            if self.a[i] <= self.a[j]:
                self.swap(k, i)
                i += 1
            else:
                self.swap(k, j)
                j += 1
            k += 1
        if k < i:
            self.shift(j - length, j, end, False)
        else:
            i2, j2 = middle - 1, end - 1
            k = middle - 1 + end - j
            while i2 >= i and j2 >= j:
                if self.a[i2] > self.a[j2]:
                    self.swap(k, i2)
                    i2 -= 1
                else:
                    self.swap(k, j2)
                    j2 -= 1
                k -= 1
            while j2 >= j:
                self.swap(k, j2)
                k -= 1
                j2 -= 1

    def dual_merge_backward(self, start, middle, end, length):
        i, j, k = middle - 1, end - 1, end - 1 + length
        while k > j and j >= middle:
            if self.a[i] > self.a[j]:
                self.swap(k, i)
                i -= 1
            else:
                self.swap(k, j)
                j -= 1
            k -= 1
        if j < middle:
            self.shift(start, i + 1, i + 1 + length, True)
        else:
            first_end, second_end = i + 1, j + 1
            i2, j2 = start, middle
            k = middle - (first_end - start)
            while i2 < first_end and j2 < second_end:
                if self.a[i2] <= self.a[j2]:
                    self.swap(k, i2)
                    i2 += 1
                else:
                    self.swap(k, j2)
                    j2 += 1
                k += 1
            while i2 < first_end:
                self.swap(k, i2)
                k += 1
                i2 += 1

    def merge_with_buf_static(self, start, middle, end, position, backward):
        if middle - start <= 0 or end - middle <= 0:
            return
        if backward:
            i, j, k = end - middle - 1, middle - 1, end - 1
            while i >= 0 and j >= start:
                if self.a[j] >= self.a[position + i]:
                    q = self.binary_search(start, j + 1, self.a[position + i], True)
                    while j >= q:
                        self.swap(k, j)
                        k -= 1
                        j -= 1
                self.swap(k, position + i)
                k -= 1
                i -= 1
            while i >= 0:
                self.swap(k, position + i)
                k -= 1
                i -= 1
        else:
            i, j, k = 0, middle, start
            while i < middle - start and j < end:
                if self.a[j] < self.a[position + i]:
                    q = self.binary_search(j, end, self.a[position + i], True)
                    while j < q:
                        self.swap(k, j)
                        k += 1
                        j += 1
                self.swap(k, position + i)
                k += 1
                i += 1
            while i < middle - start:
                self.swap(k, position + i)
                k += 1
                i += 1

    def block_merge(self, start, middle, end):
        if end - middle <= 2 * self.buf_len:
            self.dual_merge(start, middle, end, self.buf_len)
            return
        i, j = start, middle
        left_available, right_available = self.buf_len, 0
        left, right, tag_count = i - self.buf_len, j, 0
        while i < middle and left_available >= right_available:
            count = 0
            while i < middle and count < self.block_len:
                if self.a[i] <= self.a[j]:
                    self.swap(left, i)
                    i += 1
                else:
                    self.swap(left, j)
                    j += 1
                    right_available += 1
                    left_available -= 1
                left += 1
                count += 1
        selection_start = left
        while i < middle and j < end:
            while i < middle and j < end and right_available > left_available:
                first = right
                count = 0
                while i < middle and j < end and count < self.block_len:
                    if self.a[i] <= self.a[j]:
                        self.swap(right, i)
                        i += 1
                        right_available -= 1
                        left_available += 1
                    else:
                        self.swap(right, j)
                        j += 1
                    right += 1
                    count += 1
                while i < middle and count < self.block_len:
                    self.swap(right, i)
                    right += 1
                    i += 1
                    right_available -= 1
                    left_available += 1
                    count += 1
                while j < end and count < self.block_len:
                    self.swap(right, j)
                    right += 1
                    j += 1
                    count += 1
                if count == self.block_len:
                    self.swap_to_tags(first, tag_count)
                    tag_count += 1
                else:
                    self.shift(first, first + count, end, True)
                    j = end - count
                    right = first
            while i < middle and j < end and left_available >= right_available:
                first = left
                count = 0
                while i < middle and j < end and count < self.block_len:
                    if self.a[i] <= self.a[j]:
                        self.swap(left, i)
                        i += 1
                    else:
                        self.swap(left, j)
                        j += 1
                        right_available += 1
                        left_available -= 1
                    left += 1
                    count += 1
                while i < middle and count < self.block_len:
                    self.swap(left, i)
                    left += 1
                    i += 1
                    count += 1
                while j < end and count < self.block_len:
                    self.swap(left, j)
                    left += 1
                    j += 1
                    right_available += 1
                    left_available -= 1
                    count += 1
                if count == self.block_len:
                    self.swap_to_tags(first, tag_count)
                    tag_count += 1
                else:
                    self.rotate(first, middle, right)
                    left += right - middle
                    left_available = 0
        if i >= middle and left_available == self.block_len and tag_count > 0:
            self.multi_swap(left, right - self.block_len, self.block_len)
        else:
            if i < middle:
                self.rotate(left, middle, right)
                left += right - middle
            self.shift(left, left + left_available, right, False)
        if j < end:
            self.shift(j - self.buf_len, j, end, False)
        self.block_select(selection_start, tag_count)

    def block_merge_backward(self, start, middle, end):
        i, j = middle - 1, end - 1
        left_available, right_available = 0, self.buf_len
        left, right, tag_count = i, j + self.buf_len, 0
        while j >= middle and right_available >= left_available:
            count = 0
            while j >= middle and count < self.block_len:
                if self.a[i] > self.a[j]:
                    self.swap(right, i)
                    i -= 1
                    left_available += 1
                    right_available -= 1
                else:
                    self.swap(right, j)
                    j -= 1
                right -= 1
                count += 1
        selection_start = right
        while j >= middle and i >= start:
            while j >= middle and i >= start and left_available > right_available:
                first, count = left, 0
                while j >= middle and i >= start and count < self.block_len:
                    if self.a[i] > self.a[j]:
                        self.swap(left, i)
                        i -= 1
                    else:
                        self.swap(left, j)
                        j -= 1
                        right_available += 1
                        left_available -= 1
                    left -= 1
                    count += 1
                while j >= middle and count < self.block_len:
                    self.swap(left, j)
                    left -= 1
                    j -= 1
                    right_available += 1
                    left_available -= 1
                    count += 1
                while i >= start and count < self.block_len:
                    self.swap(left, i)
                    left -= 1
                    i -= 1
                    count += 1
                if count == self.block_len:
                    self.swap_to_tags(first, tag_count)
                    tag_count += 1
                else:
                    self.shift(start, first + 1 - count, first + 1, False)
                    i = start - 1 + count
                    left = first
            while j >= middle and i >= start and right_available >= left_available:
                first, count = right, 0
                while j >= middle and i >= start and count < self.block_len:
                    if self.a[i] > self.a[j]:
                        self.swap(right, i)
                        i -= 1
                        left_available += 1
                        right_available -= 1
                    else:
                        self.swap(right, j)
                        j -= 1
                    right -= 1
                    count += 1
                while j >= middle and count < self.block_len:
                    self.swap(right, j)
                    right -= 1
                    j -= 1
                    count += 1
                while i >= start and count < self.block_len:
                    self.swap(right, i)
                    right -= 1
                    i -= 1
                    left_available += 1
                    right_available -= 1
                    count += 1
                if count == self.block_len:
                    self.swap_to_tags(first, tag_count)
                    tag_count += 1
                else:
                    self.rotate(left + 1, middle, first + 1)
                    right -= middle - (left + 1)
                    right_available = 0
        if j < middle and right_available == self.block_len and tag_count > 0:
            self.multi_swap_backward(right, left + self.block_len, self.block_len)
        else:
            if j >= middle:
                self.rotate(left + 1, middle, right + 1)
                right -= middle - (left + 1)
            self.shift(left + 1, right + 1 - right_available, right + 1, True)
        if i >= start:
            self.shift(start, i + 1, i + 1 + self.buf_len, True)
        self.block_select_backward(selection_start, tag_count)

    def kota_iterator(self, start, end):
        width = 1
        effective_start = start + self.buf_len
        length = end - effective_start
        while width < 16:
            position = effective_start
            while position + 2 * width < end:
                self.in_place_merge2(position, position + width, position + 2 * width)
                position += 2 * width
            if position + width < end:
                self.in_place_merge2(position, position + width, end)
            width *= 2
        while width <= self.buf_len:
            length_of_buffer = width
            position = effective_start
            while position + 2 * width < end:
                self.merge_with_buf(position, position + width,
                                    position + 2 * width, length_of_buffer)
                position += 2 * width
            if position + width < end:
                self.merge_with_buf(position, position + width, end, length_of_buffer)
            else:
                self.shift(position - length_of_buffer, position, end, False)
            width *= 2
            position = effective_start - length_of_buffer
            while position + 2 * width < end - length_of_buffer:
                position += 2 * width
            if position + width < end - length_of_buffer:
                self.dual_merge_backward(position, position + width,
                                         end - length_of_buffer, length_of_buffer)
            else:
                self.shift(position, end - length_of_buffer, end, True)
            position -= 2 * width
            while position >= effective_start - length_of_buffer:
                self.dual_merge_backward(position, position + width,
                                         position + 2 * width, length_of_buffer)
                position -= 2 * width
            width *= 2
        while width < length:
            position = effective_start
            while position + 2 * width < end:
                self.block_merge(position, position + width, position + 2 * width)
                position += 2 * width
            if position + width < end:
                self.block_merge(position, position + width, end)
            else:
                self.shift(position - self.buf_len, position, end, False)
            width *= 2
            if width >= length:
                return True
            position = start
            while position + 2 * width < end - self.buf_len:
                position += 2 * width
            if position + width < end - self.buf_len:
                self.block_merge_backward(position, position + width,
                                          end - self.buf_len)
            else:
                self.shift(position, end - self.buf_len, end, True)
            position -= 2 * width
            while position >= start:
                self.block_merge_backward(position, position + width,
                                          position + 2 * width)
                position -= 2 * width
            width *= 2
        return False

    def sort(self):
        length = len(self.a)
        if length <= 128:
            self.in_place_merge_sort2(0, length)
            return
        self.buf_pos = 0
        self.block_len = 1
        while self.block_len * self.block_len < length:
            self.block_len *= 2
        buffer_target = 2 * self.block_len
        self.buf_len = self.find_keys(0, length, buffer_target)
        if self.buf_len < buffer_target:
            if self.buf_len > 1:
                self.in_place_merge_sort2(0, length)
            return
        tag_target = length // self.block_len
        self.tag_len = self.find_keys(self.buf_len, length, tag_target)
        if self.tag_len < tag_target:
            self.in_place_merge_sort2(0, length)
            return
        buffer_start = self.tag_len
        effective_start = buffer_start + self.buf_len
        buffer_end = self.buf_len
        self.shift(0, buffer_end, effective_start, False)
        backward = self.kota_iterator(buffer_start, length)
        if backward:
            end_start = length - self.buf_len
            self.multi_swap(0, end_start, self.tag_len)
            self.merge_with_buf_static(0, buffer_start, end_start, end_start, False)
            self.in_place_merge_sort2(end_start, length)
            middle = end_start + self.block_len
            position = self.binary_search(0, end_start, self.a[middle - 1], True)
            self.rotate(position, end_start, middle)
            position += self.block_len
            self.multi_swap_backward(length - 1, position - 1, self.block_len)
            self.merge_with_buf_static(0, position - self.block_len, position, middle, True)
            self.in_place_merge_sort2(middle, length)
            self.in_place_merge_backward(position, middle, length)
            self.in_place_merge(0, position, length)
        else:
            self.merge_with_buf_static(buffer_end, effective_start, length, 0, False)
            self.in_place_merge_sort2(0, buffer_end)
            middle = self.block_len
            position = self.binary_search(buffer_end, length, self.a[middle], True)
            self.rotate(middle, buffer_end, position)
            position -= self.block_len
            self.multi_swap(0, position, self.block_len)
            self.merge_with_buf_static(position, position + self.block_len, length, 0, False)
            self.in_place_merge_sort2(0, middle)
            self.in_place_merge(0, middle, position)
            self.in_place_merge2(length - 2 * self.block_len,
                                 length - self.block_len, length)
            self.in_place_merge(0, length - 2 * self.block_len, length)


def sort(values):
    KotaSortExample(values).sort()


if __name__ == "__main__":
    array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
    sort(array)
    print(array)
