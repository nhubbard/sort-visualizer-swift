def insertionSort(arr)
  n = arr.length()
  i = 1
  while i < n
    key = arr[i]
    j = i - 1
    while j >= 0 && arr[j] > key
      arr[j + 1] = arr[j]
      j -= 1
    end
    arr[j + 1] = key
    i += 1
  end
end

items = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
insertionSort(items)
p items