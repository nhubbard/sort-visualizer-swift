def swap(arr, a, b)
  arr[a], arr[b] = arr[b], arr[a]
end

def multi_swap(arr, a, b, count)
  count.times { |i| swap(arr, a + i, b + i) }
end

def rotate(arr, pos, len_a, len_b)
  while len_a != 0 && len_b != 0
    if len_a <= len_b
      multi_swap(arr, pos, pos + len_a, len_a)
      pos += len_a
      len_b -= len_a
    else
      multi_swap(arr, pos + (len_a - len_b), pos + len_a, len_b)
      len_a -= len_b
    end
  end
end

def bin_search(arr, pos, len, key_pos, is_left)
  left = -1
  right = len
  key = arr[key_pos]
  while left < right - 1
    mid = left + (right - left) / 2
    cond = is_left ? (arr[pos + mid] >= key) : (arr[pos + mid] > key)
    if cond
      right = mid
    else
      left = mid
    end
  end
  right
end

def merge_without_buffer(arr, pos, len1, len2)
  return if len1 == 0 || len2 == 0
  if len1 < len2
    while len1 != 0
      loc = bin_search(arr, pos + len1, len2, pos, true)
      if loc != 0
        rotate(arr, pos, len1, loc)
        pos += loc
        len2 -= loc
      end
      break if len2 == 0

      loop do
        pos += 1
        len1 -= 1
        break unless len1 != 0 && arr[pos] <= arr[pos + len1]
      end
    end
  else
    while len2 != 0
      loc = bin_search(arr, pos, len1, pos + len1 + len2 - 1, false)
      if loc != len1
        rotate(arr, pos + loc, len1 - loc, len2)
        len1 = loc
      end
      break if len1 == 0

      loop do
        len2 -= 1
        break unless len2 != 0 && arr[pos + len1 - 1] <= arr[pos + len1 + len2 - 1]
      end
    end
  end
end

# Guard: a chunk of length <= 1 has nothing to compare. The original source skips this
# check and unconditionally reads arr[a] / arr[a + 1], which crashes whenever chunking
# leaves a trailing 1-element chunk (e.g. n = 17 leaves a final [16, 17) chunk).
def insertion_sort_chunk(arr, a, b)
  return if b - a <= 1

  i = a + 1
  descending = arr[i - 1] > arr[i]
  i += 1
  if descending
    i += 1 while i < b && arr[i - 1] > arr[i]
    lo = a
    hi = i - 1
    while lo < hi
      swap(arr, lo, hi)
      lo += 1
      hi -= 1
    end
  else
    i += 1 while i < b && arr[i - 1] <= arr[i]
  end
  while i < b
    current = arr[i]
    pos = i - 1
    while pos >= a && arr[pos] > current
      arr[pos + 1] = arr[pos]
      pos -= 1
    end
    arr[pos + 1] = current
    i += 1
  end
end

def lazy_stable_sort(arr, pos, length)
  dist = 0
  while dist + 16 < length
    insertion_sort_chunk(arr, pos + dist, pos + dist + 16)
    dist += 16
  end
  insertion_sort_chunk(arr, pos + dist, pos + length) if dist < length

  part = 16
  while part < length
    left = 0
    right = length - 2 * part
    while left <= right
      merge_without_buffer(arr, pos + left, part, part)
      left += 2 * part
    end
    rest = length - left
    merge_without_buffer(arr, pos + left, part, rest - part) if rest > part
    part *= 2
  end
end

def sort(arr)
  lazy_stable_sort(arr, 0, arr.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
