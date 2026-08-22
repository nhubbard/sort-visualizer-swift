def reverse_run(arr, lo, hi)
  while lo < hi
    arr[lo], arr[hi] = arr[hi], arr[lo]
    lo += 1
    hi -= 1
  end
end

# Finds the maximal run starting at index_in (every adjacent step in the
# same direction), reversing it in place if that direction was descending.
# Returns the index where the next run starts, or -1 if this was the last
# run.
def identify_run(arr, index_in, n)
  return -1 if index_in >= n - 1

  start_index = index_in
  index = index_in
  ascending = arr[index] <= arr[index + 1]
  index += 1
  while index < n - 1
    step_ascending = arr[index] <= arr[index + 1]
    break if step_ascending != ascending

    index += 1
  end
  reverse_run(arr, start_index, index) unless ascending
  (index >= n - 1) ? -1 : index + 1
end

# Merges arr[start...mid] with arr[mid...last] by copying the left run into a
# scratch buffer and merging forward from the low end.
def merge_up(arr, start, mid, last, buffer)
  (0...(mid - start)).each { |i| buffer[i] = arr[start + i] }
  buffer_pointer = 0
  left = start
  right = mid
  while left < right && right < last
    if buffer[buffer_pointer] <= arr[right]
      arr[left] = buffer[buffer_pointer]
      buffer_pointer += 1
    else
      arr[left] = arr[right]
      right += 1
    end
    left += 1
  end
  while left < right
    arr[left] = buffer[buffer_pointer]
    buffer_pointer += 1
    left += 1
  end
end

# Merges arr[start...mid] with arr[mid...last] by copying the right run into a
# scratch buffer and merging backward from the high end.
def merge_down(arr, start, mid, last, buffer)
  (0...(last - mid)).each { |i| buffer[i] = arr[mid + i] }
  buffer_pointer = last - mid - 1
  left = mid - 1
  right = last - 1
  while right > left && left >= start
    if buffer[buffer_pointer] >= arr[left]
      arr[right] = buffer[buffer_pointer]
      buffer_pointer -= 1
    else
      arr[right] = arr[left]
      left -= 1
    end
    right -= 1
  end
  while right > left
    arr[right] = buffer[buffer_pointer]
    buffer_pointer -= 1
    right -= 1
  end
end

# Picks whichever of merge_up/merge_down needs the smaller scratch copy.
def merge_runs(arr, left_start, right_start, last, buffer)
  if last - right_start < right_start - left_start
    merge_down(arr, left_start, right_start, last, buffer)
  else
    merge_up(arr, left_start, right_start, last, buffer)
  end
end

def sort(arr)
  n = arr.length
  return if n < 2

  runs = []
  last_run = 0
  while last_run != -1
    runs << last_run
    last_run = identify_run(arr, last_run, n)
  end

  buffer = Array.new(n, 0)
  run_count = runs.length
  while run_count > 1
    i = 0
    while i < run_count - 1
      last = (i + 2 >= run_count) ? n : runs[i + 2]
      merge_runs(arr, runs[i], runs[i + 1], last, buffer)
      i += 2
    end

    runs = runs.each_slice(2).map(&:first)
    run_count = runs.length
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
