# Copyright (C) 2008 The Android Open Source Project
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

class TimSort
  def initialize(values)
    @a = values
    @n = values.length
    capacity = @n < 120 ? 5 : @n < 1542 ? 10 : @n < 119_151 ? 19 : 40
    @base = Array.new(capacity, 0)
    @length = Array.new(capacity, 0)
    @stack_size = 0
    @temp = []
    @min_gallop = 7
  end

  def ensure_capacity(needed)
    return if @temp.length >= needed
    capacity = [1, @temp.length].max
    capacity *= 2 while capacity < needed
    capacity = [capacity, [1, @n / 2].max].min
    @temp = Array.new(capacity, 0)
  end

  def min_run_length(value)
    remainder = 0
    while value >= 32
      remainder |= value & 1
      value >>= 1
    end
    value + remainder
  end

  def count_run(first, last)
    return 1 if first + 1 >= last
    cursor = first + 2
    if @a[first + 1] < @a[first]
      cursor += 1 while cursor < last && @a[cursor] < @a[cursor - 1]
      left = first
      right = cursor - 1
      while left < right
        @a[left], @a[right] = @a[right], @a[left]
        left += 1
        right -= 1
      end
    else
      cursor += 1 while cursor < last && @a[cursor] >= @a[cursor - 1]
    end
    cursor - first
  end

  def binary_insertion(first, last, sorted_end)
    cursor = [first + 1, sorted_end].max
    while cursor < last
      pivot = @a[cursor]
      low = first
      high = cursor
      while low < high
        middle = low + (high - low) / 2
        if @a[middle] <= pivot
          low = middle + 1
        else
          high = middle
        end
      end
      shift = cursor
      while shift > low
        @a[shift] = @a[shift - 1]
        shift -= 1
      end
      @a[low] = pivot
      cursor += 1
    end
  end

  def gallop(first, last, key, upper, from_end, use_temp)
    return first if first >= last
    source = use_temp ? @temp : @a
    before = ->(i) { upper ? source[i] <= key : source[i] < key }
    if from_end
      high = last
      low = last - 1
      step = 1
      until before.call(low)
        high = low
        break if low == first
        step = [last - first, step * 2].min
        low = [first, last - step].max
      end
    else
      low = first
      high = first + 1
      while before.call(high - 1) && high < last
        low = high
        high = [last, first + (high - first) * 2].min
      end
    end
    while low < high
      middle = low + (high - low) / 2
      if before.call(middle)
        low = middle + 1
      else
        high = middle
      end
    end
    low
  end

  def merge_low(first, left_length, right_start, right_length)
    ensure_capacity(left_length)
    left_length.times { |i| @temp[i] = @a[first + i] }
    left = 0
    right = right_start
    destination = first
    right_end = right_start + right_length
    left_wins = right_wins = 0
    galloped = false
    while left < left_length && right < right_end
      if @a[right] < @temp[left]
        @a[destination] = @a[right]
        right += 1
        right_wins += 1
        left_wins = 0
      else
        @a[destination] = @temp[left]
        left += 1
        left_wins += 1
        right_wins = 0
      end
      destination += 1
      break if left >= left_length || right >= right_end
      next if [left_wins, right_wins].max < @min_gallop
      galloped = true
      left_stop = gallop(left, left_length, @a[right], true, false, true)
      while left < left_stop
        @a[destination] = @temp[left]
        left += 1
        destination += 1
      end
      break if left == left_length
      @a[destination] = @a[right]
      right += 1
      destination += 1
      break if right == right_end
      right_stop = gallop(right, right_end, @temp[left], false, false, false)
      while right < right_stop
        @a[destination] = @a[right]
        right += 1
        destination += 1
      end
      break if right == right_end
      @a[destination] = @temp[left]
      left += 1
      destination += 1
      @min_gallop = [1, @min_gallop - 1].max
      left_wins = right_wins = 0
    end
    while left < left_length
      @a[destination] = @temp[left]
      left += 1
      destination += 1
    end
    @min_gallop += 2 if galloped
  end

  def merge_high(first, left_length, right_start, right_length)
    ensure_capacity(right_length)
    right_length.times { |i| @temp[i] = @a[right_start + i] }
    left = right_start - 1
    right = right_length - 1
    destination = right_start + right_length - 1
    left_wins = right_wins = 0
    galloped = false
    while left >= first && right >= 0
      if @temp[right] < @a[left]
        @a[destination] = @a[left]
        left -= 1
        left_wins += 1
        right_wins = 0
      else
        @a[destination] = @temp[right]
        right -= 1
        right_wins += 1
        left_wins = 0
      end
      destination -= 1
      break if left < first || right < 0
      next if [left_wins, right_wins].max < @min_gallop
      galloped = true
      left_stop = gallop(first, left + 1, @temp[right], true, true, false)
      while left >= left_stop
        @a[destination] = @a[left]
        left -= 1
        destination -= 1
      end
      break if left < first
      @a[destination] = @temp[right]
      right -= 1
      destination -= 1
      break if right < 0
      right_stop = gallop(0, right + 1, @a[left], false, true, true)
      while right >= right_stop
        @a[destination] = @temp[right]
        right -= 1
        destination -= 1
      end
      break if right < 0
      @a[destination] = @a[left]
      left -= 1
      destination -= 1
      @min_gallop = [1, @min_gallop - 1].max
      left_wins = right_wins = 0
    end
    while right >= 0
      @a[destination] = @temp[right]
      right -= 1
      destination -= 1
    end
    @min_gallop += 2 if galloped
  end

  def merge_at(index)
    left_start = @base[index]
    left_length = @length[index]
    right_start = @base[index + 1]
    right_length = @length[index + 1]
    @length[index] = left_length + right_length
    if index == @stack_size - 3
      @base[index + 1] = @base[index + 2]
      @length[index + 1] = @length[index + 2]
    end
    @stack_size -= 1
    skipped = gallop(left_start, right_start, @a[right_start], true, false, false)
    left_length -= skipped - left_start
    left_start = skipped
    return if left_length.zero?
    right_length = gallop(right_start, right_start + right_length,
                          @a[right_start - 1], false, false, false) - right_start
    return if right_length.zero?
    if left_length <= right_length
      merge_low(left_start, left_length, right_start, right_length)
    else
      merge_high(left_start, left_length, right_start, right_length)
    end
  end

  def collapse
    while @stack_size > 1
      index = @stack_size - 2
      if (index >= 1 && @length[index - 1] <= @length[index] + @length[index + 1]) ||
         (index >= 2 && @length[index - 2] <= @length[index] + @length[index - 1])
        index -= 1 if @length[index - 1] < @length[index + 1]
      elsif @length[index] > @length[index + 1]
        break
      end
      merge_at(index)
    end
  end

  def force_collapse
    while @stack_size > 1
      index = @stack_size - 2
      index -= 1 if index > 0 && @length[index - 1] < @length[index + 1]
      merge_at(index)
    end
  end

  def sort
    if @n < 32
      binary_insertion(0, @n, count_run(0, @n))
      return
    end
    min_run = min_run_length(@n)
    cursor = 0
    while cursor < @n
      run = count_run(cursor, @n)
      if run < min_run
        forced = [min_run, @n - cursor].min
        binary_insertion(cursor, cursor + forced, cursor + run)
        run = forced
      end
      @base[@stack_size] = cursor
      @length[@stack_size] = run
      @stack_size += 1
      collapse
      cursor += run
    end
    force_collapse
  end
end

def sort(values)
  TimSort.new(values).sort if values.length > 1
end

if __FILE__ == $PROGRAM_NAME
  array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  puts array.inspect
end
