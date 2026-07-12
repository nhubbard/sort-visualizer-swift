def comp_swap(array, a, b, sort_end)
  return if b >= sort_end
  if array[a] > array[b]
    array[a], array[b] = array[b], array[a]
  end
end

def range_comp(array, a, b, offset, sort_end)
  half = (b - a) / 2
  m = a + half
  base = a + offset
  i = 0
  while i < half - offset
    if (i & ~offset) == i
      comp_swap(array, base + i, m + i, sort_end)
    end
    i += 1
  end
end

def sort(array)
  sort_end = array.length
  return array if sort_end <= 1
  padded_length = 1
  while padded_length < sort_end
    padded_length <<= 1
  end

  k = 2
  while k <= padded_length
    j = 0
    while j < k / 2
      i = 0
      while i + j < sort_end
        range_comp(array, i, i + k, j, sort_end)
        i += k
      end
      j += 1
    end
    k *= 2
  end
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
