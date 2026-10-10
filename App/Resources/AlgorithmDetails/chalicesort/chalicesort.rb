# MIT License
# Copyright (c) 2021 aphitorite
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

# Five-way stable merge with a one-fifth external buffer.
class FifthMerge
  def initialize(values)
    @a = values
    @n = values.length
    @chunk = @n / 5
    @buffer_length = @n - 4 * @chunk
    @buffer = Array.new(@buffer_length, 0)
  end

  def binary_insertion(first, last)
    (first + 1...last).each do |i|
      value = @a[i]
      low = first
      high = i
      while low < high
        middle = low + (high - low) / 2
        if @a[middle] > value
          high = middle
        else
          low = middle + 1
        end
      end
      j = i
      while j > low
        @a[j] = @a[j - 1]
        j -= 1
      end
      @a[low] = value
    end
  end

  def source(index, offset, from_buffer)
    from_buffer ? @buffer[index - offset] : @a[index]
  end

  def merge(offset, first, middle, last, from_buffer)
    left = first
    right = middle
    destination = from_buffer ? first : first - offset
    while left < middle && right < last
      if source(left, offset, from_buffer) <= source(right, offset, from_buffer)
        value = source(left, offset, from_buffer)
        left += 1
      else
        value = source(right, offset, from_buffer)
        right += 1
      end
      if from_buffer
        @a[destination] = value
      else
        @buffer[destination] = value
      end
      destination += 1
    end
    while left < middle
      value = source(left, offset, from_buffer)
      if from_buffer
        @a[destination] = value
      else
        @buffer[destination] = value
      end
      left += 1
      destination += 1
    end
    while right < last
      value = source(right, offset, from_buffer)
      if from_buffer
        @a[destination] = value
      else
        @buffer[destination] = value
      end
      right += 1
      destination += 1
    end
  end

  def ping_pong(first, last)
    i = first
    while i + 8 < last
      binary_insertion(i, i + 8)
      i += 8
    end
    binary_insertion(i, last) if last - i > 1
    length = last - first
    from_buffer = false
    gap = 8
    while gap < length
      full = gap * 2
      i = first
      while i + full < last
        merge(first, i, i + gap, i + full, from_buffer)
        i += full
      end
      if i + gap < last
        merge(first, i, i + gap, last, from_buffer)
      else
        (i...last).each do |j|
          if from_buffer
            @a[j] = @buffer[j - first]
          else
            @buffer[j - first] = @a[j]
          end
        end
      end
      from_buffer = !from_buffer
      gap *= 2
    end
    length.times { |j| @a[first + j] = @buffer[j] } if from_buffer
  end

  def merge_forward(destination, first, middle, last)
    left = first
    right = middle
    while left < middle && right < last
      if @a[left] <= @a[right]
        @a[destination] = @a[left]
        left += 1
      else
        @a[destination] = @a[right]
        right += 1
      end
      destination += 1
    end
    while left < middle
      @a[destination] = @a[left]
      destination += 1
      left += 1
    end
    while right < last
      @a[destination] = @a[right]
      destination += 1
      right += 1
    end
  end

  def merge_backward(destination, middle, last)
    left = middle - 1
    right = last - 1
    while destination > right && right >= middle && left >= 0
      if @a[left] > @a[right]
        @a[destination] = @a[left]
        left -= 1
      else
        @a[destination] = @a[right]
        right -= 1
      end
      destination -= 1
    end
    if left < 0
      while right >= middle
        @a[destination] = @a[right]
        destination -= 1
        right -= 1
      end
    elsif right == left
      while right >= 0
        @a[destination] = @a[right]
        destination -= 1
        right -= 1
      end
    elsif right < middle
      while left >= 0
        @a[destination] = @a[left]
        destination -= 1
        left -= 1
      end
    end
    [left + 1, right + 1]
  end

  def merge_main_prefix(destination, left_end, middle, last)
    left = 0
    right = middle
    while left < left_end && right < last
      if @a[left] <= @a[right]
        @a[destination] = @a[left]
        left += 1
      else
        @a[destination] = @a[right]
        right += 1
      end
      destination += 1
    end
    while left < left_end
      @a[destination] = @a[left]
      destination += 1
      left += 1
    end
  end

  def merge_external(destination, middle, last)
    left = 0
    right = middle
    while left < @buffer_length && right < last
      if @buffer[left] <= @a[right]
        @a[destination] = @buffer[left]
        left += 1
      else
        @a[destination] = @a[right]
        right += 1
      end
      destination += 1
    end
    while left < @buffer_length
      @a[destination] = @buffer[left]
      destination += 1
      left += 1
    end
  end

  def sort
    return if @n <= 1
    ping_pong(0, @buffer_length)
    first = @buffer_length
    4.times do
      ping_pong(first, first + @chunk)
      first += @chunk
    end
    @buffer_length.times { |i| @buffer[i] = @a[i] }
    two_fifths = 2 * @chunk
    first = @buffer_length
    2.times do
      merge_forward(first - @buffer_length, first, first + @chunk, first + two_fifths)
      first += two_fifths
    end
    left, right = merge_backward(@n - 1, two_fifths, 2 * two_fifths)
    merge_main_prefix(@buffer_length, left, two_fifths, @n) if right > 0
    merge_external(0, @buffer_length, @n)
  end
