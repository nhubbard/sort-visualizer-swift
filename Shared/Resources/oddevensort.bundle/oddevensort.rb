def sort(arr)
  n = arr.length()
  sorted = false
  while !sorted
    sorted = true
    i = 1
    while i < n - 1
      if arr[i] > arr[i + 1]
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        sorted = false
      end
      i += 2
    end
    i = 0
    while i < n - 1
      if arr[i] > arr[i + 1]
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        sorted = false
      end
      i += 2
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array