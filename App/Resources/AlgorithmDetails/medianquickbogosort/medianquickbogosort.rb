def sort(arr, start = 0, e = arr.length)
  return if start >= e - 1
  mid = (start + e) / 2

  is_split = lambda do
    low_max = arr[start]
    (start + 1...mid).each do |i|
      low_max = arr[i] if arr[i] > low_max
    end
    (mid...e).each do |i|
      return false if low_max > arr[i]
    end
    true
  end

  until is_split.call
    sub = arr[start...e].shuffle
    arr[start...e] = sub
  end

  sort(arr, start, mid)
  sort(arr, mid, e)
end

array = [0, 39, 21, 62, 91, 14, 23]
sort(array)
p array
