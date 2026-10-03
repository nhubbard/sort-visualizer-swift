class OptimizedRotateMergeExample
  def initialize(values)
    @values = values
    @buffer = Array.new(64, 0)
  end

  def lower_bound(start, finish, value)
    while start < finish
      middle = (start + finish) / 2
      if @values[middle] < value then start = middle + 1 else finish = middle end
    end
    start
  end

  def upper_bound(start, finish, value)
    while start < finish
      middle = (start + finish) / 2
      if @values[middle] <= value then start = middle + 1 else finish = middle end
    end
    start
  end

  def reverse(start, finish)
    finish -= 1
    while start < finish
      @values[start], @values[finish] = @values[finish], @values[start]
      start += 1
      finish -= 1
    end
  end

  def rotate(start, middle, finish)
    return if start >= middle || middle >= finish
    left = middle - start
    right = finish - middle
    if left <= 64
      left.times { |i| @buffer[i] = @values[start + i] }
      (middle...finish).each { |i| @values[i - left] = @values[i] }
      left.times { |i| @values[finish - left + i] = @buffer[i] }
    elsif right <= 64
      right.times { |i| @buffer[i] = @values[middle + i] }
      (middle - 1).downto(start) { |i| @values[i + right] = @values[i] }
      right.times { |i| @values[start + i] = @buffer[i] }
    else
      reverse(start, middle)
      reverse(middle, finish)
      reverse(start, finish)
    end
  end

  def buffered_merge(start, middle, finish)
    left_length = middle - start
    right_length = finish - middle
    if left_length <= right_length
      left_length.times { |i| @buffer[i] = @values[start + i] }
      left, right, destination = 0, middle, start
      while left < left_length && right < finish
        if @values[right] < @buffer[left]
          @values[destination] = @values[right]
          right += 1
        else
          @values[destination] = @buffer[left]
          left += 1
        end
        destination += 1
      end
      while left < left_length
        @values[destination] = @buffer[left]
        left += 1
        destination += 1
      end
    else
      right_length.times { |i| @buffer[i] = @values[middle + i] }
      left, right, destination = middle - 1, right_length - 1, finish - 1
      while left >= start && right >= 0
        if @values[left] > @buffer[right]
          @values[destination] = @values[left]
          left -= 1
        else
          @values[destination] = @buffer[right]
          right -= 1
        end
        destination -= 1
      end
      while right >= 0
        @values[destination] = @buffer[right]
        right -= 1
        destination -= 1
      end
    end
  end

  def merge(start, middle, finish)
    return if start >= middle || middle >= finish || @values[middle - 1] <= @values[middle]
    if [middle - start, finish - middle].min <= 64
      buffered_merge(start, middle, finish)
      return
    end
    if middle - start >= finish - middle
      left_split = start + (middle - start) / 2
      right_split = lower_bound(middle, finish, @values[left_split])
    else
      right_split = middle + (finish - middle) / 2
      left_split = upper_bound(start, middle, @values[right_split])
    end
    rotate(left_split, middle, right_split)
    new_middle = left_split + right_split - middle
    merge(start, left_split, new_middle)
    merge(new_middle, right_split, finish)
  end

  def insertion(start, finish)
    (start + 1...finish).each do |index|
      value = @values[index]
      destination = upper_bound(start, index, value)
      index.downto(destination + 1) { |cursor| @values[cursor] = @values[cursor - 1] }
      @values[destination] = value
    end
  end

  def sort
    count = @values.length
    return if count < 2
    start = 0
    while start < count
      insertion(start, [start + 32, count].min)
      start += 32
    end
    run = 32
    while run < count
      start = 0
      while start + run < count
        merge(start, start + run, [start + 2 * run, count].min)
        start += 2 * run
      end
      run *= 2
    end
  end
end

def sort(values)
  OptimizedRotateMergeExample.new(values).sort
end

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
