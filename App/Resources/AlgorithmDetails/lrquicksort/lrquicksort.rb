def sort(arr)
  quick_sort(arr, 0, arr.length - 1)
  arr
end

def quick_sort(array, p, r)
  while p < r
    pivot = array[p + (r - p + 1) / 2]
    i = p
    j = r
    while i <= j
      i += 1 while array[i] < pivot
      j -= 1 while array[j] > pivot
      if i <= j
        array[i], array[j] = array[j], array[i]
        i += 1
        j -= 1
      end
    end
    if j - p < r - i
      quick_sort(array, p, j) if p < j
      p = i
    else
      quick_sort(array, i, r) if i < r
      r = j
    end
  end
end


array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
