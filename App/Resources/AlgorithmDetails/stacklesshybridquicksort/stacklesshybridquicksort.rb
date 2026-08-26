INSERTION_THRESHOLD = 16

# Arranges arr[start], arr[mid], arr[fin - 1] so the median of the three ends up at `start`,
# ready to serve as partition's pivot.
def median_of_three(arr, start, fin)
  mid = start + (fin - 1 - start) / 2
  if arr[start] > arr[mid]
    arr[start], arr[mid] = arr[mid], arr[start]
  end
  if arr[mid] > arr[fin - 1]
    arr[mid], arr[fin - 1] = arr[fin - 1], arr[mid]
    return if arr[start] > arr[mid]
  end
  arr[start], arr[mid] = arr[mid], arr[start]
end

# Classic two-pointer Hoare partition against the pivot median_of_three just placed at `start`.
# Returns the pivot's final resting index.
def partition(arr, start, fin)
  median_of_three(arr, start, fin)
  pivot = arr[start]
  i = start
  j = fin

  loop do
    i += 1
    while i < j && arr[i] < pivot
      i += 1
    end
    j -= 1
    while j >= i && arr[j] >= pivot
      j -= 1
    end
    if i < j
      arr[i], arr[j] = arr[j], arr[i]
    else
      arr[start], arr[j] = arr[j], arr[start]
      return j
    end
  end
end

# Finds where the value at target_index belongs among arr[start...fin], ties resolving toward
# the front (a plain lower-bound binary search).
def lower_bound_index(arr, start, fin, target_index)
  lo = start
  hi = fin
  while lo < hi
    mid = lo + (hi - lo) / 2
    if arr[target_index] <= arr[mid]
      hi = mid
    else
      lo = mid + 1
    end
  end
  lo
end

# Sorts arr[start...fin] in place using a plain binary-search insertion sort -- the base case
# once a segment shrinks small enough that further partitioning isn't worth it.
def binary_insertion_sort(arr, start, fin)
  (start...fin).each do |i|
    value = arr[i]
    lo = start
    hi = i
    while lo < hi
      mid = lo + (hi - lo) / 2
      if value < arr[mid]
        hi = mid
      else
        lo = mid + 1
      end
    end
    j = i - 1
    while j >= lo
      arr[j + 1] = arr[j]
      j -= 1
    end
    arr[lo] = value
  end
end

# Sorts arr[start...fin] in place with no recursion: a single loop processes one segment at a
# time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
# binary_insertion_sort, then advancing past it to the next segment.
def quick_sort(arr, start, fin)
  # Move every copy of this range's maximum value to the very end first. Those elements are
  # already correctly placed relative to everything else, so the rest of the algorithm never
  # has to look at them again -- and the boundary in front of them becomes the fixed resting
  # place partition sends each finished pivot out to.
  max_value = arr[start]
  ((start + 1)...fin).each do |i|
    max_value = arr[i] if arr[i] > max_value
  end

  tail = fin
  (start...fin).to_a.reverse_each do |i|
    if arr[i] == max_value
      tail -= 1
      arr[i], arr[tail] = arr[tail], arr[i]
    end
  end

  a = start
  segment_end = tail
  # False right after skipping a run of duplicates below means the next median-of-three should
  # refresh its candidates, since reusing them would just compare equal again.
  refresh_median = true

  loop do
    while segment_end - a > INSERTION_THRESHOLD
      median_of_three(arr, a, segment_end) if refresh_median
      pivot_index = partition(arr, a, segment_end)
      arr[pivot_index], arr[tail] = arr[tail], arr[pivot_index]
      segment_end = pivot_index
    end

    binary_insertion_sort(arr, a, segment_end)

    a = segment_end + 1
    if a >= tail
      arr[a - 1], arr[tail] = arr[tail], arr[a - 1] if a - 1 < tail
      return
    end

    segment_end = lower_bound_index(arr, a, tail, a - 1)
    arr[a - 1], arr[tail] = arr[tail], arr[a - 1]

    refresh_median = true
    while a < segment_end && arr[a - 1] == arr[a]
      refresh_median = false
      a += 1
    end
    refresh_median = true if a == segment_end
  end
end

def sort(arr)
  n = arr.length
  return if n < 2
  quick_sort(arr, 0, n)
end

array = [
  55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79,
  21, 88, 5, 51, 66, 29, 44, 12, 78, 33, 91, 6, 58, 12
]
sort(array)
p array
