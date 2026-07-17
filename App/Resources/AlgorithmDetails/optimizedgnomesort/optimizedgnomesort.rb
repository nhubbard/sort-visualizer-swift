def sort(array)
  i = 1
  while i < array.length
    pos = i
    while pos > 0 && array[pos - 1] > array[pos]
      array[pos - 1], array[pos] = array[pos], array[pos - 1]
      pos -= 1
    end
    i += 1
  end
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
