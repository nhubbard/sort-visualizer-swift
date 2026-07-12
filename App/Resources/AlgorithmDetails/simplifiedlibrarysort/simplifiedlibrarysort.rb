def binary_search(array, item, start, stop)
  lo = start
  hi = stop
  while lo < hi
    mid = lo + (hi - lo) / 2
    if item < array[mid]
      hi = mid
    else
      lo = mid + 1
    end
  end
  return lo
end

def binary_insertion_sort(array, start, stop)
  (start + 1...stop).each do |i|
    item = array[i]
    pos = binary_search(array, item, start, i)
    j = i
    while j > pos
      array[j] = array[j - 1]
      j -= 1
    end
    array[pos] = item
  end
end

def rebalance(array, temp, counts, locations, spine_size, batch_end)
  (0...spine_size).each do |i|
    counts[i + 1] = counts[i + 1] + counts[i] + 1
  end

  k = 0
  (spine_size...batch_end).each do |i|
    gap = locations[k]
    position = counts[gap]
    temp[position] = array[i]
    counts[gap] = position + 1
    k += 1
  end

  (0...spine_size).each do |i|
    position = counts[i]
    temp[position] = array[i]
    counts[i] = position + 1
  end

  (0...batch_end).each do |i|
    array[i] = temp[i]
  end

  binary_insertion_sort(array, 0, counts[0] - 1)
  (0...spine_size - 1).each do |i|
    binary_insertion_sort(array, counts[i], counts[i + 1] - 1)
  end
  binary_insertion_sort(array, counts[spine_size - 1], counts[spine_size])

  (0...spine_size + 2).each do |i|
    counts[i] = 0
  end
end

def library_sort(array)
  n = array.length
  return array if n < 2

  rebalance_factor = 2
  spine_size = 1
  binary_insertion_sort(array, 0, spine_size)

  max_level = spine_size
  while max_level * rebalance_factor < n
    max_level *= rebalance_factor
  end

  temp = Array.new(n, 0)
  counts = Array.new(max_level + 2, 0)
  locations = Array.new(n, 0)

  i = spine_size
  k = 0
  while i < n
    if rebalance_factor * spine_size == i
      rebalance(array, temp, counts, locations, spine_size, i)
      spine_size = i
      k = 0
    end
    gap = binary_search(array, array[i], 0, spine_size)
    counts[gap + 1] += 1
    locations[k] = gap
    k += 1
    i += 1
  end
  rebalance(array, temp, counts, locations, spine_size, n)
  return array
end

def sort(array)
  return library_sort(array)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
