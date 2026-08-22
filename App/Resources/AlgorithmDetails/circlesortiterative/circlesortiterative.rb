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
  swap_count
end

def sort(array)
  last = array.length
  return if last <= 1
  n = 1
  n <<= 1 while n < last

  number_of_swaps = 1
  while number_of_swaps != 0
    number_of_swaps = circle_sort_routine(array, n, last)
  end
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
