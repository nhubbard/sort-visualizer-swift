def left_binary_search(array, a, b, val)
  lo, hi = a, b
  while lo < hi
    mid = lo + (hi - lo) / 2
    if val <= array[mid]
      hi = mid
    else
      lo = mid + 1
    end
  end
  lo
end

def right_binary_search(array, a, b, val)
  lo, hi = a, b
  while lo < hi
    mid = lo + (hi - lo) / 2
    if val < array[mid]
      hi = mid
    else
      lo = mid + 1
    end
  end
  lo
end

def insert_to_left(array, a, b, temp)
  while a > b
    array[a] = array[a - 1]
    a -= 1
  end
  array[b] = temp
end

def insert_to_right(array, a, b, temp)
  while a < b
    array[a] = array[a + 1]
    a += 1
  end
  array[a] = temp
end

def double_insertion(array, a, b)
  return if b - a < 2

  j = a + (b - a - 2) / 2 + 1
  i = a + (b - a - 1) / 2

  if j > i && array[i] > array[j]
    array[i], array[j] = array[j], array[i]
  end
  i -= 1
  j += 1

  while j < b
    if array[i] > array[j]
      l = array[j]
      r = array[i]
      m = right_binary_search(array, i + 1, j, l)
      insert_to_right(array, i, m - 1, l)
      dest = left_binary_search(array, m, j, r)
      insert_to_left(array, j, dest, r)
    else
      l = array[i]
      r = array[j]
      m = left_binary_search(array, i + 1, j, l)
      insert_to_right(array, i, m - 1, l)
      dest = right_binary_search(array, m, j, r)
      insert_to_left(array, j, dest, r)
    end
    i -= 1
    j += 1
  end
end

def sort(arr)
  double_insertion(arr, 0, arr.length) if arr.length > 1
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
puts array.inspect
