def is_minimum(arr, start, stop)
  (start + 1...stop).each do |k|
    return false if arr[start] > arr[k]
  end
  true
end

def shuffle_range(arr, start, stop)
  (start...stop - 1).each do |i|
    j = rand(i...stop)
    arr[i], arr[j] = arr[j], arr[i]
  end
end

def sort(arr)
  n = arr.length
  (0...n).each do |i|
    shuffle_range(arr, i, n) until is_minimum(arr, i, n)
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23]
sort(array)
p array
