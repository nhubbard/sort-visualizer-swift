def quick_sort(array, p, r)
  return if p >= r

  pivot = array[p + (r - p + 1) / 2]
  i = p
  j = r

  while i <= j
    while array[i] < pivot
      i += 1
    end
    while array[j] > pivot
      j -= 1
    end
    if i <= j
      array[i], array[j] = array[j], array[i]
      i += 1
      j -= 1
    end
  end

  quick_sort(array, p, j) if p < j
  quick_sort(array, i, r) if i < r
end

def sort(arr)
  quick_sort(arr, 0, arr.length() - 1)
  return arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
