def sort(arr)
  n = arr.length
  max_value = arr.max || 0
  output = Array.new(n, 0)
  divisor = 1
  loop do
    counts = Array.new(4, 0)
    arr.each { |value| counts[(value / divisor) % 4] += 1 }
    (1...4).each { |digit| counts[digit] += counts[digit - 1] }
    (n - 1).downto(0) do |i|
      digit = (arr[i] / divisor) % 4
      counts[digit] -= 1
      output[counts[digit]] = arr[i]
    end
    (0...n).each { |i| arr[i] = output[i] }
    break if divisor > max_value / 4
    divisor *= 4
  end
  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
