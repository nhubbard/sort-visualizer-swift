def partition(array, first, last)
  pivot = array[last]
  pIndex = first
  i = first
  while i < last
    if array[i].to_i <= pivot.to_i
      array[i], array[pIndex] = array[pIndex], array[i]
      pIndex += 1
    end
    i += 1
  end
  array[pIndex], array[last] = array[last], array[pIndex]
  return pIndex
end

def quick_sort(array, first, last)
  if first < last
    j = partition(array, first, last)
    quick_sort(array, first, j-1)
    quick_sort(array, j+1, last)
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