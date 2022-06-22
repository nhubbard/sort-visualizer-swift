def counting(arr, e)
  n = arr.length()
  output = Array.new(n) { |z| 0 }
  count = Array.new(10) { |z| 0 }
  for i in (0...n)
    idx = arr[i] / e
    count[idx % 10] += 1
  end
  for i in (1...10)
    count[i] += count[i - 1]
  end
  i = n - 1
  while i >= 0
    idx = arr[i] / e
    output[count[idx % 10] - 1] = arr[i]
    count[idx % 10] -= 1
    i -= 1
  end
  i = 0
  for i in (0...n)
    arr[i] = output[i]
  end
end

def sort(arr)
  x = arr.max()
  e = 1
  while x / e > 0
    counting(arr, e)
    e *= 10
  end
end

array = [0, 39, 21, 62, 91, 77, 14, 23,
  90, 69, 51, 81, 68, 83, 32, 56]
sort(array)
p array