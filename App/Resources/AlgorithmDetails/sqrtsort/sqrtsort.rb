def sort(array)
  sqrt_sort(array, 0, array.length)
  array
end

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

def sqrt_merge(array, a, m, b)
  block_size = 1
  block_size *= 2 while block_size * block_size < array.length
  if m - a <= block_size && b - m <= block_size
    temp = array[a...b]
    i = 0
    j = m - a
    (a...b).each do |k|
      if i < m - a && (j == b - a || temp[i] <= temp[j])
        array[k] = temp[i]
        i += 1
      else
        array[k] = temp[j]
        j += 1
      end
    end
    return
  end
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
    sqrt_merge(array, m3 + 1, m2, b)
  end
  if m1 - a > 0 && m3 - m1 > 0
    sqrt_merge(array, a, m1, m3)
  end
end

def sqrt_sort(array, a, b)
  len = b - a
  (a...b).step(32) do |start|
    finish = [start + 32, b].min
    ((start + 1)...finish).each do |i|
      value = array[i]
      cursor = i
      while cursor > start && array[cursor - 1] > value
        array[cursor] = array[cursor - 1]
        cursor -= 1
      end
      array[cursor] = value
    end
  end
  j = 32
  while j < len
    i = a
    while i + 2 * j <= b
      sqrt_merge(array, i, i + j, i + 2 * j)
      i += 2 * j
    end
    if i + j < b
      sqrt_merge(array, i, i + j, b)
    end
    j *= 2
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
