# ArrayV median-merge: the larger partition provides an in-array swap buffer.
def exchange(a, i, j)
  a[i], a[j] = a[j], a[i]
end

def insertion(a, first, last)
  (first + 1...last).each do |i|
    j = i
    while j > first && a[j - 1] > a[j]
      exchange(a, j - 1, j)
      j -= 1
    end
  end
end

def binary_insertion(a, first, last)
  (first + 1...last).each do |i|
    value = a[i]
    low = first
    high = i
    while low < high
      middle = low + (high - low) / 2
      if value < a[middle]
        high = middle
      else
        low = middle + 1
      end
    end
    j = i
    while j > low
      a[j] = a[j - 1]
      j -= 1
    end
    a[low] = value
  end
end

def median_three(a, first, last)
  middle = first + (last - 1 - first) / 2
  exchange(a, first, middle) if a[first] > a[middle]
  if a[middle] > a[last - 1]
    exchange(a, middle, last - 1)
    return if a[first] > a[middle]
  end
  exchange(a, first, middle)
end

def median_medians(a, first, last)
  alternate = true
  while last - first > 1
    write = first
    i = first
    while i + 10 <= last
      insertion(a, i, i + 5)
      exchange(a, write, i + 2)
      write += 1
      i += 5
    end
    if i < last
      insertion(a, i, last)
      exchange(a, write, i + (last - (alternate ? 1 : 0) - i) / 2)
      write += 1
      alternate = !alternate if (last - i).even?
    end
    last = write
  end
end

def partition(a, first, last, pivot)
  i = first - 1
  j = last
  loop do
    begin
      i += 1
    end while i < j && a[i] < a[pivot]
    begin
      j -= 1
    end while j >= i && a[j] > a[pivot]
    return j if i >= j
    exchange(a, i, j)
  end
end

def merge(a, first, middle, last, destination)
  i = first
  j = middle
  while i < middle && j < last
    if a[i] <= a[j]
      exchange(a, destination, i)
      i += 1
    else
      exchange(a, destination, j)
      j += 1
    end
    destination += 1
  end
  while i < middle
    exchange(a, destination, i)
    destination += 1
    i += 1
  end
  while j < last
    exchange(a, destination, j)
    destination += 1
    j += 1
  end
end

def merge_sort(a, first, last, buffer)
  length = last - first
  return if length <= 1
  width = length
  width = (width + 3) / 4 while width >= 32
  i = first
  while i + width <= last
    binary_insertion(a, i, i + width)
    i += width
  end
  binary_insertion(a, i, last)
  while width < length
    destination = buffer
    i = first
    while i + 2 * width <= last
      merge(a, i, i + width, i + 2 * width, destination)
      i += 2 * width
      destination += 2 * width
    end
    if i + width < last
      merge(a, i, i + width, last, destination)
    else
      while i < last
        exchange(a, i, destination)
        i += 1
        destination += 1
      end
    end
    width *= 2

    destination = first
    i = buffer
    while i + 2 * width <= buffer + length
      merge(a, i, i + width, i + 2 * width, destination)
      i += 2 * width
      destination += 2 * width
    end
    if i + width < buffer + length
      merge(a, i, i + width, buffer + length, destination)
    else
      while i < buffer + length
        exchange(a, i, destination)
        i += 1
        destination += 1
      end
    end
    width *= 2
  end
end

def sort(a)
  first = 0
  last = a.length
  bad_split = false
  used_medians = false
  while last - first > 16
    if bad_split
      median_medians(a, first, last)
      used_medians = true
    else
      median_three(a, first, last)
    end
    pivot = partition(a, first + 1, last, first)
    exchange(a, first, pivot)
    left = pivot - first
    right = last - pivot - 1
    bad_split = !used_medians &&
      (left.zero? || right.zero? ||
       (left > 0 && right > 0 && (left / right >= 16 || right / left >= 16)))
    if left <= right
      merge_sort(a, first, pivot, pivot + 1)
      first = pivot + 1
    else
      merge_sort(a, pivot + 1, last, 2 * pivot + 1 - last)
      last = pivot
    end
  end
  binary_insertion(a, first, last)
end

if __FILE__ == $PROGRAM_NAME
  array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81,
           68, 83, 32, 56, 10, 2, 95, 46, 21, 74, 6, 38]
  sort(array)
  puts array.inspect
end
