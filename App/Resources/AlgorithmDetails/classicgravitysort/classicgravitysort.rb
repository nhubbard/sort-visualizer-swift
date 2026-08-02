def sort(arr)
  n = arr.length
  return arr if n == 0

  max_value = arr.max
  transpose = Array.new(max_value, 0)

  (0...n).each do |i|
    value = arr[i]
    (0...value).each do |j|
      transpose[j] += 1
    end
  end

  (0...n).each do |i|
    total = 0
    (0...max_value).each do |j|
      total += 1 if transpose[j] > 0
    end
    arr[n - i - 1] = total
    (0...max_value).each do |j|
      transpose[j] -= 1
    end
  end

  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
