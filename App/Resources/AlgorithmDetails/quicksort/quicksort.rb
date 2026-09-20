def partition(array, first, last)
  i = first
  j = last
  while i < j
    i += 1 while i < j && array[i] <= array[first]
    j -= 1 while array[j] > array[first]
    array[i], array[j] = array[j], array[i] if i < j
  end
  array[first], array[j] = array[j], array[first]
  j
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
