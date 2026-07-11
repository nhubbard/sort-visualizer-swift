def sort(arr)
  n = arr.length()
  start = 1
  while start < n
    i = start
    k = start - 1
    while k >= 0
      if arr[i] < arr[k]
        arr[i], arr[k] = arr[k], arr[i]
      end
      k -= 1
      i -= 1
    end
    start += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array