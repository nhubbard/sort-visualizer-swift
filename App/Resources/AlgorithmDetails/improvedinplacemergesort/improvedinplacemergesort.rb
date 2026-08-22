def push(array, p, a, b)
  return if a == b

  temp = array[p]
  array[p] = array[a]
  (a + 1...b).each do |i|
    array[i - 1] = array[i]
  end
  array[b - 1] = temp
end

def merge(array, a, m, b)
  i = a
  j = m
  while i < m && j < b
    if array[i] > array[j]
      j += 1
    else
      push(array, i, m, j)
      i += 1
    end
  end
  while i < m
    push(array, i, m, b)
    i += 1
  end
end

def merge_sort(array, a, b)
  m = a + (b - a) / 2
  if b - a > 2
    merge_sort(array, a, m) if b - a > 3
    merge_sort(array, m, b)
  end
  merge(array, a, m, b)
end

def sort(arr)
  n = arr.length
  merge_sort(arr, 0, n)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
