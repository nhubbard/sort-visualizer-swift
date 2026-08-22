def sort(arr)
  n = arr.length
  ext = arr.dup
  min_value = ext.min
  max_value = ext.max + 1

  cur = min_value
  i = 0
  while i < n
    (0...n).each do |j|
      if ext[j] <= cur
        arr[i] = ext[j]
        ext[j] = max_value
        i += 1
      end
    end
    cur += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
