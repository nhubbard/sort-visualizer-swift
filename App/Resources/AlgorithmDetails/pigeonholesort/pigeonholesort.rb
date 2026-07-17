def sort(array)
  array.length
  min = array.min
  max = array.max
  size = max - min + 1

  holes = Array.new(size, 0)
  array.each { |value| holes[value - min] += 1 }

  j = 0
  (0...size).each do |count|
    while holes[count] > 0
      holes[count] -= 1
      array[j] = count + min
      j += 1
    end
  end
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
