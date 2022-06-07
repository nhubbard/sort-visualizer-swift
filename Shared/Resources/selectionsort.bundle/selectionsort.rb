def selectionSort(arr)
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

items = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
selectionSort(items)
p items
