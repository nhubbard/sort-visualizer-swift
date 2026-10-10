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

def sort(values)
  FifthMerge.new(values).sort
end

if __FILE__ == $PROGRAM_NAME
  array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  puts array.inspect
end
