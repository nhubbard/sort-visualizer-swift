def sort(a)
  n = a.length
  return a if n < 2
  swapped = true
  while swapped
    swapped = false
    (0...(n - 1)).each do |i|
      if a[i] > a[i + 1]
        a[i], a[i + 1] = a[i + 1], a[i]
        swapped = true
      end
    end
  end
  a
end
array = [0, 39, 21, 62, 91, 77, 14, 23]
puts sort(array).inspect
