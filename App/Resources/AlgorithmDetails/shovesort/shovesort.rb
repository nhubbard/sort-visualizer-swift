def sort(arr)
  endpos = arr.length
  i = 0
  while i < endpos - 1
    if arr[i] > arr[i + 1]
      (i...(endpos - 1)).each do |f|
        arr[f], arr[f + 1] = arr[f + 1], arr[f]
      end
      i -= 1 if i > 0
      next
    end
    i += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
