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

def sort(array)
  n = array.length
  width = 1
  while width < n
    low = 0
    while low < n
      mid = [low + width, n].min
      high = [low + 2 * width, n].min
      merge(array, low, mid, high) if mid < high
      low += 2 * width
    end
    width *= 2
  end
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
