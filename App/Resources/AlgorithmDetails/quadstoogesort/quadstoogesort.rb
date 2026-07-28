def quad_stooge(arr, pos, length)
  if length >= 2 && arr[pos] > arr[pos + length - 1]
    arr[pos], arr[pos + length - 1] = arr[pos + length - 1], arr[pos]
  end
  return if length <= 2

  len1 = length / 2
  len2 = (length + 1) / 2
  len3 = (len1 + 1) / 2 + (len2 + 1) / 2

  quad_stooge(arr, pos, len1)
  quad_stooge(arr, pos + len1, len2)
  quad_stooge(arr, pos + len1 / 2, len3)
  quad_stooge(arr, pos + len1, len2)
  quad_stooge(arr, pos, len1)
  quad_stooge(arr, pos + len1 / 2, len3) if length > 3
end

def sort(array)
  quad_stooge(array, 0, array.length)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
