def multi_swap(array, a, b, len)
  len.times do |i|
    array[a + i], array[b + i] = array[b + i], array[a + i]
  end
end

def binary_search_mid(array, start, mid, en)
  a = 0
  b = [mid - start, en - mid].min
  m = a + (b - a) / 2
  while b > a
    if array[mid - m - 1] > array[mid + m]
      a = m + 1
    else
      b = m
    end
    m = a + (b - a) / 2
  end
  m
end

def multi_swap_merge(array, start, mid, en)
  m = binary_search_mid(array, start, mid, en)
  while m > 0
    multi_swap(array, mid - m, mid, m)
    multi_swap_merge(array, mid, mid + m, en)
    en = mid
    mid -= m
    m = binary_search_mid(array, start, mid, en)
  end
end

def multi_swap_merge_sort(array, a, b)
  len = b - a
  j = 1
  while j < len
    i = a
    while i + 2 * j <= b
      multi_swap_merge(array, i, i + j, i + 2 * j)
      i += 2 * j
    end
    if i + j < b
      multi_swap_merge(array, i, i + j, b)
    end
    j *= 2
  end
end

def sort(array)
  multi_swap_merge_sort(array, 0, array.length)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
