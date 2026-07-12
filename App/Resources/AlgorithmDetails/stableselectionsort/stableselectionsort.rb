def sort(array)
  (0..array.length - 2).each do |i|
    min = i
    ((i + 1)..array.length - 1).each do |j|
      if array[j] < array[min]
        min = j
      end
    end
    tmp = array[min]
    pos = min
    while pos > i
      array[pos] = array[pos - 1]
      pos -= 1
    end
    array[pos] = tmp
  end
  return array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
