def slow_sort(array, i, j)
  return if i >= j
  m = i + (j - i) / 2
  slow_sort(array, i, m)
  slow_sort(array, m + 1, j)
  if array[m].to_i > array[j].to_i
    array[m], array[j] = array[j], array[m]
  end
  slow_sort(array, i, j - 1)
end

def sort(array)
  slow_sort(array, 0, array.length - 1)
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
