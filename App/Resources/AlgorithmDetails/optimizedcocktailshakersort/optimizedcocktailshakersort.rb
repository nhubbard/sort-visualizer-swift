def sort(array)
  start_idx = 0
  end_idx = array.length - 1
  while start_idx < end_idx
    consec_sorted = 1
    i = start_idx
    while i < end_idx
      if array[i] > array[i + 1]
        array[i], array[i + 1] = array[i + 1], array[i]
        consec_sorted = 1
      else
        consec_sorted += 1
      end
      i += 1
    end
    end_idx -= consec_sorted

    consec_sorted = 1
    j = end_idx
    while j > start_idx
      if array[j - 1] > array[j]
        array[j - 1], array[j] = array[j], array[j - 1]
        consec_sorted = 1
      else
        consec_sorted += 1
      end
      j -= 1
    end
    start_idx += consec_sorted
  end
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
