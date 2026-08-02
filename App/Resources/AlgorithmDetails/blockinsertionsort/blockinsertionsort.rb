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

def find_run(arr, a, b)
  i = a + 1
  return i if i == b

  if arr[i - 1] > arr[i]
    i += 1
    i += 1 while i < b && arr[i - 1] > arr[i]
    lo = a
    hi = i - 1
    while lo < hi
      arr[lo], arr[hi] = arr[hi], arr[lo]
      lo += 1
      hi -= 1
    end
  else
    i += 1
    i += 1 while i < b && arr[i - 1] <= arr[i]
  end
  i
end

def insert1(arr, a, l)
  tmp = arr[l]
  l -= 1
  while l >= a && arr[l] > tmp
    arr[l + 1] = arr[l]
    l -= 1
  end
  arr[l + 1] = tmp
end

def insert2(arr, a, l, r)
  tmp_l = arr[l]
  tmp_r = arr[r]
  l -= 1
  while l >= a && arr[l] > tmp_r
    arr[l + 2] = arr[l]
    l -= 1
  end
  arr[l + 2] = tmp_r
  while l >= a && arr[l] > tmp_l
    arr[l + 1] = arr[l]
    l -= 1
  end
  arr[l + 1] = tmp_l
end

def sort(arr)
  n = arr.length
  i = find_run(arr, 0, n)
  while i < n
    j = find_run(arr, i, n)
    len = j - i
    if len == 1
      insert1(arr, 0, i)
    elsif len == 2
      insert2(arr, 0, i, i + 1)
    else
      merge_without_buffer(arr, 0, i, len)
    end
    i = j
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
