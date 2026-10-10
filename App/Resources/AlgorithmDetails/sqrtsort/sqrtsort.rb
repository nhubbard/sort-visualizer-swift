# MIT License
# Copyright (c) 2014 Andrey Astrelin
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

class SqrtSortExample
  def initialize(values)
    @values = values
    @buffer = []
    @tags = []
  end

  def read(storage, index)
    (storage ? @buffer : @values)[index]
  end

  def write(storage, index, value)
    (storage ? @buffer : @values)[index] = value
  end

  def compare(first_storage, first, second_storage, second)
    read(first_storage, first) <=> read(second_storage, second)
  end

  def copy_values(source_storage, source, target_storage, target, count)
    if source_storage == target_storage && source < target && target < source + count
      (count - 1).downto(0) { |i| write(target_storage, target + i, read(source_storage, source + i)) }
    else
      count.times { |i| write(target_storage, target + i, read(source_storage, source + i)) }
    end
  end

  def swap_values(storage, a, b)
    return if a == b
    first = read(storage, a)
    write(storage, a, read(storage, b))
    write(storage, b, first)
  end

  def insertion(storage, position, length)
    (position + 1...position + length).each do |index|
      value = read(storage, index)
      cursor = index
      while cursor > position && read(storage, cursor - 1) > value
        write(storage, cursor, read(storage, cursor - 1))
        cursor -= 1
      end
      write(storage, cursor, value)
    end
  end

  def merge_right(storage, position, left_length, right_length, distance)
    destination = position + left_length + right_length + distance - 1
    right = position + left_length + right_length - 1
    left = position + left_length - 1
    while left >= position
      if right < position + left_length || compare(storage, left, storage, right) > 0
        write(storage, destination, read(storage, left))
        left -= 1
      else
        write(storage, destination, read(storage, right))
        right -= 1
      end
      destination -= 1
    end
    if right != destination
      while right >= position + left_length
        write(storage, destination, read(storage, right))
        right -= 1
        destination -= 1
      end
    end
  end

  def merge_left(storage, position, left_length, right_length, distance)
    left = position
    right = position + left_length
    destination = position + distance
    left_end = right
    right_end = right + right_length
    while right < right_end
      if left == left_end || compare(storage, left, storage, right) > 0
        write(storage, destination, read(storage, right))
        right += 1
      else
        write(storage, destination, read(storage, left))
        left += 1
      end
      destination += 1
    end
    if destination != left
      while left < left_end
        write(storage, destination, read(storage, left))
        left += 1
        destination += 1
      end
    end
  end

  def merge_down(storage, position, prefix, prefix_position, left_length, prefix_length)
    left = right = 0
    destination = position - prefix_length
    while right < prefix_length
      if left == left_length || compare(storage, position + left, prefix, prefix_position + right) >= 0
        write(storage, destination, read(prefix, prefix_position + right))
        right += 1
      else
        write(storage, destination, read(storage, position + left))
        left += 1
      end
      destination += 1
    end
    if destination != position + left
      while left < left_length
        write(storage, destination, read(storage, position + left))
        left += 1
        destination += 1
      end
    end
  end

  def smart_merge(storage, position, prior_length, prior_fragment, block_length)
    left = position
    right = position + prior_length
    destination = position - block_length
    left_end = right
    right_end = right + block_length
    opposite = 1 - prior_fragment
    while left < left_end && right < right_end
      order = compare(storage, left, storage, right)
      if order < 0 || (order == 0 && opposite == 1)
        write(storage, destination, read(storage, left))
        left += 1
      else
        write(storage, destination, read(storage, right))
        right += 1
      end
      destination += 1
    end
    if left < left_end
      remaining = left_end - left
      while left < left_end
        left_end -= 1
        right_end -= 1
        write(storage, right_end, read(storage, left_end))
      end
      [remaining, prior_fragment]
    else
      [right_end - right, opposite]
    end
  end

  def merge_buffers(storage, position, middle_tag, block_count, block_length, trailing_a_blocks, tail_length)
    if block_count == 0
      merge_left(storage, position, trailing_a_blocks * block_length, tail_length, -block_length)
      return
    end
    prior_length = block_length
    prior_fragment = @tags[0] < middle_tag ? 0 : 1
    process = block_length
    (1...block_count).each do |tag_index|
      rest = process - prior_length
      next_fragment = @tags[tag_index] < middle_tag ? 0 : 1
      if next_fragment == prior_fragment
        copy_values(storage, position + rest, storage, position + rest - block_length, prior_length)
        rest = process
        prior_length = block_length
      else
        prior_length, prior_fragment = smart_merge(storage, position + rest, prior_length, prior_fragment, block_length)
      end
      process += block_length
    end
    rest = process - prior_length
    if tail_length != 0
      if prior_fragment != 0
        copy_values(storage, position + rest, storage, position + rest - block_length, prior_length)
        rest = process
        prior_length = block_length * trailing_a_blocks
      else
        prior_length += block_length * trailing_a_blocks
      end
      merge_left(storage, position + rest, prior_length, tail_length, -block_length)
    else
      copy_values(storage, position + rest, storage, position + rest - block_length, prior_length)
    end
  end

  def build_blocks(storage, position, length, block_length)
    pair = 1
    while pair < length
      lower = compare(storage, position + pair - 1, storage, position + pair) > 0 ? 1 : 0
      write(storage, position + pair - 3, read(storage, position + pair - 1 + lower))
      write(storage, position + pair - 2, read(storage, position + pair - lower))
      pair += 2
    end
    write(storage, position + length - 3, read(storage, position + length - 1)) if length.odd?
    position -= 2
    part = 2
    while part < block_length
      left = 0
      right = length - 2 * part
      while left <= right
        merge_left(storage, position + left, part, part, -part)
        left += 2 * part
      end
      rest = length - left
      if rest > part
        merge_left(storage, position + left, part, rest - part, -part)
      else
        while left < length
          write(storage, position + left - part, read(storage, position + left))
          left += 1
        end
      end
      position -= part
      part *= 2
    end
    remainder = length % (2 * block_length)
    leftover = length - remainder
    if remainder <= block_length
      copy_values(storage, position + leftover, storage, position + leftover + block_length, remainder)
    else
      merge_right(storage, position + leftover, block_length, remainder - block_length, block_length)
    end
    while leftover > 0
      leftover -= 2 * block_length
      merge_right(storage, position + leftover, block_length, block_length, block_length)
    end
  end

  def combine_blocks(storage, position, length, run_length, block_length)
    combine_count = length / (2 * run_length)
    remainder = length % (2 * run_length)
    if remainder <= run_length
      length -= remainder
      remainder = 0
    end
    (0..combine_count).each do |group|
      break if group == combine_count && remainder == 0
      group_position = position + group * 2 * run_length
      count = (group == combine_count ? remainder : 2 * run_length) / block_length
      tag_end = count + (group == combine_count ? 1 : 0)
      (0..tag_end).each { |tag| @tags[tag] = tag }
      middle = run_length / block_length
      (1...count).each do |tag_index|
        selected = tag_index - 1
        (tag_index...count).each do |candidate|
          order = compare(storage, group_position + selected * block_length,
                          storage, group_position + candidate * block_length)
          selected = candidate if order > 0 || (order == 0 && @tags[selected] > @tags[candidate])
        end
        if selected != tag_index - 1
          block_length.times do |offset|
            swap_values(storage, group_position + (tag_index - 1) * block_length + offset,
                        group_position + selected * block_length + offset)
          end
          @tags[tag_index - 1], @tags[selected] = @tags[selected], @tags[tag_index - 1]
        end
      end
      trailing_a = 0
      tail = group == combine_count ? remainder % block_length : 0
      if tail != 0
        while trailing_a < count && compare(storage, group_position + count * block_length,
                                            storage, group_position + (count - trailing_a - 1) * block_length) < 0
          trailing_a += 1
        end
      end
      merge_buffers(storage, group_position, middle, count - trailing_a,
                    block_length, trailing_a, tail)
    end
    if length > 0
      (length - 1).downto(0) do |index|
        write(storage, position + index, read(storage, position + index - block_length))
      end
    end
  end

  def common_sort(storage, position, length, prefix, prefix_position)
    if length <= 16
      insertion(storage, position, length)
      return
    end
    block_length = 1
    block_length *= 2 while block_length * block_length < length
    copy_values(storage, position, prefix, prefix_position, block_length)
    common_sort(prefix, prefix_position, block_length, storage, position)
    build_blocks(storage, position + block_length, length - block_length, block_length)
    run_length = block_length
    loop do
      run_length *= 2
      break if length <= run_length
      combine_blocks(storage, position + block_length, length - block_length, run_length, block_length)
    end
    merge_down(storage, position + block_length, prefix, prefix_position, length - block_length, block_length)
  end

  def sort
    length = @values.length
    return if length < 2
    buffer_length = 1
    buffer_length *= 2 while buffer_length * buffer_length < length
    @buffer = Array.new(buffer_length, 0)
    @tags = Array.new((length - 1) / buffer_length + 2, 0)
    common_sort(false, 0, length, true, 0)
  end
end

def sort(array)
  SqrtSortExample.new(array).sort
end

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
