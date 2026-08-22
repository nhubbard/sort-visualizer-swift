def comp_swap(array, a, b, sort_end)
  return if b >= sort_end
  if array[a] > array[b]
    array[a], array[b] = array[b], array[a]
  end
end

def pairwise_merge(array, a, b, sort_end)
  m = (a + b) / 2
  m1 = (a + m) / 2
  g = m - m1

  (0...(m - m1)).each do |i|
    j = m1
    k = g
    while k > 0
      comp_swap(array, j + i, j + i + k, sort_end)
      k >>= 1
      j -= (k - (i & k))
    end
  end
  pairwise_merge(array, m, b, sort_end) if b - a > 4
end

def pairwise_merge_sort(array, a, b, sort_end)
  m = (a + b) / 2
  i = a
  j = m
  while i < m
    comp_swap(array, i, j, sort_end)
    i += 1
    j += 1
  end
  if b - a > 2
    pairwise_merge_sort(array, a, m, sort_end)
    pairwise_merge_sort(array, m, b, sort_end)
    pairwise_merge(array, a, b, sort_end)
  end
end

def sort(array)
  length = array.length
  sort_end = length

  n = 1
  n <<= 1 while n < length

  pairwise_merge_sort(array, 0, n, sort_end)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
