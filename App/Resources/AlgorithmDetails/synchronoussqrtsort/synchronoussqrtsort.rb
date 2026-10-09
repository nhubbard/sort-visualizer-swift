# MIT License
# Copyright (c) 2021 The Holy Grail Sort Project, implemented by aphitorite
# Copyright (c) 2020-2021 aphitorite
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software
# and associated documentation files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all copies or
# substantial portions of the Software.
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

# Synchronous square-root block merge by aphitorite. MIT license; see the
# complete notice carried by the native SynchronousSqrtSort.swift source.
class SynchronousSqrt
  def initialize(values)
    @a = values
    @n = values.length
  end

  def binary_insertion(first, last)
    (first + 1...last).each do |i|
      value = @a[i]
      low = first
      high = i
      while low < high
        middle = low + (high - low) / 2
        if @a[middle] <= value
          low = middle + 1
        else
          high = middle
        end
      end
      j = i
      while j > low
        @a[j] = @a[j - 1]
        j -= 1
      end
      @a[low] = value if low != i
    end
  end

  def shift_forward(destination, source, last)
    while source < last
      @a[destination] = @a[source]
      destination += 1
      source += 1
    end
  end

  def shift_backward(first, source_end, destination_end)
    while source_end > first
      source_end -= 1
      destination_end -= 1
      @a[destination_end] = @a[source_end]
    end
  end

  def merge_forward(first, middle, last, output)
    left = first
    right = middle
    while left < middle && right < last
      if @a[left] <= @a[right]
        @a[output] = @a[left]
        left += 1
      else
        @a[output] = @a[right]
        right += 1
      end
      output += 1
    end
    shift_forward(output, left, middle) if left > output
    shift_forward(output, right, last)
  end

  def merge_backward(first, middle, last, output)
    left = middle - 1
    right = last - 1
    while right >= middle && left >= first
      output -= 1
      if @a[right] >= @a[left]
        @a[output] = @a[right]
        right -= 1
      else
        @a[output] = @a[left]
        left -= 1
      end
    end
    shift_backward(middle, right + 1, output) if output > right
    shift_backward(first, left + 1, output)
  end

  def smart_merge_backward(first, middle, last, output, reversed)
    left = middle - 1
    right = last - 1
    while left >= first && right >= middle
      take_left = reversed ? @a[left] >= @a[right] : @a[left] > @a[right]
      output -= 1
      if take_left
        @a[output] = @a[left]
        left -= 1
      else
        @a[output] = @a[right]
        right -= 1
      end
    end
    left + 1
  end

  def block_selection(first, last, block, tag_start, tag_count)
    available = [tag_count + 1, @tags.length - tag_start].min
    available.times do |i|
      @tags[tag_start + i] = i + (i <= tag_count / 2 ? 0 : @tags.length)
    end
    vacant = first
    current = first
    while current < last - block
      minimum = vacant == current ? current + block : current
      candidate = minimum + block
      while candidate < last
        if candidate != vacant &&
           (@a[candidate] < @a[minimum] ||
            (@a[candidate] == @a[minimum] &&
             @tags[tag_start + (candidate - first) / block] <
             @tags[tag_start + (minimum - first) / block]))
          minimum = candidate
        end
        candidate += block
      end
      if minimum > current
        if vacant == current
          block.times { |i| @a[current + i] = @a[minimum + i] }
          @tags[tag_start + (current - first) / block] =
            @tags[tag_start + (minimum - first) / block]
          vacant = minimum
        else
          block.times do |i|
            @a[current + i], @a[minimum + i] = @a[minimum + i], @a[current + i]
          end
          i = tag_start + (current - first) / block
          j = tag_start + (minimum - first) / block
          @tags[i], @tags[j] = @tags[j], @tags[i]
        end
      end
      current += block
    end
  end

  def merge_blocks_backward(first, last, first_tag, past_last_tag, block)
    tag = past_last_tag - 1
    frontier = last
    block_start = frontier - block
    reversed = @tags[tag] < @tags.length
    loop do
      begin
        tag -= 1
        block_start -= block
      end while tag >= first_tag && ((@tags[tag] < @tags.length) == reversed)
      if tag < first_tag
        shift_backward(first, frontier, frontier + block)
        break
      end
      frontier = smart_merge_backward(block_start, block_start + block,
                                      frontier, frontier + block, reversed)
      reversed = !reversed
    end
  end

  def sort
    if @n <= 16
      binary_insertion(0, @n)
      return
    end
    block = 1
    block *= 2 while block * block < @n
    first = block + @n % block
    last = @n
    work_length = last - first
    run = 1
    @prefix = Array.new(first, 0)
    @tags = Array.new((@n - 1) / block + 1, 0)
    binary_insertion(0, first)
    first.times { |i| @prefix[i] = @a[i] }

    while run < block
      distance = [2, run].max
      index = first
      while index + 2 * run < last
        merge_forward(index, index + run, index + 2 * run, index - distance)
        index += 2 * run
      end
      if index + run < last
        merge_forward(index, index + run, last, index - distance)
      else
        shift_forward(index - distance, index, last)
      end
      first -= distance
      last -= distance
      run *= 2
    end

    fragment = work_length % (2 * run)
    index = last - fragment
    if index + run < last
      merge_backward(index, index + run, last, last + run)
    else
      shift_backward(index, last, last + run)
    end
    index -= 2 * run
    while index >= first
      merge_backward(index, index + run, index + 2 * run, index + 3 * run)
      index -= 2 * run
    end
    first += run
    last += run
    run *= 2

    tag_count = 4
    while run < work_length
      index = first
      tag_index = 0
      while index + 2 * run < last
        block_selection(index - block, index + 2 * run, block, tag_index, tag_count)
        index += 2 * run
        tag_index += tag_count
      end
      has_fragment = index + run < last
      fragment = (last - index) / block
      block_selection(index - block, last, block, tag_index, tag_count) if has_fragment
      first -= block
      last -= block
      index -= block
      merge_blocks_backward(index, last, tag_index, tag_index + fragment, block) if has_fragment
      index -= 2 * run
      tag_index -= tag_count
      while index >= first
        merge_blocks_backward(index, index + 2 * run, tag_index,
                              tag_index + tag_count, block)
        index -= 2 * run
        tag_index -= tag_count
      end
      first += block
      last += block
      run *= 2
      tag_count *= 2
    end

    left = 0
    right = first
    output = 0
    while left < first && right < last
      if @prefix[left] <= @a[right]
        @a[output] = @prefix[left]
        left += 1
      else
        @a[output] = @a[right]
        right += 1
      end
      output += 1
    end
    while left < first
      @a[output] = @prefix[left]
      output += 1
      left += 1
    end
  end
end

def sort(values)
  SynchronousSqrt.new(values).sort
end

if __FILE__ == $PROGRAM_NAME
  array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  puts array.inspect
end
