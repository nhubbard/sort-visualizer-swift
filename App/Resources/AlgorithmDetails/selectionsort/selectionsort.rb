def sort(arr)
  n = arr.length()
  i = 0
  while i < n - 1
    minIdx = i
    j = i + 1
    while j < n
      if arr[j] < arr[minIdx]
        minIdx = j
      end
      j += 1
    end
    arr[minIdx], arr[i] = arr[i], arr[minIdx]
    i += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array