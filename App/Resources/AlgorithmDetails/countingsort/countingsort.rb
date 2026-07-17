def sort(array)
  n = array.length
  max = array.max

  counts = Array.new(max + 1, 0)
  array.each { |value| counts[value] += 1 }
  (1..max).each { |i| counts[i] += counts[i - 1] }

  output = Array.new(n)
  (n - 1).downto(0) do |i|
    counts[array[i]] -= 1
    output[counts[array[i]]] = array[i]
  end

  (0...n).each { |i| array[i] = output[i] }
  array
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
