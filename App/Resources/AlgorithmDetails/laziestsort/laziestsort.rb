def binary_insertion_sort(arr, lo, hi)
  ((lo + 1)...hi).each do |i|
    key = arr[i]
    left = lo
    right = i
    while left < right
      mid = (left + right) / 2
      if arr[mid] <= key
        left = mid + 1
      else
        right = mid
      end
    end
    j = i
    while j > left
      arr[j] = arr[j - 1]
      j -= 1
    end
    arr[left] = key
  end
end

def swap_range(arr, a, b, length)
  (0...length).each do |i|
    arr[a + i], arr[b + i] = arr[b + i], arr[a + i]
  end
end

# Swaps the two adjacent blocks arr[lo...mid] and arr[mid...hi] so their order is
# reversed, using no auxiliary storage: the smaller of the two remaining pieces is
# always swapped whole against an equal-sized piece of the other, which shrinks one
# piece to nothing a little at a time until both are exhausted.
def rotate(arr, lo, mid, hi)
  i = mid - lo
  j = hi - mid
  return if i == 0 || j == 0

  while i != j
    if i < j
      swap_range(arr, mid - i, mid + j - i, i)
      j -= i
    else
      swap_range(arr, mid - i, mid, j)
      i -= j
    end
  end
  swap_range(arr, mid - i, mid, i)
end

# Finds the first index in [lo, hi) whose element is not less than value, by doubling
# the step size until it overshoots and then binary-searching the resulting bracket,
# rather than scanning one element at a time. Assumes arr[lo] < value.
def gallop(arr, lo, hi, value)
  left = lo
  step = 1
  right = lo + step
  while right < hi && arr[right] < value
    left = right
    step *= 2
    right = lo + step
  end
  right = [right, hi].min
  while right - left > 1
    mid = (left + right) / 2
    if arr[mid] < value
      left = mid
    else
      right = mid
    end
  end
  right
end

# Merges the sorted run arr[lo...mid] into the sorted run arr[mid...hi] in place. `left`
# tracks the first not-yet-placed element of the left run, and `right` tracks the start
# of the not-yet-consumed remainder of the right run.
def merge(arr, lo, mid, hi)
  left = lo
  right = mid
  while left < right && right < hi
    if arr[left] <= arr[right]
      left += 1
    else
      boundary = gallop(arr, right, hi, arr[left])
      rotate(arr, left, right, boundary)
      left += boundary - right
      right = boundary
    end
  end
end

def integer_sqrt(n)
  Integer.sqrt(n)
end

def sort(arr)
  n = arr.length
  if n <= 16
    binary_insertion_sort(arr, 0, n)
    return
  end

  block_size = [16, integer_sqrt(n)].max
  low = 0
  while low < n
    binary_insertion_sort(arr, low, [low + block_size, n].min)
    low += block_size
  end

  # Merge blocks back to front: the already-sorted run always starts at merged_start,
  # and each step folds the block immediately before it into that run.
  num_blocks = (n + block_size - 1) / block_size
  merged_start = (num_blocks - 1) * block_size
  (num_blocks - 2).downto(0) do |i|
    left_start = i * block_size
    merge(arr, left_start, merged_start, n)
    merged_start = left_start
  end
end

array = [55, 12, 84, 3, 47, 91, 26, 68, 8, 73, 40, 97, 15, 62, 34, 79, 21, 88, 5, 51, 66, 29, 44, 12]
sort(array)
p array
