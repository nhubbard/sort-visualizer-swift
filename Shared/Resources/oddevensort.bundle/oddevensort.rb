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

items = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
sort(items)
p items
