def multi_swap(arr, i, j, length)
  length.times do |k|
    arr[i + k], arr[j + k] = arr[j + k], arr[i + k]
  end
end

def rotate(arr, mid, left_len, right_len)
  while left_len > 0 && right_len > 0
    if left_len > right_len
      multi_swap(arr, mid - right_len, mid, right_len)
      mid -= right_len
      left_len -= right_len
    else
      multi_swap(arr, mid - left_len, mid, left_len)
      mid += left_len
      right_len -= left_len
    end
  end
end

# Perfect-shuffle a chunk of `size - 1` elements by following the cycles of i -> i*2 mod size.
def shuffle_block(arr, start, size)
  i = 1
  while i < size
    val = arr[start + i - 1]
    j = (i * 2) % size
    while j != i
      next_val = arr[start + j - 1]
      arr[start + j - 1] = val
      val = next_val
      j = (j * 2) % size
    end
    arr[start + i - 1] = val
    i *= 3
  end
end

# A single riffle shuffle only closes into clean cycles at power-of-three sizes, so shuffle in
# power-of-three chunks and rotate the next chunk's tail into place before each one.
def shuffle(arr, start, end_)
  while end_ - start > 1
    half = (end_ - start) / 2
    chunk = 1
    chunk *= 3 while chunk * 3 - 1 <= 2 * half
    tail = (chunk - 1) / 2
    rotate(arr, start + half, half - tail, tail)
    shuffle_block(arr, start, chunk)
    start += chunk - 1
  end
end

def rotate_shuffled_equal(arr, i, j, size)
  k = 0
  while k < size
    arr[i + k], arr[j + k] = arr[j + k], arr[i + k]
    k += 2
  end
end

def rotate_shuffled(arr, mid, left_len, right_len)
  while left_len > 0 && right_len > 0
    if left_len > right_len
      rotate_shuffled_equal(arr, mid - right_len, mid, right_len)
      mid -= right_len
      left_len -= right_len
    else
      rotate_shuffled_equal(arr, mid - left_len, mid, left_len)
      mid += left_len
      right_len -= left_len
    end
  end
end

def rotate_shuffled_outer(arr, mid, left_len, right_len)
  if left_len > right_len
    rotate_shuffled_equal(arr, mid - right_len, mid + 1, right_len)
    mid -= right_len
    left_len -= right_len
  else
    rotate_shuffled_equal(arr, mid - left_len, mid + 1, left_len)
    mid += left_len + 1
    right_len -= left_len
  end
  rotate_shuffled(arr, mid, left_len, right_len)
end

# The inverse of shuffle_block: walks the same cycles, writing each value one step backward.
def unshuffle_block(arr, start, size)
  i = 1
  while i < size
    prev = i
    val = arr[start + i - 1]
    j = (i * 2) % size
    while j != i
      arr[start + prev - 1] = arr[start + j - 1]
      prev = j
      j = (j * 2) % size
    end
    arr[start + prev - 1] = val
    i *= 3
  end
end

def unshuffle(arr, start, end_)
  while end_ - start > 1
    half = (end_ - start) / 2
    chunk = 1
    chunk *= 3 while chunk * 3 - 1 <= 2 * half
    tail = (chunk - 1) / 2
    rotate_shuffled_outer(arr, start + 2 * tail, 2 * tail, 2 * half - 2 * tail)
    unshuffle_block(arr, start, chunk)
    start += chunk - 1
  end
end

def compare3(arr, i, j)
  return -1 if arr[i] < arr[j]
  return 0 if arr[i] == arr[j]

  1
end

# Scans the shuffled (interleaved) range one adjacent pair at a time. A pair already in order
# just advances the scan; a stretch of same-side elements gets un-shuffled back into two short
# plain runs and rotated into its final position.
def merge_up(arr, start, end_, from_left)
  i = start
  j = i + 1
  while j < end_
    cmp = compare3(arr, i, j)
    if cmp == -1 || (!from_left && cmp == 0)
      i += 1
      if i == j
        j += 1
        from_left = !from_left
      end
    elsif end_ - j == 1
      rotate(arr, j, j - i, 1)
      break
    else
      run = 0
      if from_left
        run += 1 while j + 2 * run < end_ && compare3(arr, j + 2 * run, i) != 1
      else
        run += 1 while j + 2 * run < end_ && compare3(arr, j + 2 * run, i) == -1
      end
      j -= 1
      unshuffle(arr, j, j + 2 * run)
      rotate(arr, j, j - i, run)
      i += run + 1
      j += 2 * run + 1
    end
  end
end

def merge(arr, start, mid, end_)
  if mid - start <= end_ - mid
    shuffle(arr, start, end_)
    merge_up(arr, start, end_, true)
  else
    shuffle(arr, start + 1, end_)
    merge_up(arr, start, end_, false)
  end
end

def ceil_pow2(x)
  x -= 1
  shift = 16
  while shift > 0
    x |= x >> shift
    shift >>= 1
  end
  x + 1
end

def sort(arr)
  n = arr.length
  return if n < 2

  subarray_count = ceil_pow2(n)
  while subarray_count > 1
    i = 0
    while i < subarray_count
      lo = n * i / subarray_count
      mid = n * (i + 1) / subarray_count
      hi = n * (i + 2) / subarray_count
      merge(arr, lo, mid, hi)
      i += 2
    end
    subarray_count >>= 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
