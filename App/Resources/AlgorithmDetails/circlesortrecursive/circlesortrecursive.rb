def next_power_of_two(n)
  k = 1
  while k < n
    k <<= 1
  end
  k
end

def circle_sort_routine(array, lo, hi, ending)
  return 0 if lo == hi
  low = lo
  high = hi
  mid = (hi - lo) / 2
  swaps = 0
  while lo < hi
    if hi < ending && array[lo] > array[hi]
      array[lo], array[hi] = array[hi], array[lo]
      swaps += 1
    end
    lo += 1
    hi -= 1
  end
  swaps += circle_sort_routine(array, low, low + mid, ending)
  if low + mid + 1 < ending
    swaps += circle_sort_routine(array, low + mid + 1, high, ending)
  end
  swaps
end

def sort(array)
  ending = array.length
  return array if ending == 0
  padded_length = next_power_of_two(ending)
  swaps = nil
  loop do
    swaps = circle_sort_routine(array, 0, padded_length - 1, ending)
    break unless swaps != 0
  end
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
