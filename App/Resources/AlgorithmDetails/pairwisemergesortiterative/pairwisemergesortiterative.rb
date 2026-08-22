def comp_swap(array, a, b, sort_end)
  return if b >= sort_end
  if array[a] > array[b]
    array[a], array[b] = array[b], array[a]
  end
end

def sort(array)
  length = array.length
  sort_end = length

  n = 1
  n <<= 1 while n < length

  k = n >> 1
  while k > 0
    j = 0
    while j < length
      k.times { |i| comp_swap(array, j + i, j + k + i, sort_end) }
      j += k << 1
    end
    k >>= 1
  end

  k = 2
  while k < n
    m = k >> 1
    while m > 0
      j = 0
      while j < length
        p = m
        while p < ((k - m) << 1)
          m.times { |i| comp_swap(array, j + p + i, j + p + m + i, sort_end) }
          p += m << 1
        end
        j += k << 1
      end
      m >>= 1
    end
    k <<= 1
  end
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
