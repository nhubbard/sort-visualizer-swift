def multi_swap(array, a, b, len)
  len.times do |i|
    array[a + i], array[b + i] = array[b + i], array[a + i]
  end
end

def rotate(array, a, m, b)
  l = m - a
  r = b - m
  while l > 0 && r > 0
    if r < l
      multi_swap(array, m - r, m, r)
      b -= r
      m -= r
      l -= r
    else
      multi_swap(array, a, m, l)
      a += l
      m += l
      r -= l
    end
  end
end

def binary_search(array, a, b, value, left)
  while a < b
    mid = a + (b - a) / 2
    comp = left ? value <= array[mid] : value < array[mid]
    if comp
      b = mid
    else
      a = mid + 1
    end
  end
  a
end

def rotate_merge(array, a, m, b)
  if m - a >= b - m
    m1 = a + (m - a) / 2
    value = array[m1]
    m2 = binary_search(array, m, b, value, true)
    m3 = m1 + (m2 - m)
  else
    m2 = m + (b - m) / 2
    value = array[m2]
    m1 = binary_search(array, a, m, value, false)
    m3 = m2 - (m - m1)
    m2 += 1
  end
  rotate(array, m1, m, m2)
  if m2 - (m3 + 1) > 0 && b - m2 > 0
    rotate_merge(array, m3 + 1, m2, b)
  end
  if m1 - a > 0 && m3 - m1 > 0
    rotate_merge(array, a, m1, m3)
  end
end

def rotate_merge_sort(array, a, b)
  len = b - a
  j = 1
  while j < len
    i = a
    while i + 2 * j <= b
      rotate_merge(array, i, i + j, i + 2 * j)
      i += 2 * j
    end
    if i + j < b
      rotate_merge(array, i, i + j, b)
    end
    j *= 2
  end
end

def sort(array)
  rotate_merge_sort(array, 0, array.length)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
