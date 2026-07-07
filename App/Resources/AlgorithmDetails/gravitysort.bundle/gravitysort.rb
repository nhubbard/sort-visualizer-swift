def gravity_sort(arr)
  n = arr.length
  return arr if n == 0

  min_value = arr.min
  max_value = arr.max
  y_size = max_value - min_value + 1

  x = Array.new(n, 0)
  y = Array.new(y_size, 0)

  (0...n).each do |i|
    x[i] = arr[i] - min_value
    y[x[i]] += 1
  end

  (y_size - 1).downto(1) do |i|
    y[i - 1] += y[i]
  end

  (y_size - 1).downto(0) do |j|
    (0...n).each do |i|
      inc = (i >= n - y[j] ? 1 : 0) - (x[i] >= j ? 1 : 0)
      arr[i] += inc
    end
  end

  arr
end

def sort(arr)
  gravity_sort(arr)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
