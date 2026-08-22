def multi_swap(arr, a, b, count)
  (0...count).each do |i|
    arr[a + i], arr[b + i] = arr[b + i], arr[a + i]
  end
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

def bin_search(arr, pos, length, key_pos, is_left)
  left = 0
  right = length
  while left < right
    mid = left + (right - left) / 2
    cond = is_left ? arr[pos + mid] < arr[key_pos] : arr[pos + mid] <= arr[key_pos]
    if cond
      left = mid + 1
    else
      right = mid
    end
  end
  left
end

def merge_without_buffer(arr, pos, len1, len2)
  return if len1 == 0 || len2 == 0

  if len1 == 1
    loc = bin_search(arr, pos + 1, len2, pos, true)
    rotate(arr, pos, 1, loc)
    return
  end
  if len2 == 1
    loc = bin_search(arr, pos, len1, pos + len1, false)
    rotate(arr, pos + loc, len1 - loc, 1)
    return
  end
  mid1 = len1 / 2
  loc = bin_search(arr, pos + len1, len2, pos + mid1, true)
  rotate(arr, pos + mid1, len1 - mid1, loc)
  merge_without_buffer(arr, pos, mid1, loc)
  merge_without_buffer(arr, pos + mid1 + loc, len1 - mid1, len2 - loc)
end

def sort(arr)
  n = arr.length
  dist = 1
  while dist < n
    arr[dist - 1], arr[dist] = arr[dist], arr[dist - 1] if arr[dist - 1] > arr[dist]
    dist += 2
  end
  part = 2
  while part < n
    left = 0
    right = n - 2 * part
    while left <= right
      merge_without_buffer(arr, left, part, part)
      left += 2 * part
    end
    rest = n - left
    merge_without_buffer(arr, left, part, rest - part) if rest > part
    part *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
