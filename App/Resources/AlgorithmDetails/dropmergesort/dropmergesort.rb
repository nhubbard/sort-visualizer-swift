RECENCY = 8
EARLY_OUT_TEST_AT = 4
EARLY_OUT_DISORDER_FRACTION = 0.6

def sort(array)
  length = array.length
  return array if length < 2

  dropped = []
  dropped_in_a_row = 0
  read = 0
  write = 0
  iteration = 0

  while read < length
    iteration += 1
    if iteration == length / EARLY_OUT_TEST_AT &&
       dropped.length > read * EARLY_OUT_DISORDER_FRACTION
      dropped.each do |value|
        array[write] = value
        write += 1
      end
      # Simplified fallback: the Python reference uses branched PDQ sorting here.
      array.sort!
      return array
    end

    if write == 0 || array[read] >= array[write - 1]
      array[write] = array[read]
      write += 1
      read += 1
      dropped_in_a_row = 0
    elsif dropped_in_a_row == 0 && write >= 2 && array[read] >= array[write - 2]
      dropped << array[write - 1]
      array[write - 1] = array[read]
      read += 1
    elsif dropped_in_a_row < RECENCY
      dropped << array[read]
      read += 1
      dropped_in_a_row += 1
    else
      dropped.pop(dropped_in_a_row)
      read -= dropped_in_a_row
      backtracked = 1
      write -= 1
      largest = read
      (read + 1 .. read + dropped_in_a_row).each do |index|
        largest = array[index] if array[index] > largest
      end

      while write >= 1 && largest < array[write - 1]
        write -= 1
        backtracked += 1
      end

      dropped.concat(array[write, backtracked])
      dropped_in_a_row = 0
    end
  end

  dropped.each_with_index { |value, offset| array[write + offset] = value }
  # Simplified tail sort: the Python reference uses branched PDQ sorting here.
  array[write, dropped.length] = array[write, dropped.length].sort
  buffer = array[write, dropped.length]
  left = write - 1
  right = buffer.length - 1
  output = length - 1

  while right >= 0
    if left < 0 || buffer[right] > array[left]
      array[output] = buffer[right]
      right -= 1
    else
      array[output] = array[left]
      left -= 1
    end
    output -= 1
  end

  array
end

array = [
  0, 1, 2, 3, 4, 9, 6, 7, 8, 5,
  10, 11, 12, 13, 14, 15, 21, 17, 18, 19,
  20, 16, 22, 23, 24, 28, 26, 27, 25, 29
]
sort(array)
p array
