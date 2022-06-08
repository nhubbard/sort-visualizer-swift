def gnomeSort(arr)
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

items = [35, 95, 74, 71, 72, 30, 96, 53, 9, 0]
gnomeSort(items)
p items