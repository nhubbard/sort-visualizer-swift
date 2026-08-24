def circle_sort_routine(array, lo, hi, last)
  return 0 if lo == hi

  low = lo
  high = hi
  mid = (hi - lo) / 2
  swap_count = 0
  while lo < hi
    if hi < last && array[lo] > array[hi]
      array[lo], array[hi] = array[hi], array[lo]
      swap_count += 1
    end
    lo += 1
    hi -= 1
  end
  swap_count += circle_sort_routine(array, low, low + mid, last)
  swap_count += circle_sort_routine(array, low + mid + 1, high, last) if low + mid + 1 < last
  swap_count
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
    return array if circle_sort_routine(array, 0, n - 1, last) == 0
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
