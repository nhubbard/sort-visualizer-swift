def sort(arr, i, j)
  if arr[j] < arr[i]
    arr[i], arr[j] = arr[j], arr[i]
  end
  if j - i > 1
    t = (j - i + 1) / 3
    sort(arr, i, j - t)
    sort(arr, i + t, j)
    sort(arr, i, j - t)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array, 0, array.length - 1)
p array
