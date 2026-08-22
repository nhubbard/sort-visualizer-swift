def merge(array, low, mid, high)
  left = array[low...mid]
  right = array[mid...high]
  i = 0
  j = 0
  k = low
  while i < left.length && j < right.length
    if left[i] <= right[j]
      array[k] = left[i]
      i += 1
    else
      array[k] = right[j]
      j += 1
    end
    k += 1
  end
  while i < left.length
    array[k] = left[i]
    i += 1
    k += 1
  end
  while j < right.length
    array[k] = right[j]
    j += 1
    k += 1
  end
end

def sort(arr)
  n = arr.length
  subarray_count = 1
  while subarray_count < n
    subarray_count *= 2
  end

  while subarray_count > 1
    i = 0
    while i < subarray_count
      low = n * i / subarray_count
      mid = n * (i + 1) / subarray_count
      high = n * (i + 2) / subarray_count
      merge(arr, low, mid, high)
      i += 2
    end
    subarray_count /= 2
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
