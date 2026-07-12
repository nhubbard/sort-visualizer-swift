def minimum?(arr, start, stop)
  (start + 1...stop).all? { |k| arr[start] <= arr[k] }
end

def maximum?(arr, start, stop)
  (start...stop - 1).all? { |k| arr[k] <= arr[stop - 1] }
end

def shuffle_range!(arr, start, stop)
  (start...stop - 1).each do |i|
    j = rand(i...stop)
    arr[i], arr[j] = arr[j], arr[i]
  end
end

def sort(arr)
  lo = 0
  hi = arr.length
  while lo < hi - 1
    if minimum?(arr, lo, hi)
      lo += 1
    elsif maximum?(arr, lo, hi)
      hi -= 1
    else
      shuffle_range!(arr, lo, hi)
    end
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23]
array = sort(array)
p array
