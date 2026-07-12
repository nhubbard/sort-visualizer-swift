def push(array, low, high)
  i = low
  while i < high
    if array[i] > array[i + 1]
      array[i], array[i + 1] = array[i + 1], array[i]
    end
    i += 1
  end
end

def merge(array, low, high, mid)
  i = low
  while i <= mid
    if array[i] > array[mid + 1]
      array[i], array[mid + 1] = array[mid + 1], array[i]
      push(array, mid + 1, high)
    end
    i += 1
  end
end

def merge_sort(array, low, high)
  if high - low == 0
    return
  elsif high - low == 1
    if array[low] > array[high]
      array[low], array[high] = array[high], array[low]
    end
  else
    mid = (low + high) / 2
    merge_sort(array, low, mid)
    merge_sort(array, mid + 1, high)
    merge(array, low, high, mid)
  end
end

def sort(array)
  merge_sort(array, 0, array.length() - 1) if array.length() >= 2
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
