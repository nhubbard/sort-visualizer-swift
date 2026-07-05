def sort(array)
  n = array.length()
  c = 0
  while c < n - 1
    d = 0
    while d < n - c - 1
      if array[d] > array[d + 1]
        array[d], array[d + 1] = array[d + 1], array[d]
      end
      d += 1
    end
    c += 1
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array