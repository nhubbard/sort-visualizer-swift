def sort(arr)
  n = arr.length
  i = 1
  while i < n
    j = i
    while j > 0 && arr[j - 1] > arr[j]
      arr[j], arr[j - 1] = arr[j - 1], arr[j]
      j -= 1
    end
    i += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
