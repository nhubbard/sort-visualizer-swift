def circle_sort_routine(array, length, last)
  swap_count = 0
  gap = length / 2
  while gap > 0
    start = 0
    while start + gap < last
      low = start
      high = start + 2 * gap - 1
      while low < high
        if high < last && array[low] > array[high]
          array[low], array[high] = array[high], array[low]
          swap_count += 1
        end
        low += 1
        high -= 1
      end
      start += 2 * gap
    end
    gap /= 2
  end
  return swap_count
end

def binary_insertion_sort(array, last)
  (1...last).each do |i|
    value = array[i]
    lo = 0
    hi = i
    while lo < hi
      mid = lo + (hi - lo) / 2
      if value < array[mid]
        hi = mid
      else
        lo = mid + 1
      end
    end
    j = i
    while j > lo
      array[j] = array[j - 1]
      j -= 1
    end
    array[lo] = value
  end
end

def sort(array)
  last = array.length
  return if last <= 1
  n = 1
  threshold = 0
  while n < last
    n <<= 1
    threshold += 1
  end
  threshold /= 2

  iterations = 0
  loop do
    iterations += 1
    if iterations >= threshold
      binary_insertion_sort(array, last)
      return array
    end
    return array if circle_sort_routine(array, n, last) == 0
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
