def sort(arr)
  n = arr.length()
  swapped = true
  start = 0
  fin = n - 1
  while swapped
    swapped = false
    i = start
    while i < fin
      if arr[i] > arr[i + 1]
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        swapped = true
      end
      i += 1
    end
    if not swapped
      break
    end
    swapped = false
    fin -= 1
    i = fin - 1
    while i >= start
      if arr[i] > arr[i + 1]
        arr[i], arr[i + 1] = arr[i + 1], arr[i]
        swapped = true
      end
      i -= 1
    end
    start += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array