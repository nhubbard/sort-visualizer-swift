def digit_at(value, divisor, radix)
  (value / divisor) % radix
end

def flag_sort(arr, low, high, divisor, radix)
  return if high - low <= 1

  count = Array.new(radix, 0)
  offset = Array.new(radix, 0)

  (low...high).each do |i|
    count[digit_at(arr[i], divisor, radix)] += 1
  end

  offset[0] = low
  (1...radix).each do |d|
    offset[d] = offset[d - 1] + count[d - 1]
  end
  bucket_start = offset.dup

  (0...radix).each do |d|
    while count[d] > 0
      origin = offset[d]
      from = origin
      value = arr[from]

      loop do
        digit = digit_at(value, divisor, radix)
        dest = offset[digit]
        offset[digit] += 1
        count[digit] -= 1
        displaced = arr[dest]
        arr[dest] = value
        value = displaced
        from = dest
        break if from == origin
      end
    end
  end

  return unless divisor > 1

  (0...radix).each do |d|
    begin_index = bucket_start[d]
    end_index = offset[d]
    flag_sort(arr, begin_index, end_index, divisor / radix, radix) if end_index - begin_index > 1
  end
end

def sort(arr)
  return if arr.length <= 1

  radix = 10
  max_value = arr.max

  divisor = 1
  divisor *= radix while max_value / divisor >= radix

  flag_sort(arr, 0, arr.length, divisor, radix)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
