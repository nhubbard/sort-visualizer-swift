def bit_length(value)
  length = 0
  while value > 0
    value >>= 1
    length += 1
  end
  length
end

def min_level?(index)
  bit_length(index + 1).odd?
end

def better_than?(a, b, min_level)
  min_level ? a < b : a > b
end

def downheap(array, start, size)
  i = start
  loop do
    min_level = min_level?(i)
    left = (2 * i) + 1
    right = (2 * i) + 2
    return if left >= size

    winner = left
    winner = right if right < size && better_than?(array[right], array[winner], min_level)
    base = (4 * i) + 3
    (0...4).each do |offset|
      gc = base + offset
      winner = gc if gc < size && better_than?(array[gc], array[winner], min_level)
    end
    is_grandchild = winner >= base
    extreme = better_than?(array[winner], array[i], min_level)
    unless is_grandchild
      array[i], array[winner] = array[winner], array[i] if extreme
      return
    end
    if extreme
      array[i], array[winner] = array[winner], array[i]
    else
      return
    end
    parent = (winner - 1) / 2
    if min_level
      array[parent], array[winner] = array[winner], array[parent] if array[winner] > array[parent]
    elsif array[winner] < array[parent]
      array[parent], array[winner] = array[winner], array[parent]
    end
    i = winner
  end
end

def heapify(array, length)
  ((length - 1) / 2).downto(0) do |i|
    downheap(array, i, length)
  end
end

def store_max(array, heap_size)
  return heap_size if heap_size <= 1

  imax = 1
  imax = 2 if heap_size > 2 && array[2] > array[1]
  last = heap_size - 1
  array[imax], array[last] = array[last], array[imax]
  new_size = last
  downheap(array, imax, new_size) if imax < new_size
  new_size
end

def sort(arr)
  n = arr.length
  return if n <= 1

  heapify(arr, n)
  heap_size = n
  (n - 1).times do
    heap_size = store_max(arr, heap_size)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
