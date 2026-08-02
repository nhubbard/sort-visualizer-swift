def sort(arr)
  n = arr.length
  return arr if n == 0

  min_value = arr.min
  max_value = arr.max
  aux_length = max_value - min_value
  aux = Array.new(aux_length, 0)

  transfer_to = lambda do |index|
    pointer = 0
    while arr[index] > min_value
      arr[index] -= 1
      aux[pointer] += 1
      pointer += 1
    end
  end

  transfer_from = lambda do |index|
    pointer = 0
    while pointer < aux_length && aux[pointer] != 0
      arr[index] += 1
      aux[pointer] -= 1
      pointer += 1
    end
  end

  (0...n).each { |i| transfer_to.call(i) }
  (n - 1).downto(0) { |i| transfer_from.call(i) }

  arr
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
