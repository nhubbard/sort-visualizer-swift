# MIT License
# Copyright (c) 2020-2021 aphitorite
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

class EctaSortExample
  def initialize(array)
    @a = array
  end

  def min_run(size)
    size = (size + 1) / 2 while size >= 32
    size
  end

  def insertion(start, finish)
    (start + 1...finish).each do |index|
      value = @a[index]
      low, high = start, index
      while low < high
        middle = (low + high) / 2
        if @a[middle] > value then high = middle else low = middle + 1 end
      end
      index.downto(low + 1) { |cursor| @a[cursor] = @a[cursor - 1] }
      @a[low] = value
    end
  end

  def copy(source, destination, count)
    return if count <= 0
    if source < destination
      (count - 1).downto(0) { |i| @a[destination + i] = @a[source + i] }
    else
      count.times { |i| @a[destination + i] = @a[source + i] }
    end
  end

  def merge_to(start, middle, finish, destination)
    left, right, output = start, middle, destination
    while left < middle && right < finish
      if @a[left] <= @a[right]
        @a[output] = @a[left]
        left += 1
      else
        @a[output] = @a[right]
        right += 1
      end
      output += 1
    end
    while left < middle
      @a[output] = @a[left]
      left += 1
      output += 1
    end
    while right < finish
      @a[output] = @a[right]
      right += 1
      output += 1
    end
  end

  def ping_pong(start, m1, m2, m3, finish, workspace)
    second = workspace + m2 - start
    merge_to(start, m1, m2, workspace)
    merge_to(m2, m3, finish, second)
    merge_to(workspace, second, workspace + finish - start, start)
  end

  def merge_backward(start, middle, finish, workspace)
    count = finish - middle
    copy(middle, workspace, count)
    left, right, output = middle - 1, workspace + count - 1, finish
    while left >= start && right >= workspace
      output -= 1
      if @a[left] > @a[right]
        @a[output] = @a[left]
        left -= 1
      else
        @a[output] = @a[right]
        right -= 1
      end
    end
    while right >= workspace
      output -= 1
      @a[output] = @a[right]
      right -= 1
    end
  end

  def merge_from_buffer(start, middle, finish, count)
    index, right, output = 0, middle, start
    while index < count && right < finish
      if @a[right] >= @buffer[index]
        @a[output] = @buffer[index]
        index += 1
      else
        @a[output] = @a[right]
        right += 1
      end
      output += 1
    end
    while index < count
      @a[output] = @buffer[index]
      index += 1
      output += 1
    end
  end

  def dual_merge_backward(start, first, middle, finish, count)
    index, split = count - 1, count - (finish - middle)
    left, output = middle - 1, finish
    while index >= split && left >= first
      output -= 1
      if @a[left] < @buffer[index]
        @a[output] = @buffer[index]
        index -= 1
      else
        @a[output] = @a[left]
        left -= 1
      end
    end
    if left < first
      while index >= 0
        output -= 1
        @a[output] = @buffer[index]
        index -= 1
      end
    else
      merge_from_buffer(start, first, output, split)
    end
  end

  def merge_sort(start, finish, workspace, initial_run, capacity)
    run, index = initial_run, start
    while index + run <= finish
      insertion(index, index + run)
      index += run
    end
    insertion(index, finish)
    while 4 * run <= capacity
      index = start
      while index + 4 * run <= finish
        ping_pong(index, index + run, index + 2 * run, index + 3 * run, index + 4 * run, workspace)
        index += 4 * run
      end
      if index + 3 * run < finish
        ping_pong(index, index + run, index + 2 * run, index + 3 * run, finish, workspace)
      elsif index + 2 * run < finish
        ping_pong(index, index + run, index + 2 * run, finish, finish, workspace)
      elsif index + run < finish
        merge_backward(index, index + run, finish, workspace)
      end
      run *= 4
    end
    while run <= capacity
      index = start
      while index + 2 * run <= finish
        merge_backward(index, index + run, index + 2 * run, workspace)
        index += 2 * run
      end
      merge_backward(index, index + run, finish, workspace) if index + run < finish
      run *= 2
    end
    run
  end

  def block_cycle(start, count, workspace, exclude_last, forward)
    stride = forward ? @block : -@block
    count.times do |index|
      next_tag = @tags[index]
      next if index == next_tag
      copy(start + index * stride, workspace, @block)
      current = index
      loop do
        copy(start + next_tag * stride, start + current * stride, @block) unless exclude_last && current == count - 1
        @tags[current] = current
        current = next_tag
        next_tag = @tags[next_tag]
        break if next_tag == index
      end
      copy(workspace, start + current * stride, @block)
      @tags[current] = current
    end
  end

  def ecta_forward(start, middle, finish)
    left, right, tag, tag_count, saved, other = start, middle, 0, 0, 2 * @block, 0
    saved_position, other_position = start - 2 * @block, middle
    loop do
      choice = saved < @block ? 1 : 0
      @block.times do |offset|
        destination = (choice == 0 ? saved_position : other_position) + offset
        if left < middle && right < finish
          if @a[left] <= @a[right]
            @a[destination] = @a[left]; left += 1; saved += 1
          else
            @a[destination] = @a[right]; right += 1; other += 1
          end
        elsif left < middle
          @a[destination] = @a[left]; left += 1; saved += 1
        else
          @a[destination] = @a[right]; right += 1; other += 1
        end
      end
      if choice == 0
        saved_position += @block; saved -= @block
      else
        other_position += @block; other -= @block
      end
      @tags[tag_count] = choice == 0 ? tag : -1
      tag_count += 1
      tag += 1 if choice == 0
      break unless left < middle || right < finish
    end
    if saved > 0
      @tags[tag_count] = tag
      tag += 1
    end
    (2...tag_count).each do |index|
      if @tags[index] == -1
        @tags[index] = tag
        tag += 1
      end
    end
    block_cycle(start - 2 * @block, tag, finish - @block, saved > 0, true)
  end

  def ecta_backward(start, middle, finish)
    right, left, tag, tag_count, saved, other = finish - 1, middle - 1, 0, 0, 2 * @block, 0
    saved_position, other_position = finish + 2 * @block, middle
    loop do
      choice = saved < @block ? 1 : 0
      (1..@block).each do |offset|
        destination = (choice == 0 ? saved_position : other_position) - offset
        if right >= middle && left >= start
          if @a[right] >= @a[left]
            @a[destination] = @a[right]; right -= 1; saved += 1
          else
            @a[destination] = @a[left]; left -= 1; other += 1
          end
        elsif right >= middle
          @a[destination] = @a[right]; right -= 1; saved += 1
        else
          @a[destination] = @a[left]; left -= 1; other += 1
        end
      end
      if choice == 0
        saved_position -= @block; saved -= @block
      else
        other_position -= @block; other -= @block
      end
      @tags[tag_count] = choice == 0 ? tag : -1
      tag_count += 1
      tag += 1 if choice == 0
      break unless right >= middle || left >= start
    end
    if saved > 0
      @tags[tag_count] = tag
      tag += 1
    end
    (2...tag_count).each do |index|
      if @tags[index] == -1
        @tags[index] = tag
        tag += 1
      end
    end
    block_cycle(finish + @block, tag, start, saved > 0, false)
  end

  def sort
    n = @a.length
    return if n < 2
    if n <= 32
      insertion(0, n)
      return
    end
    if n < 256
      @block = 0
      @buffer_length = n / 2
    else
      @block = min_run(n)
      @block *= 2 while @block * @block < n / 2
      @buffer_length = 2 * @block + n % @block
    end
    @buffer = Array.new(@buffer_length)
    @tags = Array.new(@block == 0 ? 0 : (n - @buffer_length) / @block + 1, 0)
    @buffer_length.times { |i| @buffer[i] = @a[@buffer_length + i] } if n < 256
    if n < 256
      merge_sort(0, @buffer_length, @buffer_length, min_run(n), @buffer_length)
      @buffer_length.times { |i| @a[@buffer_length + i] = @buffer[i] }
      @buffer_length.times { |i| @buffer[i] = @a[i] }
      merge_sort(@buffer_length, n, 0, min_run(n), @buffer_length)
      merge_from_buffer(0, @buffer_length, n, @buffer_length)
      return
    end
    start, finish = @buffer_length, n
    data_length = finish - start
    @buffer_length.times { |i| @buffer[i] = @a[start + i] }
    merge_sort(0, start, start, min_run(@buffer_length), @buffer_length)
    @buffer_length.times { |i| @a[start + i] = @buffer[i] }
    @buffer_length.times { |i| @buffer[i] = @a[i] }
    run = merge_sort(start, finish, 0, min_run(n), @buffer_length)
    backward = false
    while run < data_length
      index = start
      while index + 2 * run <= finish
        ecta_forward(index, index + run, index + 2 * run)
        index += 2 * run
      end
      if index + run < finish
        ecta_forward(index, index + run, finish)
      else
        copy(index, index - 2 * @block, finish - index)
      end
      run *= 2; start -= 2 * @block; finish -= 2 * @block
      if run >= data_length
        backward = true
        break
      end
      index = start
      index += 2 * run while index + 2 * run <= finish
      if index + run < finish
        ecta_backward(index, index + run, finish)
      else
        copy(index, index + 2 * @block, finish - index)
      end
      index -= 2 * run
      while index >= start
        ecta_backward(index, index + run, index + 2 * run)
        index -= 2 * run
      end
      run *= 2; start += 2 * @block; finish += 2 * @block
    end
    if backward
      dual_merge_backward(0, start, finish, n, @buffer_length)
    else
      merge_from_buffer(0, start, finish, @buffer_length)
    end
  end
end

def sort(array)
  EctaSortExample.new(array).sort
end

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
