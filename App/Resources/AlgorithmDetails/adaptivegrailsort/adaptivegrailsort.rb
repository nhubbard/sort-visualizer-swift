# MIT License
# Copyright (c) 2013 Andrey Astrelin
# Copyright (c) 2020 The Holy Grail Sort Project
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

class AdaptiveGrailExample
  def initialize(input)
    @values = input
    @min_run = 16
  end

  def read(index)
    @values[index]
  end

  def write(index, value)
    @values[index] = value
  end

  def swap(first, second)
    @values[first], @values[second] = @values[second], @values[first]
  end

  def compare(first, second)
    if @values[first] < @values[second]
      return -1
    end
    if @values[first] > @values[second]
      return 1
    end
    0
  end

  def compare_value(index, value)
    if @values[index] < value
      return -1
    end
    if @values[index] > value
      return 1
    end
    0
  end

  def reverse(start, finish)
    left = start
    right = (finish - 1)
    while left < right
      @values[left], @values[right] = @values[right], @values[left]
      left += 1
      right -= 1
    end
  end

  def multi_swap(first, second, count)
    if !(count > 0)
      return
    end
    (0...count).each do |offset|
      swap(first + offset, second + offset)
    end
  end

  def multi_tri_swap(first, second, third, count)
    if !(count > 0)
      return
    end
    (0...count).each do |offset|
      value = read(first + offset)
      write(first + offset, read(second + offset))
      write(second + offset, read(third + offset))
      write(third + offset, value)
    end
  end

  def insert_to(source, destination)
    value = read(source)
    cursor = source
    while cursor > destination
      write(cursor, read(cursor - 1))
      cursor -= 1
    end
    write(destination, value)
  end

  def insert_to_backward(source, destination)
    value = read(source)
    cursor = source
    while cursor < destination
      write(cursor, read(cursor + 1))
      cursor += 1
    end
    write(cursor, value)
  end

  def shift(destination, source, finish)
    if !(source < finish)
      return
    end
    (0...(finish - source)).each do |offset|
      swap(destination + offset, source + offset)
    end
  end

  def rotate(start_in, middle_in, end_in)
    start = start_in
    middle = middle_in
    finish = end_in
    left = (middle - start)
    right = (finish - middle)
    while (left > 1) && (right > 1)
      if right < left
        multi_swap(middle - right, middle, right)
        finish -= right
        middle -= right
        left -= right
      else
        multi_swap(start, middle, left)
        start += left
        middle += left
        right -= left
      end
    end
    if right == 1
      insert_to(middle, start)
    elsif left == 1
      insert_to_backward(start, finish - 1)
    end
  end

  def left_binary_search(start, finish, value)
    lower = start
    upper = finish
    while lower < upper
      middle = (lower + ((upper - lower) / 2))
      if @values[middle] >= value
        upper = middle
      else
        lower = (middle + 1)
      end
    end
    lower
  end

  def right_binary_search(start, finish, value)
    lower = start
    upper = finish
    while lower < upper
      middle = (lower + ((upper - lower) / 2))
      if @values[middle] > value
        upper = middle
      else
        lower = (middle + 1)
      end
    end
    lower
  end

  def build_unique_run(start, limit)
    count = 1
    index = (start + 1)
    order = compare(index - 1, index)
    if order < 0
      index += 1
      count += 1
      while (count < limit) && (compare(index - 1, index) < 0)
        index += 1
        count += 1
      end
    elsif order > 0
      index += 1
      count += 1
      while (count < limit) && (compare(index - 1, index) > 0)
        index += 1
        count += 1
      end
      reverse(start, index)
    end
    count
  end

  def build_unique_run_backward(finish, limit)
    count = 1
    index = (finish - 1)
    order = compare(index - 1, index)
    if order < 0
      index -= 1
      count += 1
      while (count < limit) && (compare(index - 1, index) < 0)
        index -= 1
        count += 1
      end
    elsif order > 0
      index -= 1
      count += 1
      while (count < limit) && (compare(index - 1, index) > 0)
        index -= 1
        count += 1
      end
      reverse(index, finish)
    end
    count
  end

  def find_keys(start, finish, initial, needed)
    count = initial
    key_start = start
    key_end = (start + count)
    index = key_end
    while (index < finish) && (count < needed)
      candidate = read(index)
      location = left_binary_search(key_start, key_end, candidate)
      if (location == key_end) || (compare_value(location, candidate) != 0)
        rotate(key_start, key_end, index)
        distance = (index - key_end)
        location += distance
        key_start += distance
        key_end += distance
        insert_to(key_end, location)
        count += 1
        key_end += 1
      end
      index += 1
    end
    rotate(start, key_start, key_end)
    count
  end

  def find_keys_backward(start, finish, initial, needed)
    count = initial
    key_start = (finish - count)
    key_end = finish
    index = (key_start - 1)
    while (index >= start) && (count < needed)
      candidate = read(index)
      location = left_binary_search(key_start, key_end, candidate)
      if (location == key_end) || (compare_value(location, candidate) != 0)
        rotate(index + 1, key_start, key_end)
        distance = (key_start - (index + 1))
        location -= distance
        key_end -= distance
        key_start -= (distance + 1)
        count += 1
        insert_to_backward(index, location - 1)
      end
      index -= 1
    end
    rotate(key_start, key_end, finish)
    count
  end

  def build_runs(start, finish)
    index = (start + 1)
    run_start = start
    while index < finish
      descending = compare(index - 1, index) > 0
      index += 1
      if descending
        while (index < finish) && (compare(index - 1, index) > 0)
          index += 1
        end
        reverse(run_start, index)
      else
        while (index < finish) && (compare(index - 1, index) <= 0)
          index += 1
        end
      end
      if index < finish
        run_start = ((index - (((index - run_start) - 1) % @min_run)) - 1)
      end
      while ((index - run_start) < @min_run) && (index < finish)
        insert_to(index, right_binary_search(run_start, index, read(index)))
        index += 1
      end
      run_start = index
      index += 1
    end
  end

  def binary_insertion(start, finish)
    if !((finish - start) > 1)
      return
    end
    ((start + 1)...finish).each do |index|
      insert_to(index, right_binary_search(start, index, read(index)))
    end
  end

  def merge_with_buffer_rest(start, middle, finish, buffer, length)
    left = 0
    right = middle
    output = start
    while (left < length) && (right < finish)
      if compare(buffer + left, right) <= 0
        swap(output, buffer + left)
        left += 1
      else
        swap(output, right)
        right += 1
      end
      output += 1
    end
    while left < length
      swap(output, buffer + left)
      output += 1
      left += 1
    end
  end

  def merge_with_buffer(start, middle, finish, buffer)
    length = (middle - start)
    multi_swap(buffer, start, length)
    merge_with_buffer_rest(start, middle, finish, buffer, length)
  end

  def merge_with_buffer_backward(start, middle, finish, buffer)
    length = (finish - middle)
    multi_swap(middle, buffer, length)
    left = (length - 1)
    right = (middle - 1)
    output = (finish - 1)
    while (left >= 0) && (right >= start)
      if compare(buffer + left, right) >= 0
        swap(output, buffer + left)
        left -= 1
      else
        swap(output, right)
        right -= 1
      end
      output -= 1
    end
    while left >= 0
      swap(output, buffer + left)
      output -= 1
      left -= 1
    end
  end

  def in_place_merge(start, middle, finish)
    left = start
    right = middle
    while (left < right) && (right < finish)
      if compare(left, right) > 0
        next_value = left_binary_search(right + 1, finish, read(left))
        rotate(left, right, next_value)
        left += (next_value - right)
        right = next_value
      else
        left += 1
      end
    end
  end

  def in_place_merge_backward(start, middle, finish)
    left = (middle - 1)
    right = (finish - 1)
    while (right > left) && (left >= start)
      if compare(left, right) > 0
        next_value = right_binary_search(start, left, read(right))
        rotate(next_value, left + 1, right + 1)
        right -= ((left + 1) - next_value)
        left = (next_value - 1)
      else
        right -= 1
      end
    end
  end

  def merge_without_buffer(start, middle, finish)
    if (middle - start) > (finish - middle)
      in_place_merge_backward(start, middle, finish)
    else
      in_place_merge(start, middle, finish)
    end
  end

  def check_sorted(middle)
    compare(middle - 1, middle) > 0
  end

  def check_reverse_bounds(start, middle, finish)
    if compare(start, finish - 1) > 0
      rotate(start, middle, finish)
      return false
    end
    true
  end

  def check_bounds(start, middle, finish)
    check_sorted(middle) && check_reverse_bounds(start, middle, finish)
  end

  def subarray(tag, middle_key)
    ((compare(tag, middle_key) < 0) ? "left" : "right")
  end

  def block_select_sort(position, tags, offset, distance, left_count, block_count, block_length)
    middle_key = left_count
    index = 0
    limit = (left_count + 1)
    while index < (limit - 1)
      minimum = index
      candidate = [(left_count - offset), (index + 1)].max
      while candidate < limit
        order = compare((position + distance) + (candidate * block_length), (position + distance) + (minimum * block_length))
        if (order < 0) || ((order == 0) && (compare(tags + candidate, tags + minimum) < 0))
          minimum = candidate
        end
        candidate += 1
      end
      if minimum != index
        multi_swap(position + (index * block_length), position + (minimum * block_length), block_length)
        swap(tags + index, tags + minimum)
        if (limit < block_count) && (minimum == (limit - 1))
          limit += 1
        end
      end
      if minimum == middle_key
        middle_key = index
      end
      index += 1
    end
    tags + middle_key
  end

  def sort_keys(finish, buffer, middle_key)
    swap(buffer, middle_key)
    left = middle_key
    index = (left + 1)
    right = (buffer + 1)
    while index < finish
      if compare(index, buffer) < 0
        swap(left, index)
        left += 1
      else
        swap(right, index)
        right += 1
      end
      index += 1
    end
    multi_swap(left, buffer, finish - left)
  end

  def sort_keys_without_buffer(finish, middle_key)
    left = middle_key
    index = (left + 1)
    while index < finish
      if compare(index, left) < 0
        insert_to(index, left)
        left += 1
      end
      index += 1
    end
  end

  def merge_blocks(start, middle, finish, destination, reverse_equal)
    left = start
    right = middle
    output = destination
    while (left < middle) && (right < finish)
      order = compare(left, right)
      if (order < 0) || ((order == 0) && !reverse_equal)
        swap(output, left)
        left += 1
      else
        swap(output, right)
        right += 1
      end
      output += 1
    end
    if left > output
      while left < middle
        swap(output, left)
        output += 1
        left += 1
      end
    end
    right
  end

  def block_merge(start, middle, finish, tags, buffer, block_length)
    last_full = ((finish - (((finish - middle) - 1) % block_length)) - 1)
    left = (start + block_length)
    group = start
    key = (tags - 1)
    left_count = ((middle - left) / block_length)
    block_count = ((last_full - left) / block_length)
    left_blocks = -1
    right_blocks = (left_count - 1)
    multi_tri_swap(buffer, middle - block_length, start, block_length)
    insert_to_backward(tags, (tags + left_count) - 1)
    middle_key = block_select_sort(left, tags, 1, block_length - 1, left_count, block_count, block_length)
    fragment = "left"
    while (left_blocks < left_count) && (right_blocks < block_count)
      if fragment == "left"
        loop do
          group += block_length
          left_blocks += 1
          key += 1
          if !((left_blocks < left_count) && (subarray(key, middle_key) == "left"))
            break
          end
        end
        if left_blocks == left_count
          left = merge_blocks(left, group, finish, left - block_length, false)
          merge_with_buffer_rest(left - block_length, left, finish, buffer, block_length)
        else
          left = merge_blocks(left, group, (group + block_length) - 1, left - block_length, false)
        end
        fragment = "right"
      else
        loop do
          group += block_length
          right_blocks += 1
          key += 1
          if !((right_blocks < block_count) && (subarray(key, middle_key) == "right"))
            break
          end
        end
        if right_blocks == block_count
          shift(left - block_length, left, finish)
          multi_swap(buffer, finish - block_length, block_length)
        else
          left = merge_blocks(left, group, (group + block_length) - 1, left - block_length, true)
        end
        fragment = "left"
      end
    end
    sort_keys(tags + block_count, buffer, middle_key)
  end

  def block_merge_without_buffer(start, middle, finish, tags, block_length)
    first_full = (start + ((middle - start) % block_length))
    last_full = (finish - ((finish - middle) % block_length))
    left = start
    group = first_full
    key = tags
    left_count = (((middle - group) / block_length) + 1)
    block_count = (((last_full - group) / block_length) + 1)
    left_blocks = 0
    right_blocks = left_count
    middle_key = block_select_sort(group, tags, 0, 0, left_count - 1, block_count - 1, block_length)
    fragment = "left"
    while (left_blocks < left_count) && (right_blocks < block_count)
      next_value = subarray(key, middle_key)
      key += 1
      if next_value == fragment
        if fragment == "left"
          left_blocks += 1
        else
          right_blocks += 1
        end
        left = group
      else
        middle2 = group
        end2 = (group + block_length)
        if fragment == "left"
          while (left < middle2) && (middle2 < end2)
            if compare(left, middle2) > 0
              next_position = left_binary_search(middle2 + 1, end2, read(left))
              rotate(left, middle2, next_position)
              left += (next_position - middle2)
              middle2 = next_position
            else
              left += 1
            end
          end
        else
          while (left < middle2) && (middle2 < end2)
            if compare(left, middle2) >= 0
              next_position = right_binary_search(middle2 + 1, end2, read(left))
              rotate(left, middle2, next_position)
              left += (next_position - middle2)
              middle2 = next_position
            else
              left += 1
            end
          end
        end
        if left < middle2
          if next_value == "left"
            left_blocks += 1
          else
            right_blocks += 1
          end
        else
          if fragment == "left"
            left_blocks += 1
          else
            right_blocks += 1
          end
          fragment = next_value
        end
      end
      group += block_length
    end
    if left_blocks < left_count
      in_place_merge_backward(start, last_full, finish)
    end
    sort_keys_without_buffer((tags + block_count) - 1, middle_key)
  end

  def smart_merge(start, middle, finish, buffer)
    if check_bounds(start, middle, finish)
      trimmed = right_binary_search(start, middle - 1, read(middle))
      merge_with_buffer(trimmed, middle, finish, buffer)
    end
  end

  def smart_merge_backward(start, middle, finish, buffer)
    if check_bounds(start, middle, finish)
      trimmed = left_binary_search(middle + 1, finish, read(middle - 1))
      merge_with_buffer_backward(start, middle, trimmed, buffer)
    end
  end

  def smart_block_merge(start, middle, finish, tags, buffer, block_length)
    if check_bounds(start, middle, finish)
      trimmed_start = right_binary_search(start, middle - 1, read(middle))
      trimmed_end = left_binary_search(middle + 1, finish, read(middle - 1))
      if check_reverse_bounds(trimmed_start, middle, trimmed_end)
        if ((middle - trimmed_start) <= block_length) || ((trimmed_end - middle) <= block_length)
          if (trimmed_end - middle) < (middle - trimmed_start)
            merge_with_buffer_backward(trimmed_start, middle, trimmed_end, buffer)
          else
            merge_with_buffer(trimmed_start, middle, trimmed_end, buffer)
          end
        else
          trimmed_start -= ((trimmed_start - start) % block_length)
          block_merge(trimmed_start, middle, trimmed_end, tags, buffer, block_length)
        end
      end
    end
  end

  def smart_block_merge_without_buffer(start, middle, finish, tags, block_length)
    if check_bounds(start, middle, finish)
      trimmed_start = right_binary_search(start, middle - 1, read(middle))
      if (middle - trimmed_start) <= block_length
        in_place_merge(trimmed_start, middle, finish)
      else
        block_merge_without_buffer(trimmed_start, middle, finish, tags, block_length)
      end
    end
  end

  def smart_in_place_merge(start, middle, finish)
    if check_sorted(middle)
      in_place_merge_backward(start, middle, finish)
    end
  end

  def redistribute_buffer(start_in, middle_in, finish)
    start = start_in
    middle = middle_in
    right = left_binary_search(middle, finish, read(start))
    rotate(start, middle, right)
    distance = (right - middle)
    start += distance
    middle += distance
    left_middle = (start + ((middle - start) / 2))
    right = left_binary_search(middle, finish, read(left_middle))
    rotate(left_middle, middle, right)
    distance = (right - middle)
    left_middle += distance
    middle += distance
    merge_without_buffer(start, left_middle - distance, left_middle)
    merge_without_buffer(left_middle, middle, finish)
  end

  def redistribute_buffer_backward(start, middle_in, end_in)
    middle = middle_in
    finish = end_in
    right = right_binary_search(start, middle, read(finish - 1))
    rotate(right, middle, finish)
    distance = (middle - right)
    finish -= distance
    middle -= distance
    right_middle = (middle + ((finish - middle) / 2))
    right = right_binary_search(start, middle, read(right_middle - 1))
    rotate(right, middle, right_middle)
    distance = (middle - right)
    right_middle -= distance
    middle -= distance
    merge_without_buffer(right_middle, right_middle + distance, finish)
    merge_without_buffer(start, middle, right_middle)
  end

  def in_place_merge_sort(start, finish)
    build_runs(start, finish)
    run = @min_run
    while run < (finish - start)
      index = start
      while (index + (2 * run)) <= finish
        smart_in_place_merge(index, index + run, index + (2 * run))
        index += (2 * run)
      end
      if (index + run) < finish
        smart_in_place_merge(index, index + run, finish)
      end
      run *= 2
    end
  end

  def adaptive_sort_without_buffer(start_in, end_in, keys, ideal, backward_buffer)
    start = start_in
    finish = end_in
    length = (finish - start)
    block_length = [keys, @min_run].min
    while (2 * block_length) <= keys
      block_length *= 2
    end
    tag_length = (keys - block_length)
    run_length = @min_run
    tags = nil
    buffer = nil
    data_start = nil
    data_end = nil
    if backward_buffer
      buffer = (finish - block_length)
      data_start = start
      data_end = (buffer - tag_length)
      tags = data_end
    else
      buffer = (start + tag_length)
      data_start = (buffer + block_length)
      data_end = finish
      tags = start
    end
    build_runs(data_start, data_end)
    while (run_length <= block_length) && (run_length < length)
      index = data_start
      while (index + (2 * run_length)) <= data_end
        smart_merge(index, index + run_length, index + (2 * run_length), buffer)
        index += (2 * run_length)
      end
      if (index + run_length) < data_end
        smart_merge_backward(index, index + run_length, data_end, buffer)
      end
      run_length *= 2
    end
    if ((block_length / 2) >= @min_run) && ((block_length / 2) >= ((keys + 1) / 2))
      binary_insertion(buffer, buffer + block_length)
      block_length /= 2
      tag_length = (keys - block_length)
      buffer += block_length
    end
    while (tag_length >= (((2 * run_length) / block_length) - 1)) && (run_length < length)
      index = data_start
      while (index + (2 * run_length)) <= data_end
        smart_block_merge(index, index + run_length, index + (2 * run_length), tags, buffer, block_length)
        index += (2 * run_length)
      end
      if (index + run_length) < data_end
        if (data_end - (index + run_length)) > block_length
          smart_block_merge(index, index + run_length, data_end, tags, buffer, block_length)
        else
          smart_merge_backward(index, index + run_length, data_end, buffer)
        end
      end
      run_length *= 2
    end
    binary_insertion(buffer, buffer + block_length)
    tag_length = (keys - (keys % 2))
    while run_length < length
      block_length = ((2 * run_length + tag_length - 1) / tag_length)
      index = data_start
      while (index + (2 * run_length)) <= data_end
        smart_block_merge_without_buffer(index, index + run_length, index + (2 * run_length), tags, block_length)
        index += (2 * run_length)
      end
      if (index + run_length) < data_end
        if (data_end - (index + run_length)) > block_length
          smart_block_merge_without_buffer(index, index + run_length, data_end, tags, block_length)
        else
          smart_in_place_merge(index, index + run_length, data_end)
        end
      end
      run_length *= 2
    end
    if backward_buffer
      start = right_binary_search(start, data_end, read(data_end))
      if keys >= (ideal / 2)
        redistribute_buffer_backward(start, data_end, finish)
      else
        merge_without_buffer(start, data_end, finish)
      end
    else
      finish = left_binary_search(data_start, finish, read(data_start - 1))
      if keys >= (ideal / 2)
        redistribute_buffer(start, data_start, finish)
      else
        merge_without_buffer(start, data_start, finish)
      end
    end
  end

  def sort(start_in, end_in)
    start = start_in
    finish = end_in
    length = (finish - start)
    if length < 31
      binary_insertion(start, finish)
      return
    end
    if length < 63
      @min_run = ((length + 1) / 2)
      build_runs(start, finish)
      middle = (start + @min_run)
      if check_bounds(start, middle, finish)
        redistribute_buffer_backward(start, middle, finish)
      end
      return
    end
    @min_run = length
    while @min_run >= 32
      @min_run = ((@min_run + 1) / 2)
    end
    block_length = @min_run
    while (block_length * block_length) < length
      block_length *= 2
    end
    tag_length = ((length / block_length) - 2)
    ideal = (tag_length + block_length)
    right_run = build_unique_run_backward(finish, ideal)
    left_run = 0
    backward_buffer = nil
    if right_run == ideal
      backward_buffer = true
    else
      left_run = build_unique_run(start, ideal)
      backward_buffer = if left_run == ideal
        false
      else
        ((right_run < 16) && (left_run < 16)) || (right_run >= left_run)
      end
    end
    keys = (backward_buffer ? find_keys_backward(start, finish, right_run, ideal) : find_keys(start, finish, left_run, ideal))
    if keys < ideal
      if keys == 1
        return
      end
      if keys <= 4
        in_place_merge_sort(start, finish)
      else
        adaptive_sort_without_buffer(start, finish, keys, ideal, backward_buffer)
      end
      return
    end
    buffer = nil
    data_start = nil
    data_end = nil
    tags = nil
    if backward_buffer
      buffer = (finish - block_length)
      data_start = start
      data_end = (buffer - tag_length)
      tags = data_end
    else
      buffer = (start + tag_length)
      data_start = (buffer + block_length)
      data_end = finish
      tags = start
    end
    build_runs(data_start, data_end)
    run_length = @min_run
    while (run_length <= block_length) && (run_length < length)
      index = data_start
      while (index + (2 * run_length)) <= data_end
        smart_merge(index, index + run_length, index + (2 * run_length), buffer)
        index += (2 * run_length)
      end
      if (index + run_length) < data_end
        smart_merge_backward(index, index + run_length, data_end, buffer)
      end
      run_length *= 2
    end
    while run_length < length
      index = data_start
      while (index + (2 * run_length)) <= data_end
        smart_block_merge(index, index + run_length, index + (2 * run_length), tags, buffer, block_length)
        index += (2 * run_length)
      end
      if (index + run_length) < data_end
        if (data_end - (index + run_length)) > block_length
          smart_block_merge(index, index + run_length, data_end, tags, buffer, block_length)
        else
          smart_merge_backward(index, index + run_length, data_end, buffer)
        end
      end
      run_length *= 2
    end
    binary_insertion(buffer, buffer + block_length)
    if backward_buffer
      start = right_binary_search(start, data_end, read(data_end))
      redistribute_buffer_backward(start, data_end, finish)
    else
      finish = left_binary_search(data_start, finish, read(data_start - 1))
      redistribute_buffer(start, data_start, finish)
    end
  end
end

def sort(values)
  sorter = AdaptiveGrailExample.new(values)
  sorter.sort(0, values.length)
end
array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
