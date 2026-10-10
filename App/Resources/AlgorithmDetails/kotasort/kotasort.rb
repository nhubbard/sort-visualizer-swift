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



class KotaSortExample
  def initialize(values)
    @a = values
    @buf_pos = 0
    @block_len = 0
    @buf_len = 0
    @tag_len = 0
  end
  def swap(left, right)
    @a[left], @a[right] = @a[right], @a[left]
  end
  def rotate(start, middle, finish)
    left_len, right_len = (middle - start), (finish - middle)
    while left_len != 0 && right_len != 0
      if (left_len <= right_len)
        (0...left_len).each do |offset|
          swap((start + offset), ((start + left_len) + offset))
        end
        start += left_len
        right_len -= left_len
      else
        (0...right_len).each do |offset|
          swap((((start + left_len) - right_len) + offset), ((start + left_len) + offset))
        end
        left_len -= right_len
      end
    end
  end
  def binary_search(start, finish, value, left)
    while (start < finish)
      middle = (start + ((finish - start) / 2))
      if (left ? (@a[middle] >= value) : (@a[middle] > value))
        finish = middle
      else
        start = (middle + 1)
      end
    end
    return start
  end
  def find_keys(start, finish, target)
    count, pos, pos_end, index = 1, start, (start + 1), (start + 1)
    while ((index < finish) && (count < target))
      value = @a[index]
      loc = binary_search(pos, pos_end, value, true)
      if ((index == loc) || (value != @a[loc]))
        rotate(pos, pos_end, index)
        increase = (index - pos_end)
        loc += increase
        pos += increase
        pos_end += increase
        rotate(loc, pos_end, (pos_end + 1))
        count += 1
        pos_end += 1
      end
      index += 1
    end
    rotate(start, pos, pos_end)
    return count
  end
  def swap_to_tags(position, tag)
    swap((@buf_pos + tag), position)
  end
  def shift(start, middle, finish, left)
    if left
      while (middle > start)
        finish -= 1
        middle -= 1
        swap(finish, middle)
      end
    else
      while (middle < finish)
        swap(start, middle)
        start += 1
        middle += 1
      end
    end
  end
  def multi_swap(first, second, length)
    (0...length).each do |offset|
      swap((first + offset), (second + offset))
    end
  end
  def multi_swap_backward(first, second, length)
    (0...length).each do |offset|
      swap((first - offset), (second - offset))
    end
  end
  def block_select(position, count)
    (0...count).each do |tag|
      start = (position + (tag * @block_len))
      minimum = start
      ((tag + 1)...count).each do |index|
        candidate = (position + (index * @block_len))
        if (@a[candidate] < @a[minimum])
          minimum = candidate
        end
      end
      if (start != minimum)
        multi_swap(start, minimum, @block_len)
      end
      swap_to_tags(start, tag)
    end
  end
  def block_select_backward(position, count)
    (0...count).each do |tag|
      start = (position - (tag * @block_len))
      minimum = start
      ((tag + 1)...count).each do |index|
        candidate = (position - (index * @block_len))
        if (@a[candidate] < @a[minimum])
          minimum = candidate
        end
      end
      if (start != minimum)
        multi_swap_backward(start, minimum, @block_len)
      end
      swap_to_tags(start, tag)
    end
  end
  def in_place_merge(start, middle, finish)
    i, j = start, middle
    while ((i < j) && (j < finish))
      if (@a[i] > @a[j])
        k = binary_search(j, finish, @a[i], true)
        rotate(i, j, k)
        i += (k - j)
        j = k
      else
        i += 1
      end
    end
  end
  def in_place_merge_backward(start, middle, finish)
    i, j = (middle - 1), (finish - 1)
    while ((j > i) && (i >= start))
      if (@a[i] >= @a[j])
        k = binary_search(start, (i + 1), @a[j], true)
        rotate(k, (i + 1), (j + 1))
        j -= ((i + 1) - k)
        i = (k - 1)
      else
        j -= 1
      end
    end
  end
  def in_place_merge2(start, middle, finish)
    i, m, k = start, middle, middle
    while (m < finish)
      if (@a[(m - 1)] <= @a[m])
        return
      end
      while ((i < (m - 1)) && (@a[i] <= @a[m]))
        i += 1
      end
      swap(i, k)
      i += 1
      k += 1
      while (i < m)
        while ((i < m) && (k < finish) && (@a[m] > @a[k]))
          swap(i, k)
          i += 1
          k += 1
        end
        if (i >= m)
          break
        end
        if (k >= finish)
          rotate(i, m, finish)
          return
        end
        if ((k - m) >= (m - i))
          rotate(i, m, k)
          break
        end
        q = m
        while ((i < m) && (q < k) && (@a[q] <= @a[k]))
          swap(i, q)
          i += 1
          q += 1
        end
        rotate(m, q, k)
      end
      m = k
    end
  end
  def in_place_merge_sort2(start, finish)
    width = 1
    while (width < (finish - start))
      position = start
      while ((position + (2 * width)) < finish)
        in_place_merge2(position, (position + width), (position + (2 * width)))
        position += (2 * width)
      end
      if ((position + width) < finish)
        in_place_merge2(position, (position + width), finish)
      end
      width *= 2
    end
  end
  def merge_with_buf(start, middle, finish, length)
    i, j, k = start, middle, (start - length)
    while ((i < middle) && (j < finish))
      if (@a[i] <= @a[j])
        swap(k, i)
        i += 1
      else
        swap(k, j)
        j += 1
      end
      k += 1
    end
    while (j < finish)
      swap(k, j)
      k += 1
      j += 1
    end
    shift(k, i, middle, false)
  end
  def dual_merge(start, middle, finish, length)
    if ((finish - middle) <= length)
      merge_with_buf(start, middle, finish, length)
      return
    end
    i, j, k = start, middle, (start - length)
    while ((k < i) && (i < middle))
      if (@a[i] <= @a[j])
        swap(k, i)
        i += 1
      else
        swap(k, j)
        j += 1
      end
      k += 1
    end
    if (k < i)
      shift((j - length), j, finish, false)
    else
      i2, j2 = (middle - 1), (finish - 1)
      k = (((middle - 1) + finish) - j)
      while ((i2 >= i) && (j2 >= j))
        if (@a[i2] > @a[j2])
          swap(k, i2)
          i2 -= 1
        else
          swap(k, j2)
          j2 -= 1
        end
        k -= 1
      end
      while (j2 >= j)
        swap(k, j2)
        k -= 1
        j2 -= 1
      end
    end
  end
  def dual_merge_backward(start, middle, finish, length)
    i, j, k = (middle - 1), (finish - 1), ((finish - 1) + length)
    while ((k > j) && (j >= middle))
      if (@a[i] > @a[j])
        swap(k, i)
        i -= 1
      else
        swap(k, j)
        j -= 1
      end
      k -= 1
    end
    if (j < middle)
      shift(start, (i + 1), ((i + 1) + length), true)
    else
      first_end, second_end = (i + 1), (j + 1)
      i2, j2 = start, middle
      k = (middle - (first_end - start))
      while ((i2 < first_end) && (j2 < second_end))
        if (@a[i2] <= @a[j2])
          swap(k, i2)
          i2 += 1
        else
          swap(k, j2)
          j2 += 1
        end
        k += 1
      end
      while (i2 < first_end)
        swap(k, i2)
        k += 1
        i2 += 1
      end
    end
  end
  def merge_with_buf_static(start, middle, finish, position, backward)
    if (((middle - start) <= 0) || ((finish - middle) <= 0))
      return
    end
    if backward
      i, j, k = ((finish - middle) - 1), (middle - 1), (finish - 1)
      while ((i >= 0) && (j >= start))
        if (@a[j] >= @a[(position + i)])
          q = binary_search(start, (j + 1), @a[(position + i)], true)
          while (j >= q)
            swap(k, j)
            k -= 1
            j -= 1
          end
        end
        swap(k, (position + i))
        k -= 1
        i -= 1
      end
      while (i >= 0)
        swap(k, (position + i))
        k -= 1
        i -= 1
      end
    else
      i, j, k = 0, middle, start
      while ((i < (middle - start)) && (j < finish))
        if (@a[j] < @a[(position + i)])
          q = binary_search(j, finish, @a[(position + i)], true)
          while (j < q)
            swap(k, j)
            k += 1
            j += 1
          end
        end
        swap(k, (position + i))
        k += 1
        i += 1
      end
      while (i < (middle - start))
        swap(k, (position + i))
        k += 1
        i += 1
      end
    end
  end
  def block_merge(start, middle, finish)
    if ((finish - middle) <= (2 * @buf_len))
      dual_merge(start, middle, finish, @buf_len)
      return
    end
    i, j = start, middle
    left_available, right_available = @buf_len, 0
    left, right, tag_count = (i - @buf_len), j, 0
    while ((i < middle) && (left_available >= right_available))
      count = 0
      while ((i < middle) && (count < @block_len))
        if (@a[i] <= @a[j])
          swap(left, i)
          i += 1
        else
          swap(left, j)
          j += 1
          right_available += 1
          left_available -= 1
        end
        left += 1
        count += 1
      end
    end
    selection_start = left
    while ((i < middle) && (j < finish))
      while ((i < middle) && (j < finish) && (right_available > left_available))
        first = right
        count = 0
        while ((i < middle) && (j < finish) && (count < @block_len))
          if (@a[i] <= @a[j])
            swap(right, i)
            i += 1
            right_available -= 1
            left_available += 1
          else
            swap(right, j)
            j += 1
          end
          right += 1
          count += 1
        end
        while ((i < middle) && (count < @block_len))
          swap(right, i)
          right += 1
          i += 1
          right_available -= 1
          left_available += 1
          count += 1
        end
        while ((j < finish) && (count < @block_len))
          swap(right, j)
          right += 1
          j += 1
          count += 1
        end
        if (count == @block_len)
          swap_to_tags(first, tag_count)
          tag_count += 1
        else
          shift(first, (first + count), finish, true)
          j = (finish - count)
          right = first
        end
      end
      while ((i < middle) && (j < finish) && (left_available >= right_available))
        first = left
        count = 0
        while ((i < middle) && (j < finish) && (count < @block_len))
          if (@a[i] <= @a[j])
            swap(left, i)
            i += 1
          else
            swap(left, j)
            j += 1
            right_available += 1
            left_available -= 1
          end
          left += 1
          count += 1
        end
        while ((i < middle) && (count < @block_len))
          swap(left, i)
          left += 1
          i += 1
          count += 1
        end
        while ((j < finish) && (count < @block_len))
          swap(left, j)
          left += 1
          j += 1
          right_available += 1
          left_available -= 1
          count += 1
        end
        if (count == @block_len)
          swap_to_tags(first, tag_count)
          tag_count += 1
        else
          rotate(first, middle, right)
          left += (right - middle)
          left_available = 0
        end
      end
    end
    if ((i >= middle) && (left_available == @block_len) && (tag_count > 0))
      multi_swap(left, (right - @block_len), @block_len)
    else
      if (i < middle)
        rotate(left, middle, right)
        left += (right - middle)
      end
      shift(left, (left + left_available), right, false)
    end
    if (j < finish)
      shift((j - @buf_len), j, finish, false)
    end
    block_select(selection_start, tag_count)
  end
  def block_merge_backward(start, middle, finish)
    i, j = (middle - 1), (finish - 1)
    left_available, right_available = 0, @buf_len
    left, right, tag_count = i, (j + @buf_len), 0
    while ((j >= middle) && (right_available >= left_available))
      count = 0
      while ((j >= middle) && (count < @block_len))
        if (@a[i] > @a[j])
          swap(right, i)
          i -= 1
          left_available += 1
          right_available -= 1
        else
          swap(right, j)
          j -= 1
        end
        right -= 1
        count += 1
      end
    end
    selection_start = right
    while ((j >= middle) && (i >= start))
      while ((j >= middle) && (i >= start) && (left_available > right_available))
        first, count = left, 0
        while ((j >= middle) && (i >= start) && (count < @block_len))
          if (@a[i] > @a[j])
            swap(left, i)
            i -= 1
          else
            swap(left, j)
            j -= 1
            right_available += 1
            left_available -= 1
          end
          left -= 1
          count += 1
        end
        while ((j >= middle) && (count < @block_len))
          swap(left, j)
          left -= 1
          j -= 1
          right_available += 1
          left_available -= 1
          count += 1
        end
        while ((i >= start) && (count < @block_len))
          swap(left, i)
          left -= 1
          i -= 1
          count += 1
        end
        if (count == @block_len)
          swap_to_tags(first, tag_count)
          tag_count += 1
        else
          shift(start, ((first + 1) - count), (first + 1), false)
          i = ((start - 1) + count)
          left = first
        end
      end
      while ((j >= middle) && (i >= start) && (right_available >= left_available))
        first, count = right, 0
        while ((j >= middle) && (i >= start) && (count < @block_len))
          if (@a[i] > @a[j])
            swap(right, i)
            i -= 1
            left_available += 1
            right_available -= 1
          else
            swap(right, j)
            j -= 1
          end
          right -= 1
          count += 1
        end
        while ((j >= middle) && (count < @block_len))
          swap(right, j)
          right -= 1
          j -= 1
          count += 1
        end
        while ((i >= start) && (count < @block_len))
          swap(right, i)
          right -= 1
          i -= 1
          left_available += 1
          right_available -= 1
          count += 1
        end
        if (count == @block_len)
          swap_to_tags(first, tag_count)
          tag_count += 1
        else
          rotate((left + 1), middle, (first + 1))
          right -= (middle - (left + 1))
          right_available = 0
        end
      end
    end
    if ((j < middle) && (right_available == @block_len) && (tag_count > 0))
      multi_swap_backward(right, (left + @block_len), @block_len)
    else
      if (j >= middle)
        rotate((left + 1), middle, (right + 1))
        right -= (middle - (left + 1))
      end
      shift((left + 1), ((right + 1) - right_available), (right + 1), true)
    end
    if (i >= start)
      shift(start, (i + 1), ((i + 1) + @buf_len), true)
    end
    block_select_backward(selection_start, tag_count)
  end
  def kota_iterator(start, finish)
    width = 1
    effective_start = (start + @buf_len)
    length = (finish - effective_start)
    while (width < 16)
      position = effective_start
      while ((position + (2 * width)) < finish)
        in_place_merge2(position, (position + width), (position + (2 * width)))
        position += (2 * width)
      end
      if ((position + width) < finish)
        in_place_merge2(position, (position + width), finish)
      end
      width *= 2
    end
    while (width <= @buf_len)
      length_of_buffer = width
      position = effective_start
      while ((position + (2 * width)) < finish)
        merge_with_buf(position, (position + width), (position + (2 * width)), length_of_buffer)
        position += (2 * width)
      end
      if ((position + width) < finish)
        merge_with_buf(position, (position + width), finish, length_of_buffer)
      else
        shift((position - length_of_buffer), position, finish, false)
      end
      width *= 2
      position = (effective_start - length_of_buffer)
      while ((position + (2 * width)) < (finish - length_of_buffer))
        position += (2 * width)
      end
      if ((position + width) < (finish - length_of_buffer))
        dual_merge_backward(position, (position + width), (finish - length_of_buffer), length_of_buffer)
      else
        shift(position, (finish - length_of_buffer), finish, true)
      end
      position -= (2 * width)
      while (position >= (effective_start - length_of_buffer))
        dual_merge_backward(position, (position + width), (position + (2 * width)), length_of_buffer)
        position -= (2 * width)
      end
      width *= 2
    end
    while (width < length)
      position = effective_start
      while ((position + (2 * width)) < finish)
        block_merge(position, (position + width), (position + (2 * width)))
        position += (2 * width)
      end
      if ((position + width) < finish)
        block_merge(position, (position + width), finish)
      else
        shift((position - @buf_len), position, finish, false)
      end
      width *= 2
      if (width >= length)
        return true
      end
      position = start
      while ((position + (2 * width)) < (finish - @buf_len))
        position += (2 * width)
      end
      if ((position + width) < (finish - @buf_len))
        block_merge_backward(position, (position + width), (finish - @buf_len))
      else
        shift(position, (finish - @buf_len), finish, true)
      end
      position -= (2 * width)
      while (position >= start)
        block_merge_backward(position, (position + width), (position + (2 * width)))
        position -= (2 * width)
      end
      width *= 2
    end
    return false
  end
  def sort()
    length = @a.length
    if (length <= 128)
      in_place_merge_sort2(0, length)
      return
    end
    @buf_pos = 0
    @block_len = 1
    while ((@block_len * @block_len) < length)
      @block_len *= 2
    end
    buffer_target = (2 * @block_len)
    @buf_len = find_keys(0, length, buffer_target)
    if (@buf_len < buffer_target)
      if (@buf_len > 1)
        in_place_merge_sort2(0, length)
      end
      return
    end
    tag_target = (length / @block_len)
    @tag_len = find_keys(@buf_len, length, tag_target)
    if (@tag_len < tag_target)
      in_place_merge_sort2(0, length)
      return
    end
    buffer_start = @tag_len
    effective_start = (buffer_start + @buf_len)
    buffer_end = @buf_len
    shift(0, buffer_end, effective_start, false)
    backward = kota_iterator(buffer_start, length)
    if backward
      end_start = (length - @buf_len)
      multi_swap(0, end_start, @tag_len)
      merge_with_buf_static(0, buffer_start, end_start, end_start, false)
      in_place_merge_sort2(end_start, length)
      middle = (end_start + @block_len)
      position = binary_search(0, end_start, @a[(middle - 1)], true)
      rotate(position, end_start, middle)
      position += @block_len
      multi_swap_backward((length - 1), (position - 1), @block_len)
      merge_with_buf_static(0, (position - @block_len), position, middle, true)
      in_place_merge_sort2(middle, length)
      in_place_merge_backward(position, middle, length)
      in_place_merge(0, position, length)
    else
      merge_with_buf_static(buffer_end, effective_start, length, 0, false)
      in_place_merge_sort2(0, buffer_end)
      middle = @block_len
      position = binary_search(buffer_end, length, @a[middle], true)
      rotate(middle, buffer_end, position)
      position -= @block_len
      multi_swap(0, position, @block_len)
      merge_with_buf_static(position, (position + @block_len), length, 0, false)
      in_place_merge_sort2(0, middle)
      in_place_merge(0, middle, position)
      in_place_merge2((length - (2 * @block_len)), (length - @block_len), length)
      in_place_merge(0, (length - (2 * @block_len)), length)
    end
  end
end
def sort(values)
  KotaSortExample.new(values).sort()
end
array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
