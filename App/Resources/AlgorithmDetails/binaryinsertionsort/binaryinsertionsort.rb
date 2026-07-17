def binary_search(array, item, first, last)
  low = first
  high = last
  while low < high
    mid = low + (high - low) / 2
    if item < array[mid]
      high = mid
    else
      low = mid + 1
    end
  end
  low
end

def binary_insertion_sort(array)
  (1...array.length).each do |i|
    item = array[i]
    pos = binary_search(array, item, 0, i)
    j = i
    while j > pos
      array[j] = array[j - 1]
      j -= 1
    end
    array[pos] = item
  end
  array
end

def sort(array)
  binary_insertion_sort(array)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
