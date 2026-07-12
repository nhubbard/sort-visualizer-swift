def destination(array, flagged, a, b1, b)
  held_value = array[a]
  d = a
  e = 0
  (a + 1...b).each do |i|
    if array[i] < held_value
      d += 1
    elsif i < b1 && !flagged[i] && array[i] == held_value
      e += 1
    end
  end
  while flagged[d] || e > 0
    e -= 1 unless flagged[d]
    d += 1
  end
  d
end

def stable_cycle_sort(array)
  n = array.length
  return array if n <= 1
  flagged = Array.new(n, false)
  (0...(n - 1)).each do |i|
    next if flagged[i]
    j = i
    loop do
      k = destination(array, flagged, i, j, n)
      array[i], array[k] = array[k], array[i]
      flagged[k] = true
      j = k
      break if j == i
    end
  end
  array
end

def sort(array)
  stable_cycle_sort(array)
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array
