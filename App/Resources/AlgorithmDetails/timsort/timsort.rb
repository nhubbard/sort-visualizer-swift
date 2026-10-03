def min_run_length(value)
  n = value
  remainder = 0
  while n >= 32
    remainder |= n & 1
    n >>= 1
  end
  n + remainder
end

def count_run(values, start)
  finish = start + 1
  return 1 if finish == values.length

  descending = values[finish] < values[start]
  finish += 1
  if descending
    finish += 1 while finish < values.length && values[finish] < values[finish - 1]
    values[start...finish] = values[start...finish].reverse
  else
    finish += 1 while finish < values.length && values[finish] >= values[finish - 1]
  end
  finish - start
end

def binary_insertion(values, start, finish, sorted_end)
  (sorted_end...finish).each do |index|
    pivot = values[index]
    low = start
    high = index
    while low < high
      middle = (low + high) / 2
      if values[middle] <= pivot
        low = middle + 1
      else
        high = middle
      end
    end
    index.downto(low + 1) { |shift| values[shift] = values[shift - 1] }
    values[low] = pivot
  end
end

def merge(values, runs, index)
  start, left_length = runs[index]
  right_start, right_length = runs[index + 1]
  left = values[start...right_start]
  right = values[right_start...(right_start + right_length)]
  i = 0
  j = 0
  destination = start
  while i < left.length && j < right.length
    if left[i] <= right[j]
      values[destination] = left[i]
      i += 1
    else
      values[destination] = right[j]
      j += 1
    end
    destination += 1
  end
  while i < left.length
    values[destination] = left[i]
    i += 1
    destination += 1
  end
  while j < right.length
    values[destination] = right[j]
    j += 1
    destination += 1
  end
  runs[index, 2] = [[start, left_length + right_length]]
end

def sort(values)
  n = values.length
  return if n < 2

  minimum = min_run_length(n)
  runs = []
  cursor = 0
  while cursor < n
    length = count_run(values, cursor)
    forced = [minimum, n - cursor].min
    if length < forced
      binary_insertion(values, cursor, cursor + forced, cursor + length)
      length = forced
    end
    runs << [cursor, length]
    while runs.length > 1
      index = runs.length - 2
      if (index >= 1 && runs[index - 1][1] <= runs[index][1] + runs[index + 1][1]) ||
          (index >= 2 && runs[index - 2][1] <= runs[index][1] + runs[index - 1][1])
        index -= 1 if runs[index - 1][1] < runs[index + 1][1]
      elsif runs[index][1] > runs[index + 1][1]
        break
      end
      merge(values, runs, index)
    end
    cursor += length
  end
  while runs.length > 1
    index = runs.length - 2
    index -= 1 if index.positive? && runs[index - 1][1] < runs[index + 1][1]
    merge(values, runs, index)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
