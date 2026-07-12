def classify(value, min_value, c)
  ((value - min_value) * c).to_i + 1
end

def flash_sort(array)
  n = array.length
  return if n == 0

  m = (0.2 * n).to_i + 2

  min_value = array[0]
  max_value = array[0]
  max_index = 0

  i = 1
  while i < n - 1
    if array[i] < array[i + 1]
      small, big, big_index = array[i], array[i + 1], i + 1
    else
      big, big_index, small = array[i], i, array[i + 1]
    end
    if big > max_value
      max_value = big
      max_index = big_index
    end
    min_value = small if small < min_value
    i += 2
  end

  last = array[n - 1]
  if last < min_value
    min_value = last
  elsif last > max_value
    max_value = last
    max_index = n - 1
  end

  return if max_value == min_value

  l = Array.new(m + 1, 0)
  c = (m - 1.0) / (max_value - min_value)

  (0...n).each do |h|
    k = classify(array[h], min_value, c)
    l[k] += 1
  end

  (2..m).each do |k|
    l[k] += l[k - 1]
  end

  array[max_index], array[0] = array[0], array[max_index]

  j = 0
  k = m
  num_moves = 0
  while num_moves < n
    while j >= l[k]
      j += 1
      k = classify(array[j], min_value, c)
    end

    evicted = array[j]
    while j < l[k]
      k = classify(evicted, min_value, c)
      location = l[k] - 1
      temp = array[location]
      array[location] = evicted
      evicted = temp
      l[k] -= 1
      num_moves += 1
    end
  end

  (1...n).each do |idx|
    current = array[idx]
    pos = idx - 1
    while pos >= 0 && array[pos] > current
      array[pos + 1] = array[pos]
      pos -= 1
    end
    array[pos + 1] = current
  end
end

def sort(array)
  flash_sort(array)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
