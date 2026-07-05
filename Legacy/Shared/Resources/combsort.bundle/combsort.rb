def sort(arr)
  n = arr.length()
  shrink = 1.3
  gap = n
  sorted = false
  while !sorted
    gap = (gap / shrink).to_i
    if gap <= 1
      sorted = true
      gap = 1
    end
    i = 0
    while i < n - gap
      sm = gap + i
      if arr[i] > arr[sm]
        arr[i], arr[sm] = arr[sm], arr[i]
        sorted = false
      end
      i += 1
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
