INSERTION_THRESHOLD = 24

# Sorts arr[start...end] in place using a plain binary-search insertion sort -- the base case
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

# Dual-pivot partition of arr[start...fin]. `scratch` is a fixed index outside this range,
# borrowed briefly as scratch space by the closing rotation and immediately restored. Returns
# the boundary between the low region and everything at or above the smaller of the two pivots.
def partition(arr, start, fin, scratch)
  m1 = (start + start + fin) / 3
  m2 = (start + fin + fin) / 3

  if arr[m1] > arr[m2]
    arr[m1], arr[start] = arr[start], arr[m1]
    fin -= 1
    arr[m2], arr[fin] = arr[fin], arr[m2]
  else
    arr[m2], arr[start] = arr[start], arr[m2]
    fin -= 1
    arr[m1], arr[fin] = arr[fin], arr[m1]
  end

  low = start
  high = fin
  # Reversed from the usual low/high naming: after the swaps above, `start` holds the larger of
  # the two chosen medians and `fin` the smaller. Neither position moves again until the
  # closing rotation below, so their values are safe to hold onto directly.
  pivot_max = arr[start]
  pivot_min = arr[fin]

  k = low + 1
  while k < high
    if arr[k] < pivot_min
      low += 1
      arr[k], arr[low] = arr[low], arr[k]
    elsif arr[k] >= pivot_max
      loop do
        high -= 1
        break unless high > k && arr[high] >= pivot_max
      end
      arr[k], arr[high] = arr[high], arr[k]
      if arr[k] < pivot_min
        low += 1
        arr[k], arr[low] = arr[low], arr[k]
      end
    end
    k += 1
  end

  arr[start], arr[low] = arr[low], arr[start]
  # Three-way rotation: the value at `fin` moves to `scratch`, whatever was borrowed from
  # `scratch` moves to `high`, and whatever was at `high` moves to `fin`.
  displaced = arr[fin]
  arr[fin] = arr[high]
  arr[high] = arr[scratch]
  arr[scratch] = displaced

  low
end

# Sorts arr[start...fin] in place with no recursion: a single loop processes one segment at a
# time, shrinking and partitioning it down to INSERTION_THRESHOLD elements, finishing with
# binary_insertion_sort, then advancing past it to the next segment.
def quick_sort(arr, start, fin)
  # Move every copy of this range's maximum value to the very end first. Those elements are
  # already correctly placed relative to everything else, so the rest of the algorithm never
  # has to look at them again -- and the boundary in front of them becomes fixed scratch space
  # partition can borrow from.
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
  # refresh one of its two candidates, since reusing them would just compare equal again.
  reuse_median_candidates = true

  loop do
    while segment_end - a > INSERTION_THRESHOLD
      unless reuse_median_candidates
        m = (a + a + segment_end) / 3
        arr[a], arr[m] = arr[m], arr[a]
      end
      segment_end = partition(arr, a, segment_end, tail)
    end

    binary_insertion_sort(arr, a, segment_end)

    a = segment_end + 1
    if a >= tail
      arr[a - 1], arr[tail] = arr[tail], arr[a - 1] if a - 1 < tail
      return
    end

    segment_end = lower_bound_index(arr, a, tail, a - 1)
    arr[a - 1], arr[tail] = arr[tail], arr[a - 1]

    reuse_median_candidates = true
    while a < segment_end && arr[a - 1] == arr[a]
      reuse_median_candidates = false
      a += 1
    end
    reuse_median_candidates = true if a == segment_end
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
