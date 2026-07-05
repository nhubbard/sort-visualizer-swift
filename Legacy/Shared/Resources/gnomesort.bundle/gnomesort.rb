def sort(arr)
  n = arr.length()
  idx = 0
  while idx < n
    if idx == 0
      idx += 1
    end
    if arr[idx] >= arr[idx - 1]
      idx += 1
    else
      arr[idx], arr[idx - 1] = arr[idx - 1], arr[idx]
      idx -= 1
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array