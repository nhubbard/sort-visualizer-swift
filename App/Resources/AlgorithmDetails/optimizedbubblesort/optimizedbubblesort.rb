def sort(array)
  i = array.length - 1
  while i > 0
    consec_sorted = 1
    j = 0
    while j < i
      if array[j] > array[j + 1]
        array[j], array[j + 1] = array[j + 1], array[j]
        consec_sorted = 1
      else
        consec_sorted += 1
      end
      j += 1
    end
    i -= consec_sorted
  end
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
