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

def shift_backward(a, first, middle, last)
  while middle > first
    middle -= 1
    last -= 1
    exchange(a, middle, last)
  end
end

def multi_swap(a, first, second, length)
  length.times { |offset| exchange(a, first + offset, second + offset) }
end

def rotate(a, first, middle, last)
  left = middle - first
  right = last - middle
  while left > 0 && right > 0
    if right < left
      multi_swap(a, middle - right, middle, right)
      last -= right
      middle -= right
      left -= right
    else
      multi_swap(a, first, middle, left)
      first += left
      middle += left
      right -= left
    end
  end
end

def in_place_merge(a, first, middle, last)
  left = first
  right = middle
  while left < right && right < last
    if a[left] > a[right]
      upper = right + 1
      upper += 1 while upper < last && a[left] > a[upper]
      rotate(a, left, right, upper)
      left += upper - right
      right = upper
    else
      left += 1
    end
  end
end

def partition(a, first, last)
  left = first
  right = last
  loop do
    begin
      left += 1
    end while left < right && a[left] > a[first]
    begin
      right -= 1
    end while right >= left && a[right] < a[first]
    return right if left >= right
    exchange(a, left, right)
  end
end

def quick_select(a, lower, upper, target)
  bad_split = false
  used_medians = false
  target_upper = (target + upper + 1) / 2
  loop do
    if bad_split
      median_medians(a, lower, upper)
      used_medians = true
    else
      median_three(a, lower, upper)
    end
    pivot = partition(a, lower, upper)
    exchange(a, lower, pivot)
    left = [1, pivot - lower].max
    right = [1, upper - pivot - 1].max
    bad_split = !used_medians && (left / right >= 16 || right / left >= 16)
    return pivot if pivot >= target && pivot < target_upper
    if pivot < target
      lower = pivot + 1
    else
      upper = pivot
    end
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

def merge_forward(a, destination, first, middle, last)
  left = first
  right = middle
  while left < middle && right < last
    if a[left] <= a[right]
      exchange(a, destination, left)
      left += 1
    else
      exchange(a, destination, right)
      right += 1
    end
    destination += 1
  end
  left < middle ? left : right
end

def sort(a)
  n = a.length
  return if n <= 1
  first = 0
  middle = (n + 1) / 2
  minimum = Math.sqrt(n).floor
  merge_sort(a, middle, n, first)
  while middle - first > minimum
    selected = quick_select(a, first, middle, (first + middle + 1) / 2)
    merge_sort(a, selected, middle, first)
    buffer_length = selected - first
    merge_end = [selected + buffer_length, n].min
    selected = merge_forward(a, first, selected, middle, merge_end)
    while selected < middle
      shift_backward(a, selected, middle, merge_end)
      selected = merge_end - (middle - selected)
      first = selected - buffer_length
      middle = merge_end
      break if middle == n
      merge_end = [merge_end + buffer_length, n].min
      selected = merge_forward(a, first, selected, middle, merge_end)
    end
    middle = selected
    first = selected - buffer_length
  end
  binary_insertion(a, first, middle)
  in_place_merge(a, first, middle, n)
end

if __FILE__ == $PROGRAM_NAME
  array = [0, 39, 21, 62, 91, 77, 14, 23, 90, 69, 51, 81, 68, 83, 32, 56]
  sort(array)
  puts array.inspect
end
