def shakerSort(arr)
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

items = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
shakerSort(items)
p items