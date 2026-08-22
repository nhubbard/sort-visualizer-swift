def silly_sort(arr, i, j)
  if i < j
    m = i + (j - i) / 2
    silly_sort(arr, i, m)
    silly_sort(arr, m + 1, j)
    if arr[i] >= arr[m + 1]
      arr[i], arr[m + 1] = arr[m + 1], arr[i]
    end
    silly_sort(arr, i + 1, j)
  end
end

def sort(array)
  silly_sort(array, 0, array.length - 1)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
