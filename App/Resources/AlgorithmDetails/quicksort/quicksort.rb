def partition(array, first, last)
  pivot = array[last]
  p_index = first
  i = first
  while i < last
    if array[i].to_i <= pivot.to_i
      array[i], array[p_index] = array[p_index], array[i]
      p_index += 1
    end
    i += 1
  end
  array[p_index], array[last] = array[last], array[p_index]
  p_index
end

def quick_sort(array, first, last)
  if first < last
    j = partition(array, first, last)
    quick_sort(array, first, j - 1)
    quick_sort(array, j + 1, last)
  end
  array
end

def sort(array)
  quick_sort(array, 0, array.length - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