end

class KeyGroup
  attr_accessor :start, :end
  def initialize(start, finish)
    @start = start
    @end = finish
  end
end

def relation(left, right, operator)
  if operator == "<"
    return left < right
  end
  if operator == "<="
    return left <= right
  end
  if operator == ">"
    return left > right
  end
  if operator == ">="
    return left >= right
  end
  left == right
end

class ChaliceSortExample
  def initialize(input)
    @values = input
    @temp = []
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

  def compare(first, second, predicate)
    relation(@values[first], @values[second], predicate)
  end

  def compare_values(first, second, predicate)
    relation(first, second, predicate)
  end

  def save(index, value)
    @temp[index] = value
  end

  def load(index)
    @temp[index]
  end

  def shift_forward_external(destination, source, finish)
    output = destination
    (source...finish).each do |input|
      write(output, read(input))
      output += 1
    end
  end

  def shift_backward_external(start, source_end, destination_end)
    input = source_end
    output = destination_end
    while input > start
      input -= 1
      output -= 1
      write(output, read(input))
    end
  end

  def right_binary_search(start, finish, value)
    lower = start
    upper = finish
    while lower < upper
      middle = (lower + ((upper - lower) / 2))
      if read(middle) <= value
        lower = (middle + 1)
      else
        upper = middle
      end
    end
    lower
  end

  def multi_swap(first, second, length)
    if !(length > 0)
      return
    end
    (0...length).each do |offset|
      swap(first + offset, second + offset)
    end
  end

  def binary_insertion(start, finish)
    if !((finish - start) > 1)
      return
    end
    ((start + 1)...finish).each do |index|
      value = read(index)
      low = start
      high = index
      while low < high
        middle = (low + ((high - low) / 2))
        if read(middle) > value
          high = middle
        else
          low = (middle + 1)
        end
      end
      insert_to(index, low)
    end
  end

  def ceil_cbrt(value)
    low = 0
    high = 11
    while low < high
      middle = ((low + high) / 2)
      if (1 << (3 * middle)) >= value
        high = middle
      else
        low = (middle + 1)
      end
    end
    1 << low
  end

  def calc_keys(block_length, count)
    low = 1
    high = (count / 4)
    while low < high
      middle = ((low + high) / 2)
      if ((((count - (4 * middle)) - 1) / block_length) - 2) < middle
        high = middle
      else
        low = (middle + 1)
      end
    end
    low
  end

  def left_bin_search(start_in, end_in, value)
    start = start_in
    finish = end_in
    while start < finish
      middle = (start + ((finish - start) / 2))
      if @values[middle] >= value
        finish = middle
      else
        start = (middle + 1)
      end
    end
    start
  end

  def rotate(start, middle, finish)
    if !((start < middle) && (middle < finish))
      return
    end
    position = start
    left_length = (middle - start)
    right_length = (finish - middle)
    while (left_length != 0) && (right_length != 0)
      if left_length <= right_length
        (0...left_length).each do |offset|
          swap(position + offset, (position + left_length) + offset)
        end
        position += left_length
        right_length -= left_length
      else
        (0...right_length).each do |offset|
          swap(((position + left_length) - right_length) + offset, (position + left_length) + offset)
        end
        left_length -= right_length
      end
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

  def shift_forward(destination, source, finish)
    if !(source < finish)
      return
    end
    (0...(finish - source)).each do |offset|
      swap(destination + offset, source + offset)
    end
  end

  def shift_backward(start, source_end, destination_end)
    source = source_end
    destination = destination_end
    while source > start
      source -= 1
      destination -= 1
      swap(destination, source)
    end
  end

  def merge_forward_external(start_in, middle, finish)
    left_length = (middle - start_in)
    if !(left_length > 0)
      return
    end
    (0...left_length).each do |offset|
      save(offset, read(start_in + offset))
    end
    start = start_in
    left = 0
    right = middle
    while (left < left_length) && (right < finish)
      if compare_values(load(left), read(right), "<=")
        write(start, load(left))
        left += 1
      else
        write(start, read(right))
        right += 1
      end
      start += 1
    end
    while left < left_length
      write(start, load(left))
      left += 1
      start += 1
    end
  end

  def merge_backward_external(start, middle, end_in)
    right_length = (end_in - middle)
    if !(right_length > 0)
      return
    end
    (0...right_length).each do |offset|
      save(offset, read(middle + offset))
    end
    finish = end_in
    right = (right_length - 1)
    left = (middle - 1)
    while (right >= 0) && (left >= start)
      finish -= 1
      if compare_values(load(right), read(left), ">=")
        write(finish, load(right))
        right -= 1
      else
        write(finish, read(left))
        left -= 1
      end
    end
    while right >= 0
      finish -= 1
      write(finish, load(right))
      right -= 1
    end
  end

  def merge_with_buffer_forward(start_in, middle, finish, destination_in, external)
    start = start_in
    right = middle
    destination = destination_in
    while (start < middle) && (right < finish)
      choose_left = compare(start, right, "<=")
      source = (choose_left ? start : right)
      if external
        write(destination, read(source))
      else
        swap(destination, source)
      end
      if choose_left
        start += 1
      else
        right += 1
      end
      destination += 1
    end
    if start > destination
      if external
        shift_forward_external(destination, start, middle)
      else
        shift_forward(destination, start, middle)
      end
    end
    if external
      shift_forward_external(destination, right, finish)
    else
      shift_forward(destination, right, finish)
    end
  end

  def merge_with_buffer_backward(start, middle, end_in, destination_end_in, external)
    left = (middle - 1)
    right = (end_in - 1)
    destination_end = destination_end_in
    while (right >= middle) && (left >= start)
      destination_end -= 1
      if compare(right, left, ">=")
        if external
          write(destination_end, read(right))
        else
          swap(destination_end, right)
        end
        right -= 1
      else
        if external
          write(destination_end, read(left))
        else
          swap(destination_end, left)
        end
        left -= 1
      end
    end
    if destination_end > right
      if external
        shift_backward_external(middle, right + 1, destination_end)
      else
        shift_backward(middle, right + 1, destination_end)
      end
    end
    if external
      shift_backward_external(start, left + 1, destination_end)
    else
      shift_backward(start, left + 1, destination_end)
    end
  end

  def in_place_merge(start_in, middle_in, finish)
    start = start_in
    middle = middle_in
    while (start < middle) && (middle < finish)
      start = right_binary_search(start, middle, read(middle))
      if start == middle
        return
      end
      insertion = left_bin_search(middle, finish, read(start))
      rotate(start, middle, insertion)
      moved = (insertion - middle)
      middle = insertion
      start += (moved + 1)
    end
  end

  def laziest_sort_external(start, finish)
    cursor = start
    while cursor < finish
      next_value = [finish, (cursor + @temp.length)].min
      binary_insertion(cursor, next_value)
      if cursor > start
        merge_backward_external(start, cursor, next_value)
      end
      cursor = next_value
    end
  end

  def find_keys_small(start, finish, other_start, other_end, full, needed)
    first = start
    last = nil
    if full
      last = 0
      while first < finish
        location = left_bin_search(other_start, other_end, read(first))
        if (location == other_end) || !compare(first, location, "==")
          last = (first + 1)
          break
        end
        first += 1
      end
      if last != 0
        index = last
        while (index < finish) && ((last - first) < needed)
          other_location = left_bin_search(other_start, other_end, read(index))
          if (other_location == other_end) || !compare(index, other_location, "==")
            location = left_bin_search(first, last, read(index))
            if (location == last) || !compare(index, location, "==")
              rotate(first, last, index)
              displaced = (index - last)
              first += displaced
              location += displaced
              last = (index + 1)
              insert_to(index, location)
            end
          end
          index += 1
        end
      else
        last = first
      end
    else
      last = (first + 1)
      index = last
      while (index < finish) && ((last - first) < needed)
        location = left_bin_search(first, last, read(index))
        if (location == last) || !compare(index, location, "==")
          rotate(first, last, index)
          displaced = (index - last)
          first += displaced
          location += displaced
          last = (index + 1)
          insert_to(index, location)
        end
        index += 1
      end
    end
    KeyGroup.new(first, last)
  end

  def find_keys(start, finish, desired, stride)
    group = find_keys_small(start, finish, 0, 0, false, [desired, stride].min)
    first = group.start
    last = group.end
    if (stride < desired) && ((last - first) == stride)
      remaining = (desired - stride)
      loop do
        group = find_keys_small(last, finish, first, last, true, [stride, remaining].min)
        found = (group.end - group.start)
        if found == 0
          break
        end
        if (found < stride) || (remaining == stride)
          rotate(last, group.start, group.end)
          second_start = last
          last += found
          merge_backward_external(first, second_start, last)
          break
        end
        rotate(first, last, group.start)
        first += (group.start - last)
        last = group.end
        merge_backward_external(first, group.start, last)
        remaining -= stride
      end
    end
    rotate(start, first, last)
    last - first
  end

  def find_bits_small(start, finish, reference_in, backward, needed)
    first = start
    reference = reference_in
    while (first < finish) && !compare(first, reference, (backward ? "<" : ">"))
      first += 1
    end
    reference += 1
    last = nil
    if first < finish
      last = (first + 1)
      index = last
      while (index < finish) && ((last - first) < needed)
        if compare(index, reference, (backward ? "<" : ">"))
          rotate(first, last, index)
          first += (index - last)
          last = (index + 1)
          reference += 1
        end
        index += 1
      end
    else
      last = first
    end
    KeyGroup.new(first, last)
  end

  def find_bits(start, finish, needed, stride)
    laziest_sort_external(start, start + needed)
    reference_start = start
    reference = (start + needed)
    count = 0
    first_count = 0
    (0...2).each do |phase|
      if count >= needed
        next
      end
      first = reference
      last = first
      loop do
        group = find_bits_small(last, finish, reference_start + count, phase == 1, [stride, (needed - count)].min)
        found = (group.end - group.start)
        if found == 0
          break
        end
        count += found
        if (found < stride) || (count == needed)
          rotate(last, group.start, group.end)
          last += found
          break
        end
        rotate(first, last, group.start)
        first += (group.start - last)
        last = group.end
      end
      rotate(reference, first, last)
      reference += (last - first)
      if phase == 0
        first_count = count
      end
    end
    if count < needed
      return -1
    end
    multi_swap(start + first_count, (start + needed) + first_count, needed - first_count)
    first_count
  end

  def bit_reversal(start, finish)
    length = (finish - start)
    offset = 0
    half = (length / 2)
    three_quarters = (half + (half / 2))
    if length < 3
      return
    end
    (1...(length - 1)).each do |index|
      jump = half
      current = index
      decrement = three_quarters
      while (current & 1) == 0
        jump -= decrement
        current >>= 1
        decrement >>= 1
      end
      offset += jump
      if offset > index
        swap(start + index, start + offset)
      end
    end
  end

  def unshuffle(start, finish)
    remaining = ((finish - start) / 2)
    consumed = 0
    width = 2
    while remaining > 0
      if (remaining & 1) == 1
        position = (start + consumed)
        bit_reversal(position, position + width)
        bit_reversal(position, position + (width / 2))
        bit_reversal(position + (width / 2), position + width)
        rotate(start + (consumed / 2), position, position + (width / 2))
        consumed += width
      end
      remaining >>= 1
      width *= 2
    end
  end

  def redistribute_buffer(start_in, middle_in, finish)
    start = start_in
    middle = middle_in
    size = @temp.length
    while ((middle - start) > size) && (middle < finish)
      insertion = left_bin_search(middle, finish, read(start + size))
      rotate(start + size, middle, insertion)
      moved = (insertion - middle)
      middle = insertion
      merge_forward_external(start, start + size, middle)
      start += (moved + size)
    end
    if middle < finish
      merge_forward_external(start, middle, finish)
    end
  end

  def copy_main(source, destination, length)
    if !((length > 0) && (source != destination))
      return
    end
    if destination > source
      (length - 1).downto(0) do |offset|
        write(destination + offset, read(source + offset))
      end
    else
      (0...length).each do |offset|
        write(destination + offset, read(source + offset))
      end
    end
  end

  def dual_merge_backward(start_in, middle_in, end_in, destination_end_in, external)
    start = start_in
    middle = middle_in
    finish = (end_in - 1)
    destination_end = destination_end_in
    left = (middle - 1)
    while (destination_end > (finish + 1)) && (finish >= middle)
      destination_end -= 1
      if compare(finish, left, ">=")
        if external
          write(destination_end, read(finish))
        else
          swap(destination_end, finish)
        end
        finish -= 1
      else
        if external
          write(destination_end, read(left))
        else
          swap(destination_end, left)
        end
        left -= 1
      end
    end
    if finish < middle
      if external
        shift_backward_external(start, left + 1, destination_end)
      else
        shift_backward(start, left + 1, destination_end)
      end
    else
      left += 1
      finish += 1
      destination_end = (middle - (left - start))
      right = middle
      while (start < left) && (right < finish)
        choose_left = compare(start, right, "<=")
        source = (choose_left ? start : right)
        if external
          write(destination_end, read(source))
        else
          swap(destination_end, source)
        end
        if choose_left
          start += 1
        else
          right += 1
        end
        destination_end += 1
      end
      while start < left
        if external
          write(destination_end, read(start))
        else
          swap(destination_end, start)
        end
        start += 1
        destination_end += 1
      end
    end
  end

  def smart_merge(destination_in, start_in, middle, reversed)
    destination = destination_in
    start = start_in
    right = middle
    while start < middle
      choose_left = (reversed ? compare(start, right, "<") : compare(start, right, "<="))
      if choose_left
        write(destination, read(start))
        start += 1
      else
        write(destination, read(right))
        right += 1
      end
      destination += 1
    end
    right
  end

  def smart_tail_merge(destination_in, start_in, middle, finish)
    destination = destination_in
    start = start_in
    right = middle
    block_length = @temp.length
    while (start < middle) && (right < finish)
      if compare(start, right, "<=")
        write(destination, read(start))
        start += 1
      else
        write(destination, read(right))
        right += 1
      end
      destination += 1
    end
    if start < middle
      if start > destination
        shift_forward_external(destination, start, middle)
      end
      (0...block_length).each do |offset|
        write((finish - block_length) + offset, load(offset))
      end
    else
      buffer_index = 0
      while (buffer_index < block_length) && (right < finish)
        if compare_values(load(buffer_index), read(right), "<=")
          write(destination, load(buffer_index))
          buffer_index += 1
        else
          write(destination, read(right))
          right += 1
        end
        destination += 1
      end
      while buffer_index < block_length
        write(destination, load(buffer_index))
        buffer_index += 1
        destination += 1
      end
    end
  end

  def block_cycle(start, tag_start, sorted_tags, tag_count, block_length)
    if !(tag_count > 1)
      return
    end
    (0...(tag_count - 1)).each do |index|
      if compare(tag_start + index, sorted_tags + index, ">") || ((index > 0) && compare(tag_start + index, (sorted_tags + index) - 1, "<"))
        copy_main(start + (index * block_length), start - block_length, block_length)
        position = index
        next_value = (left_bin_search(sorted_tags, sorted_tags + tag_count, read(tag_start + index)) - sorted_tags)
        loop do
          copy_main(start + (next_value * block_length), start + (position * block_length), block_length)
          swap(tag_start + index, tag_start + next_value)
          position = next_value
          next_value = (left_bin_search(sorted_tags, sorted_tags + tag_count, read(tag_start + index)) - sorted_tags)
          if !(next_value != index)
            break
          end
        end
        copy_main(start - block_length, start + (position * block_length), block_length)
      end
    end
  end

  def block_cycle_easy(start, tag_start, sorted_tags, tag_count, block_length)
    if !(tag_count > 1)
      return
    end
    (0...(tag_count - 1)).each do |index|
      if compare(tag_start + index, sorted_tags + index, ">") || ((index > 0) && compare(tag_start + index, (sorted_tags + index) - 1, "<"))
        next_value = (left_bin_search(sorted_tags, sorted_tags + tag_count, read(tag_start + index)) - sorted_tags)
        loop do
          multi_swap(start + (index * block_length), start + (next_value * block_length), block_length)
          swap(tag_start + index, tag_start + next_value)
          next_value = (left_bin_search(sorted_tags, sorted_tags + tag_count, read(tag_start + index)) - sorted_tags)
          if !(next_value != index)
            break
          end
        end
      end
    end
  end

  def in_place_merge_backward(start, middle_in, end_in, reversed)
    middle = middle_in
    finish = end_in
    final_end = (reversed ? right_binary_search(middle, finish, read(middle - 1)) : left_bin_search(middle, finish, read(middle - 1)))
    finish = final_end
    while (finish > middle) && (middle > start)
      insertion = (reversed ? left_bin_search(start, middle, read(finish - 1)) : right_binary_search(start, middle, read(finish - 1)))
      rotate(insertion, middle, finish)
      moved = (middle - insertion)
      middle = insertion
      finish -= (moved + 1)
      if middle == start
        break
      end
      finish = (reversed ? right_binary_search(middle, finish, read(middle - 1)) : left_bin_search(middle, finish, read(middle - 1)))
    end
    final_end
  end

  def block_merge(start, middle, finish, left_tag_count, tag_count, tag_start_in, sorted_tags_in, first_bits_in, second_bits_in, block_length)
    if (finish - middle) <= block_length
      merge_backward_external(start, middle, finish)
      return
    end
    insert_to((tag_start_in + left_tag_count) - 1, tag_start_in)
    left_block = ((start + block_length) - 1)
    right_block = ((middle + block_length) - 1)
    left_tag = tag_start_in
    right_tag = (tag_start_in + left_tag_count)
    output_tag = sorted_tags_in
    first_bits = first_bits_in
    second_bits = second_bits_in
    while (left_tag < (tag_start_in + left_tag_count)) && (right_tag < (tag_start_in + tag_count))
      if compare(left_block, right_block, "<=")
        swap(output_tag, left_tag)
        output_tag += 1
        left_tag += 1
        left_block += block_length
      else
        swap(output_tag, right_tag)
        output_tag += 1
        right_tag += 1
        swap(first_bits, second_bits)
        right_block += block_length
      end
      first_bits += 1
      second_bits += 1
    end
    while left_tag < (tag_start_in + left_tag_count)
      swap(output_tag, left_tag)
      output_tag += 1
      left_tag += 1
      first_bits += 1
      second_bits += 1
    end
    while right_tag < (tag_start_in + tag_count)
      swap(output_tag, right_tag)
      output_tag += 1
      right_tag += 1
      swap(first_bits, second_bits)
      first_bits += 1
      second_bits += 1
    end
    tag_start = sorted_tags_in
    sorted_tags = tag_start_in
    heap_sort(sorted_tags, sorted_tags + tag_count)
    (0...block_length).each do |offset|
      save(offset, read((middle - block_length) + offset))
    end
    copy_main(start, middle - block_length, block_length)
    block_cycle(start + block_length, tag_start, sorted_tags, tag_count, block_length)
    multi_swap(tag_start, sorted_tags, tag_count)
    first_bits -= tag_count
    second_bits -= tag_count
    fragment = (start + block_length)
    next_block = fragment
    bits_end = (second_bits + tag_count)
    reversed = compare(first_bits, second_bits, ">")
    loop do
      loop do
        if reversed
          swap(first_bits, second_bits)
        end
        first_bits += 1
        second_bits += 1
        next_block += block_length
        if !((second_bits < bits_end) && compare(first_bits, second_bits, (reversed ? ">" : "<")))
          break
        end
      end
      if second_bits == bits_end
        smart_tail_merge(fragment - block_length, fragment, (reversed ? fragment : next_block), finish)
        return
      end
      fragment = smart_merge(fragment - block_length, fragment, next_block, reversed)
      reversed = !reversed
    end
  end

  def block_merge_easy(start, middle, finish, left_tail, right_tail, left_tag_count, tag_count, tag_start_in, sorted_tags_in, first_bits_in, second_bits_in, block_length)
    if (finish - middle) <= block_length
      _ = in_place_merge_backward(start, middle, finish, false)
      return
    end
    data_start = (start + left_tail)
    data_end = (finish - right_tail)
    left_block = ((data_start + block_length) - 1)
    right_block = ((middle + block_length) - 1)
    left_tag = sorted_tags_in
    right_tag = (sorted_tags_in + left_tag_count)
    output_tag = tag_start_in
    first_bits = first_bits_in
    second_bits = second_bits_in
    while (left_tag < (sorted_tags_in + left_tag_count)) && (right_tag < (sorted_tags_in + tag_count))
      if compare(left_block, right_block, "<=")
        swap(left_tag, output_tag)
        left_tag += 1
        output_tag += 1
        left_block += block_length
      else
        swap(right_tag, output_tag)
        right_tag += 1
        output_tag += 1
        swap(first_bits, second_bits)
        right_block += block_length
      end
      first_bits += 1
      second_bits += 1
    end
    while left_tag < (sorted_tags_in + left_tag_count)
      swap(left_tag, output_tag)
      left_tag += 1
      output_tag += 1
      first_bits += 1
      second_bits += 1
    end
    while right_tag < (sorted_tags_in + tag_count)
      swap(right_tag, output_tag)
      right_tag += 1
      output_tag += 1
      swap(first_bits, second_bits)
      first_bits += 1
      second_bits += 1
    end
    tag_start = sorted_tags_in
    sorted_tags = tag_start_in
    heap_sort(sorted_tags, sorted_tags + tag_count)
    block_cycle_easy(data_start, tag_start, sorted_tags, tag_count, block_length)
    multi_swap(tag_start, sorted_tags, tag_count)
    first_bits -= tag_count
    second_bits -= tag_count
    fragment = data_start
    next_block = fragment
    bits_end = (second_bits + tag_count)
    reversed = compare(first_bits, second_bits, ">")
    loop do
      loop do
        if reversed
          swap(first_bits, second_bits)
        end
        first_bits += 1
        second_bits += 1
        next_block += block_length
        if !((second_bits < bits_end) && compare(first_bits, second_bits, (reversed ? ">" : "<")))
          break
        end
      end
      if second_bits == bits_end
        if !reversed
          _ = in_place_merge_backward(data_start, data_end, finish, false)
        end
        in_place_merge(start, data_start, finish)
        return
      end
      fragment = in_place_merge_backward(fragment, next_block, next_block + block_length, reversed)
      reversed = !reversed
    end
  end

  def sift(start, root_in, limit)
    root = root_in
    while ((root * 2) + 1) < limit
      child = ((root * 2) + 1)
      if ((child + 1) < limit) && compare(start + child, (start + child) + 1, "<")
        child += 1
      end
      if !compare(start + root, start + child, "<")
        return
      end
      swap(start + root, start + child)
      root = child
    end
  end

  def heap_sort(start, finish)
    count = (finish - start)
    if !(count > 1)
      return
    end
    ((count - 2) / 2).downto(0) do |root|
      sift(start, root, count)
    end
    (count - 1).downto(1) do |limit|
      swap(start, start + limit)
      sift(start, 0, limit)
    end
  end

  def sort
    count = @values.length
    start = 0
    finish = count
    cube_root = (2 * ceil_cbrt(count / 4))
    block_length = (2 * cube_root)
    key_length = calc_keys(block_length, count)
    @temp = ([0] * block_length)
    keys = find_keys(start, finish, 2 * key_length, cube_root)
    if keys < 8
      run_length = 1
      while run_length < count
        middle = (start + run_length)
        while middle < finish
          _ = in_place_merge_backward(middle - run_length, middle, [(middle + run_length), finish].min, false)
          middle += (2 * run_length)
        end
        run_length *= 2
      end
      return
    end
    if keys < (2 * key_length)
      keys -= (keys % 4)
      key_length = (keys / 2)
    end
    key_end = (start + keys)
    bit_end = (key_end + keys)
    bit_separation = find_bits(key_end, finish, key_length, cube_root)
    if bit_separation == -1
      laziest_sort_external(start, bit_end)
      in_place_merge(start, bit_end, finish)
      return
    end
    data_start = (bit_end + block_length)
    data_length = (finish - data_start)
    binary_insertion(bit_end, data_start)
    (0...block_length).each do |offset|
      save(offset, read(bit_end + offset))
    end
    run_length = 1
    while run_length < cube_root
      vacant = [2, run_length].max
      index = data_start
      while (index + (2 * run_length)) < finish
        merge_with_buffer_forward(index, index + run_length, index + (2 * run_length), index - vacant, true)
        index += (2 * run_length)
      end
      if (index + run_length) < finish
        merge_with_buffer_forward(index, index + run_length, finish, index - vacant, true)
      else
        shift_forward_external(index - vacant, index, finish)
      end
      data_start -= vacant
      finish -= vacant
      run_length *= 2
    end
    index = (finish - (data_length % (2 * run_length)))
    if (index + run_length) < finish
      merge_with_buffer_backward(index, index + run_length, finish, finish + run_length, true)
    else
      shift_backward_external(index, finish, finish + run_length)
    end
    index -= (2 * run_length)
    while index >= data_start
      merge_with_buffer_backward(index, index + run_length, index + (2 * run_length), index + (3 * run_length), true)
      index -= (2 * run_length)
    end
    data_start += run_length
    finish += run_length
    run_length *= 2
    index = data_start
    while (index + (2 * run_length)) < finish
      merge_with_buffer_forward(index, index + run_length, index + (2 * run_length), index - run_length, true)
      index += (2 * run_length)
    end
    if (index + run_length) < finish
      merge_with_buffer_forward(index, index + run_length, finish, index - run_length, true)
    else
      shift_forward_external(index - run_length, index, finish)
    end
    data_start -= run_length
    finish -= run_length
    run_length *= 2
    index = (finish - (data_length % (2 * run_length)))
    if (index + run_length) < finish
      dual_merge_backward(index, index + run_length, finish, finish + (run_length / 2), true)
    else
      shift_backward_external(index, finish, finish + (run_length / 2))
    end
    index -= (2 * run_length)
    while index >= data_start
      dual_merge_backward(index, index + run_length, index + (2 * run_length), (index + (2 * run_length)) + (run_length / 2), true)
      index -= (2 * run_length)
    end
    data_start += (run_length / 2)
    finish += (run_length / 2)
    run_length *= 2
    if keys >= run_length
      rotate(start, key_end, data_start)
      bit_end = (key_end + block_length)
      if key_length >= run_length
        minimum_level = (2 * run_length)
        while run_length < key_length
          vacant = [minimum_level, run_length].max
          index = data_start
          while (index + (2 * run_length)) < finish
            merge_with_buffer_forward(index, index + run_length, index + (2 * run_length), index - vacant, false)
            index += (2 * run_length)
          end
          if (index + run_length) < finish
            merge_with_buffer_forward(index, index + run_length, finish, index - vacant, false)
          else
            shift_forward(index - vacant, index, finish)
          end
          data_start -= vacant
          finish -= vacant
          run_length *= 2
        end
        index = (finish - (data_length % (2 * run_length)))
        if (index + run_length) < finish
          merge_with_buffer_backward(index, index + run_length, finish, finish + run_length, false)
        else
          shift_backward(index, finish, finish + run_length)
        end
        index -= (2 * run_length)
        while index >= data_start
          merge_with_buffer_backward(index, index + run_length, index + (2 * run_length), index + (3 * run_length), false)
          index -= (2 * run_length)
        end
        data_start += run_length
        finish += run_length
        run_length *= 2
      end
      if keys >= run_length
        index = data_start
        while (index + (2 * run_length)) < finish
          merge_with_buffer_forward(index, index + run_length, index + (2 * run_length), index - run_length, false)
          index += (2 * run_length)
        end
        if (index + run_length) < finish
          merge_with_buffer_forward(index, index + run_length, finish, index - run_length, false)
        else
          shift_forward(index - run_length, index, finish)
        end
        data_start -= run_length
        finish -= run_length
        run_length *= 2
        index = (finish - (data_length % (2 * run_length)))
        if (index + run_length) < finish
          dual_merge_backward(index, index + run_length, finish, finish + (run_length / 2), false)
        else
          shift_backward(index, finish, finish + (run_length / 2))
        end
        index -= (2 * run_length)
        while index >= data_start
          dual_merge_backward(index, index + run_length, index + (2 * run_length), (index + (2 * run_length)) + (run_length / 2), false)
          index -= (2 * run_length)
        end
        data_start += (run_length / 2)
        finish += (run_length / 2)
        run_length *= 2
      end
      rotate(start, bit_end, data_start)
      bit_end = (key_end + keys)
      heap_sort(start, key_end)
    end
    (0...block_length).each do |offset|
      write(bit_end + offset, load(offset))
    end
    unshuffle(start, key_end)
    limit = (block_length * (key_length + 2))
    tag_count = ((run_length / block_length) - 1)
    while (run_length < data_length) && ([(2 * run_length), data_length].min <= limit)
      index = data_start
      while (index + (2 * run_length)) <= finish
        block_merge(index, index + run_length, index + (2 * run_length), tag_count, 2 * tag_count, start, start + key_length, key_end, key_end + key_length, block_length)
        index += (2 * run_length)
      end
      if (index + run_length) < finish
        block_merge(index, index + run_length, finish, tag_count, (((finish - index) - 1) / block_length) - 1, start, start + key_length, key_end, key_end + key_length, block_length)
      end
      run_length *= 2
      tag_count = ((2 * tag_count) + 1)
    end
    while run_length < data_length
      block_length = ((2 * run_length) / key_length)
      left_tail = (run_length % block_length)
      index = data_start
      while (index + (2 * run_length)) <= finish
        block_merge_easy(index, index + run_length, index + (2 * run_length), left_tail, left_tail, key_length / 2, key_length, start, start + key_length, key_end, key_end + key_length, block_length)
        index += (2 * run_length)
      end
      if (index + run_length) < finish
        block_merge_easy(index, index + run_length, finish, left_tail, ((finish - index) - run_length) % block_length, key_length / 2, (key_length / 2) + (((finish - index) - run_length) / block_length), start, start + key_length, key_end, key_end + key_length, block_length)
      end
      run_length *= 2
    end
    multi_swap(key_end + bit_separation, (key_end + key_length) + bit_separation, key_length - bit_separation)
    laziest_sort_external(start, data_start)
    redistribute_buffer(start, data_start, finish)
  end
end

def sort(values)
  if values.length >= 32 && values.length < 128
    FifthMerge.new(values).sort
  else
    sorter = ChaliceSortExample.new(values)
    if values.length < 32
      sorter.binary_insertion(0, values.length)
    else
      sorter.sort
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
