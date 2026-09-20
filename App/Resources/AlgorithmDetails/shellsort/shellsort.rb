def sort(arr)
  n = arr.length
  gaps = [8861, 3938, 1750, 701, 301, 132, 57, 23, 10, 4, 1]
  gaps.each do |gap|
    next if gap >= n
    (gap...n).each do |i|
      j = i
      while j >= gap && arr[j] < arr[j - gap]
        arr[j], arr[j - gap] = arr[j - gap], arr[j]
        j -= gap
      end
    end
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
