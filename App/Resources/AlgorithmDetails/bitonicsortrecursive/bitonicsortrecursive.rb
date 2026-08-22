def greatest_power_of_two_less_than(n)
  k = 1
  while k < n
    k <<= 1
  end
  k >> 1
end

def compare(array, i, j, dir)
  is_greater = array[i] > array[j]
  if dir == is_greater
    array[i], array[j] = array[j], array[i]
  end
end

def bitonic_merge(array, lo, n, dir)
  if n > 1
    m = greatest_power_of_two_less_than(n)
    (lo...(lo + n - m)).each do |i|
      compare(array, i, i + m, dir)
    end
    bitonic_merge(array, lo, m, dir)
    bitonic_merge(array, lo + m, n - m, dir)
  end
end

def bitonic_sort(array, lo, n, dir)
  if n > 1
    m = n / 2
    bitonic_sort(array, lo, m, !dir)
    bitonic_sort(array, lo + m, n - m, dir)
    bitonic_merge(array, lo, n, dir)
  end
end

def sort(array)
  bitonic_sort(array, 0, array.length, true)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
