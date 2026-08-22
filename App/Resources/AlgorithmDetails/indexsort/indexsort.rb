def sort(array)
  n = array.length
  min_value = array.min

  (0...n).each do |i|
    cmp_count = 0
    while array[i] - min_value != i && cmp_count < n
      j = array[i] - min_value
      array[i], array[j] = array[j], array[i]
      cmp_count += 1
    end
    break if cmp_count >= n - 1
  end
  array
end

array = [7, 3, 14, 0, 9, 5, 12, 1,
  15, 4, 10, 2, 13, 6, 11, 8]
sort(array)
p array
