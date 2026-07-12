def partition(array, lo, hi)
  pivot = array[hi]
  i = lo
  j = lo
  while j < hi
    if array[j] < pivot
      array[i], array[j] = array[j], array[i]
      i += 1
    end
    j += 1
  end
  array[i], array[hi] = array[hi], array[i]
  return i
end

def quick_sort(array, lo, hi)
  if lo < hi
    p = partition(array, lo, hi)
    quick_sort(array, lo, p - 1)
    quick_sort(array, p + 1, hi)
  end
  return array
end

def sort(array)
  return quick_sort(array, 0, array.length() - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
