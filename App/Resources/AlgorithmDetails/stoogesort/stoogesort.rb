def stooge_sort(arr, i, j)
  if arr[j] < arr[i]
    arr[i], arr[j] = arr[j], arr[i]
  end
  if j - i > 1
    t = (j - i + 1) / 3
    stooge_sort(arr, i, j - t)
    stooge_sort(arr, i + t, j)
    stooge_sort(arr, i, j - t)
  end
end

def sort(array)
  stooge_sort(array, 0, array.length - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
