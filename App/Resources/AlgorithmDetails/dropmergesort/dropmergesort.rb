RECENCY = 8
EARLY_OUT_TEST_AT = 4
EARLY_OUT_DISORDER_FRACTION = 0.6

# A plain general-purpose sort for arr[lo...hi], used both as the early-out fallback and to sort
# the leftover "dropped" elements before the final merge. Any decent O(n log n) sort works here --
# the algorithm doesn't depend on which one.
def quicksort(arr, lo, hi)
  return if hi - lo <= 1
  pivot = arr[lo + (hi - lo) / 2]
  less = []
  equal = []
  greater = []

  (lo...hi).each do |i|
    if arr[i] < pivot
      less << arr[i]
    elsif arr[i] > pivot
      greater << arr[i]
    else
      equal << arr[i]
    end
  end

  quicksort(less, 0, less.length)
  quicksort(greater, 0, greater.length)

  merged = less + equal + greater
  merged.each_with_index { |value, i| arr[lo + i] = value }
end

def sort(arr)
  length = arr.length
  return if length < 2

  dropped = []
  num_dropped_in_a_row = 0
  read = 0
  write = 0
  iteration = 0
  early_out_stop = length / EARLY_OUT_TEST_AT

  while read < length
    iteration += 1
    if iteration == early_out_stop && dropped.length > read * EARLY_OUT_DISORDER_FRACTION
      # Too disordered for the adaptive approach to be worth it: flush what's been dropped so
      # far back into the array and fall back to a plain full sort.
      dropped.each do |value|
        arr[write] = value
        write += 1
      end
      dropped.clear
      quicksort(arr, 0, length)
      return
    end

    if write == 0 || arr[read] >= arr[write - 1]
      # In order -- keep it.
      arr[write] = arr[read]
      write += 1
      read += 1
      num_dropped_in_a_row = 0
    elsif num_dropped_in_a_row == 0 && write >= 2 && arr[read] >= arr[write - 2]
      # Quick undo: the element two back would have accepted this one just fine, so drop the
      # one right before it instead of the new element.
      dropped << arr[write - 1]
      arr[write - 1] = arr[read]
      read += 1
    elsif num_dropped_in_a_row < RECENCY
      dropped << arr[read]
      read += 1
      num_dropped_in_a_row += 1
    else
      # Accepting something `num_dropped_in_a_row` elements back made every subsequent element
      # drop -- that accept was a mistake. Undo it, and any other recently accepted elements
      # bigger than the dropped run's maximum.
      dropped.slice!(dropped.length - num_dropped_in_a_row, num_dropped_in_a_row)
      read -= num_dropped_in_a_row

      num_backtracked = 1
      write -= 1

      max_of_dropped = arr[read]
      ((read + 1)..(read + num_dropped_in_a_row)).each do |i|
        max_of_dropped = arr[i] if arr[i] > max_of_dropped
      end

      while write >= 1 && max_of_dropped < arr[write - 1]
        write -= 1
        num_backtracked += 1
      end

      (write...(write + num_backtracked)).each do |i|
        dropped << arr[i]
      end

      num_dropped_in_a_row = 0
    end
  end

  dropped.each_with_index do |value, offset|
    arr[write + offset] = value
  end

  quicksort(arr, write, length)

  # Copy the now-sorted dropped tail before the final backward merge starts overwriting
  # arr[write..] in place.
  buffer = arr[write, dropped.length]

  i = buffer.length - 1
  j = write - 1
  k = length - 1

  while i >= 0
    if j < 0 || buffer[i] > arr[j]
      arr[k] = buffer[i]
      k -= 1
      i -= 1
    else
      arr[k] = arr[j]
      k -= 1
      j -= 1
    end
  end
end

array = [
  0, 1, 2, 3, 4, 9, 6, 7, 8, 5, 10, 11, 12, 13, 14, 15,
  21, 17, 18, 19, 20, 16, 22, 23, 24, 28, 26, 27, 25, 29
]
sort(array)
p array
